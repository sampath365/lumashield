package com.lumashield.app

import android.app.Activity
import android.app.AlarmManager
import android.app.AppOpsManager
import android.app.StatusBarManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.lumashield.app.filter.FilterBus
import com.lumashield.app.filter.FilterConfig
import com.lumashield.app.filter.FilterPrefs
import com.lumashield.app.filter.FilterSupport
import com.lumashield.app.filter.SchedulePlanner
import com.lumashield.app.filter.ScheduleSettings
import com.lumashield.app.service.BreakPopup
import com.lumashield.app.service.EyeBreakScheduler
import com.lumashield.app.service.EyeStatusNotifier
import com.lumashield.app.service.ForegroundAppReader
import com.lumashield.app.service.NotificationHelper
import com.lumashield.app.service.OverlayFilterService
import com.lumashield.app.service.ScheduleAlarmScheduler
import com.lumashield.app.widget.FilterWidgetProvider

/**
 * Flutter host plus the platform channel that drives the native overlay.
 *
 * All privileged work (overlay window, foreground service, alarms, usage stats)
 * lives in native code; Dart never assumes a capability it has not checked.
 */
class MainActivity : FlutterFragmentActivity() {

    companion object {
        const val EXTRA_LAUNCH_ACTION = "lumashield.launch_action"
        const val LAUNCH_ACTION_EYE_BREAK = "eye_break"
    }

    private val methodChannelName = "com.lumashield.app/filter"
    private val eventChannelName = "com.lumashield.app/events"

    private var eventSink: EventChannel.EventSink? = null
    private var pendingLaunchAction: String? = null
    private val busListener: (Map<String, Any?>) -> Unit = { state ->
        runOnUiThread { eventSink?.success(state) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        NotificationHelper.createChannels(this)
        pendingLaunchAction = intent?.getStringExtra(EXTRA_LAUNCH_ACTION)
        EyeBreakScheduler.scheduleNext(this)
        EyeBreakScheduler.startStatusRefresh(this)
        EyeStatusNotifier.update(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = intent.getStringExtra(EXTRA_LAUNCH_ACTION) ?: return
        pendingLaunchAction = action
        eventSink?.success(mapOf("launchAction" to action))
    }

    override fun onResume() {
        super.onResume()
        EyeStatusNotifier.update(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                try {
                    handleCall(call.method, call.arguments, result)
                } catch (error: Throwable) {
                    result.error("native_error", error.message, null)
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    FilterBus.register(busListener)
                    events?.success(statusMap())
                }

                override fun onCancel(arguments: Any?) {
                    FilterBus.unregister(busListener)
                    eventSink = null
                }
            })
    }

    private fun handleCall(method: String, arguments: Any?, result: MethodChannel.Result) {
        val prefs = FilterPrefs(this)
        when (method) {
            "getStatus" -> result.success(statusMap())

            "isOverlayGranted" -> result.success(Settings.canDrawOverlays(this))
            "openOverlaySettings" -> {
                FilterSupport.openOverlaySettings(this)
                result.success(true)
            }

            "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
            "requestIgnoreBatteryOptimizations" -> {
                requestIgnoreBattery()
                result.success(true)
            }
            "openBatterySettings" -> {
                openBatterySettings()
                result.success(true)
            }

            "isUsageAccessGranted" -> result.success(ForegroundAppReader.hasUsageAccess(this))
            "openUsageAccessSettings" -> {
                startActivity(
                    Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                result.success(true)
            }

            "canScheduleExactAlarms" -> result.success(ScheduleAlarmScheduler.canScheduleExact(this))
            "openExactAlarmSettings" -> {
                openExactAlarmSettings()
                result.success(true)
            }

            "openNotificationSettings" -> {
                openNotificationSettings()
                result.success(true)
            }

            "openAppSettings" -> {
                startActivity(
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:$packageName"),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                result.success(true)
            }

            "startProtection" -> {
                val config = FilterConfig.fromMap(arguments as? Map<*, *>)
                prefs.filter = config.copy(enabled = true)
                OverlayFilterService.start(this)
                result.success(statusMap())
            }

            "updateProtection" -> {
                val config = FilterConfig.fromMap(arguments as? Map<*, *>)
                prefs.filter = config
                if (config.enabled) {
                    OverlayFilterService.update(this)
                } else {
                    OverlayFilterService.stop(this)
                }
                result.success(statusMap())
            }

            "stopProtection" -> {
                prefs.filter = prefs.filter.copy(enabled = false)
                OverlayFilterService.stop(this)
                result.success(statusMap())
            }

            "toggleProtection" -> {
                OverlayFilterService.toggle(this)
                result.success(statusMap())
            }

            "emergencyDisable" -> {
                prefs.filter = prefs.filter.copy(enabled = false)
                prefs.schedule = prefs.schedule.copy(enabled = false)
                ScheduleAlarmScheduler.cancelBoundary(this)
                OverlayFilterService.stop(this)
                result.success(statusMap())
            }

            "applySchedule" -> {
                val schedule = ScheduleSettings.fromMap(arguments as? Map<*, *>)
                prefs.schedule = schedule
                ScheduleAlarmScheduler.scheduleNext(this)
                val applied = SchedulePlanner.stateAt(System.currentTimeMillis(), schedule)
                if (schedule.enabled) {
                    prefs.filter = prefs.filter.copy(
                        enabled = applied.enabled,
                        intensity = applied.intensity,
                        kelvin = applied.kelvin,
                        modeLabel = if (applied.enabled) "Scheduled night" else prefs.filter.modeLabel,
                    )
                    if (applied.enabled && FilterSupport.canDrawOverlays(this)) {
                        OverlayFilterService.start(this)
                    } else {
                        OverlayFilterService.stop(this)
                    }
                }
                result.success(statusMap())
            }

            "cancelSchedule" -> {
                prefs.schedule = prefs.schedule.copy(enabled = false)
                ScheduleAlarmScheduler.cancelBoundary(this)
                result.success(statusMap())
            }

            "getSchedulePreview" -> {
                val schedule = prefs.schedule
                val now = System.currentTimeMillis()
                result.success(
                    mapOf(
                        "nightNow" to SchedulePlanner.isNight(now, schedule),
                        "nextActivation" to SchedulePlanner.nextActivation(now, schedule),
                        "nextDeactivation" to SchedulePlanner.nextDeactivation(now, schedule),
                    ),
                )
            }

            "setServiceOptions" -> {
                val map = arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                (map["showNotification"] as? Boolean)?.let { prefs.showNotification = it }
                (map["notificationActions"] as? Boolean)?.let { prefs.notificationActions = it }
                (map["restoreOnBoot"] as? Boolean)?.let { prefs.restoreOnBoot = it }
                (map["autoRestart"] as? Boolean)?.let { prefs.autoRestart = it }
                OverlayFilterService.update(this)
                result.success(statusMap())
            }

            "setProfiles" -> {
                val list = arguments as? List<*> ?: emptyList<Any>()
                prefs.profiles = list.mapNotNull { item ->
                    val map = item as? Map<*, *> ?: return@mapNotNull null
                    val pkg = map["packageName"] as? String ?: return@mapNotNull null
                    com.lumashield.app.filter.AppProfile(
                        packageName = pkg,
                        label = map["label"] as? String ?: pkg,
                        enabled = map["enabled"] as? Boolean ?: true,
                        intensity = (map["intensity"] as? Number)?.toInt() ?: 0,
                        kelvin = (map["kelvin"] as? Number)?.toInt() ?: 4500,
                    )
                }
                result.success(true)
            }

            "setProfilesEnabled" -> {
                prefs.perAppEnabled = arguments as? Boolean ?: false
                result.success(true)
            }

            "updateEyeCare" -> {
                val map = arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                prefs.applyEyeCare(map)
                EyeBreakScheduler.scheduleNext(this)
                EyeBreakScheduler.startStatusRefresh(this)
                EyeStatusNotifier.update(this)
                result.success(eyeCareMap(prefs))
            }

            "getEyeCare" -> result.success(eyeCareMap(prefs))

            "completeEyeBreak" -> {
                EyeStatusNotifier.registerRest(this)
                EyeBreakScheduler.scheduleNext(this)
                NotificationHelper.cancelEyeBreakNotification(this)
                result.success(eyeCareMap(prefs))
            }

            "snoozeEyeBreak" -> {
                EyeBreakScheduler.snooze(this, 5)
                NotificationHelper.cancelEyeBreakNotification(this)
                result.success(eyeCareMap(prefs))
            }

            "startEyeBreakNow" -> {
                EyeBreakScheduler.snooze(this, prefs.breakIntervalMin)
                result.success(eyeCareMap(prefs))
            }

            "showBreakPopup" -> {
                val shown = BreakPopup.show(this)
                result.success(shown)
            }

            "dismissBreakPopup" -> {
                BreakPopup.dismiss(this)
                result.success(true)
            }

            "consumeLaunchAction" -> {
                val action = pendingLaunchAction
                pendingLaunchAction = null
                result.success(action)
            }

            "getInstalledApps" -> result.success(launchableApps())

            "getForegroundApp" -> result.success(ForegroundAppReader.currentPackage(this))

            "getDeviceInfo" -> result.success(
                mapOf(
                    "manufacturer" to Build.MANUFACTURER,
                    "model" to Build.MODEL,
                    "sdk" to Build.VERSION.SDK_INT,
                    "androidVersion" to Build.VERSION.RELEASE,
                ),
            )

            "requestAddTile" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val statusBar = getSystemService(StatusBarManager::class.java)
                    statusBar?.requestAddTileService(
                        ComponentName(this, com.lumashield.app.service.FilterTileService::class.java),
                        getString(R.string.tile_label),
                        android.graphics.drawable.Icon.createWithResource(
                            this,
                            R.drawable.ic_tile,
                        ),
                        mainExecutor,
                    ) { addResult -> result.success(addResult) }
                } else {
                    result.success(StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED)
                }
            }

            "requestPinWidget" -> {
                val manager = AppWidgetManager.getInstance(this)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                    manager.isRequestPinAppWidgetSupported
                ) {
                    manager.requestPinAppWidget(
                        ComponentName(this, FilterWidgetProvider::class.java),
                        null,
                        null,
                    )
                    result.success(true)
                } else {
                    result.success(false)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun eyeCareMap(prefs: FilterPrefs): Map<String, Any?> = mapOf(
        "breaksEnabled" to prefs.breaksEnabled,
        "intervalMin" to prefs.breakIntervalMin,
        "breakLengthSec" to prefs.breakLengthSec,
        "quietEnabled" to prefs.quietHoursEnabled,
        "quietStartMin" to prefs.quietStartMin,
        "quietEndMin" to prefs.quietEndMin,
        "sound" to prefs.eyeSound,
        "vibrate" to prefs.eyeVibrate,
        "showEyeStatus" to prefs.eyeStatusEnabled,
        "breakPopup" to prefs.breakPopup,
        "eyeScore" to EyeStatusNotifier.computeScore(prefs),
        "minutesSinceBreak" to ((System.currentTimeMillis() - prefs.lastBreakAt) / 60_000L)
            .coerceAtLeast(0),
        "nextBreakIn" to EyeStatusNotifier.minutesUntilBreak(prefs),
        "nextBreakAt" to prefs.nextBreakAt,
    )

    private fun statusMap(): Map<String, Any?> {
        val prefs = FilterPrefs(this)
        val config = prefs.filter
        val schedule = prefs.schedule
        val now = System.currentTimeMillis()
        return mapOf(
            "supported" to true,
            "running" to OverlayFilterService.isRunning,
            "enabled" to config.enabled,
            "intensity" to config.safeIntensity,
            "kelvin" to config.safeKelvin,
            "dim" to config.safeDim,
            "customColor" to config.customColor,
            "modeLabel" to config.modeLabel,
            "strength" to FilterSupport.strengthPercent(config),
            "overlayGranted" to Settings.canDrawOverlays(this),
            "batteryOptimized" to !isIgnoringBatteryOptimizations(),
            "usageAccessGranted" to ForegroundAppReader.hasUsageAccess(this),
            "exactAlarmsAllowed" to ScheduleAlarmScheduler.canScheduleExact(this),
            "scheduleEnabled" to schedule.enabled,
            "scheduleMode" to schedule.mode,
            "nextActivation" to SchedulePlanner.nextActivation(now, schedule),
            "nextDeactivation" to SchedulePlanner.nextDeactivation(now, schedule),
            "nightNow" to SchedulePlanner.isNight(now, schedule),
            "showNotification" to prefs.showNotification,
            "notificationActions" to prefs.notificationActions,
            "restoreOnBoot" to prefs.restoreOnBoot,
            "autoRestart" to prefs.autoRestart,
            "profilesEnabled" to prefs.perAppEnabled,
            "eyeScore" to EyeStatusNotifier.computeScore(prefs),
            "nextBreakIn" to EyeStatusNotifier.minutesUntilBreak(prefs),
            "eyeStatusEnabled" to prefs.eyeStatusEnabled,
            "breaksEnabled" to prefs.breaksEnabled,
            "breakIntervalMin" to prefs.breakIntervalMin,
        )
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBattery() {
        val intent = Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:$packageName"),
        )
        runCatching { startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
            .onFailure { openBatterySettings() }
    }

    private fun openBatterySettings() {
        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        runCatching { startActivity(intent) }.onFailure {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    private fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(
                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                Uri.parse("package:$packageName"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            runCatching { startActivity(intent) }.onFailure { openAppSettings() }
        } else {
            openAppSettings()
        }
    }

    private fun openAppSettings() {
        startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        runCatching { startActivity(intent) }.onFailure { openAppSettings() }
    }

    /** Launcher apps only, which keeps the app clear of the restricted QUERY_ALL_PACKAGES permission. */
    private fun launchableApps(): List<Map<String, Any?>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(0L),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(intent, 0)
        }
        return resolveInfos
            .asSequence()
            .mapNotNull { info ->
                val activityInfo = info.activityInfo ?: return@mapNotNull null
                val pkg = activityInfo.packageName
                if (pkg == packageName) return@mapNotNull null
                mapOf<String, Any?>(
                    "packageName" to pkg,
                    "label" to info.loadLabel(packageManager).toString(),
                )
            }
            .distinctBy { it["packageName"] }
            .sortedBy { (it["label"] as? String)?.lowercase() }
            .toList()
    }
}
