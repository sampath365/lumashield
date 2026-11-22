package com.lumashield.app.service

import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.view.Gravity
import android.view.WindowManager
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.lumashield.app.filter.FilterBus
import com.lumashield.app.filter.FilterConfig
import com.lumashield.app.filter.FilterPrefs
import com.lumashield.app.filter.FilterSupport
import com.lumashield.app.filter.OverlayView
import com.lumashield.app.filter.SchedulePlanner
import com.lumashield.app.widget.FilterWidgetProvider

/**
 * Foreground service that owns the system overlay.
 *
 * It is the only component that adds or removes the [OverlayView], which keeps
 * lifecycle handling in one place: start, stop, update, reboot restore,
 * schedule transitions and per-app overrides all funnel through [applyNow].
 *
 * Android can still stop the service (battery savers, vendor task killers,
 * secure screens). The service therefore persists its state and asks for a
 * restart when it is destroyed, subject to the user's auto restart setting.
 */
class OverlayFilterService : Service() {

    companion object {
        const val ACTION_START = "com.lumashield.app.action.START"
        const val ACTION_STOP = "com.lumashield.app.action.STOP"
        const val ACTION_TOGGLE = "com.lumashield.app.action.TOGGLE"
        const val ACTION_UPDATE = "com.lumashield.app.action.UPDATE"
        const val ACTION_APPLY_SCHEDULE = "com.lumashield.app.action.APPLY_SCHEDULE"
        const val ACTION_RESTART = "com.lumashield.app.action.RESTART"

        @Volatile
        var isRunning: Boolean = false
            private set

        fun start(context: Context) {
            val intent = Intent(context, OverlayFilterService::class.java).apply {
                action = ACTION_START
            }
            runCatching { ContextCompat.startForegroundService(context, intent) }
        }

        fun update(context: Context) {
            if (!FilterPrefs(context).filter.enabled) {
                stop(context)
                return
            }
            val intent = Intent(context, OverlayFilterService::class.java).apply {
                action = ACTION_UPDATE
            }
            runCatching { ContextCompat.startForegroundService(context, intent) }
        }

        fun stop(context: Context) {
            val prefs = FilterPrefs(context)
            prefs.filter = prefs.filter.copy(enabled = false)
            runCatching {
                context.stopService(Intent(context, OverlayFilterService::class.java))
            }
            FilterBus.emit(
                mapOf(
                    "running" to false,
                    "enabled" to false,
                    "intensity" to prefs.filter.safeIntensity,
                    "kelvin" to prefs.filter.safeKelvin,
                ),
            )
        }

        fun toggle(context: Context) {
            val intent = Intent(context, OverlayFilterService::class.java).apply {
                action = ACTION_TOGGLE
            }
            runCatching { ContextCompat.startForegroundService(context, intent) }
        }

        /** Applies the schedule for "now" and moves the overlay accordingly. */
        fun applySchedule(context: Context) {
            val prefs = FilterPrefs(context)
            val schedule = prefs.schedule
            if (!schedule.enabled) return
            val applied = SchedulePlanner.stateAt(System.currentTimeMillis(), schedule)
            val current = prefs.filter
            val next = current.copy(
                enabled = applied.enabled,
                intensity = applied.intensity,
                kelvin = applied.kelvin,
                modeLabel = if (applied.enabled) "Scheduled night" else current.modeLabel,
            )
            prefs.filter = next
            ScheduleAlarmScheduler.scheduleNext(context)
            if (next.enabled && FilterSupport.canDrawOverlays(context)) {
                start(context)
            } else {
                stop(context)
            }
        }
    }

    private lateinit var prefs: FilterPrefs
    private lateinit var windowManager: WindowManager
    private var overlayView: OverlayView? = null
    private var userStopped = false
    private val handler = Handler(Looper.getMainLooper())
    private var profileWatcher: Runnable? = null
    private var lastProfilePackage: String? = null

    override fun onCreate() {
        super.onCreate()
        prefs = FilterPrefs(this)
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        NotificationHelper.createChannels(this)
        isRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // startForegroundService() requires a notification within a few seconds,
        // even when the action turns out to be a stop. Post it first, tear down after.
        startForegroundCompat(prefs.filter)

        when (intent?.action) {
            ACTION_STOP -> {
                userStopped = true
                prefs.filter = prefs.filter.copy(enabled = false)
                publish()
                teardown()
                return START_NOT_STICKY
            }

            ACTION_TOGGLE -> {
                val next = prefs.filter.copy(enabled = !prefs.filter.enabled)
                prefs.filter = next
                userStopped = !next.enabled
                applyNow()
                if (!next.enabled) return START_NOT_STICKY
                return START_STICKY
            }

            ACTION_APPLY_SCHEDULE -> {
                val schedule = prefs.schedule
                if (schedule.enabled) {
                    val applied = SchedulePlanner.stateAt(System.currentTimeMillis(), schedule)
                    prefs.filter = prefs.filter.copy(
                        enabled = applied.enabled,
                        intensity = applied.intensity,
                        kelvin = applied.kelvin,
                        modeLabel = if (applied.enabled) "Scheduled night" else prefs.filter.modeLabel,
                    )
                }
                ScheduleAlarmScheduler.scheduleNext(this)
            }
        }

        val config = prefs.filter
        if (!config.enabled) {
            teardown()
            return START_NOT_STICKY
        }
        applyNow()
        return START_STICKY
    }

    private fun applyNow() {
        val config = prefs.filter
        if (!config.enabled) {
            teardown()
            return
        }
        if (!Settings.canDrawOverlays(this)) {
            // Permission was revoked while running: stop cleanly instead of
            // leaving a foreground service that cannot do its job.
            prefs.filter = config.copy(enabled = false)
            publish()
            teardown()
            return
        }

        startForegroundCompat(config)
        ensureOverlay(config)
        publish()
        ScheduleAlarmScheduler.scheduleNext(this)
        startProfileWatcher()
    }

    private fun startForegroundCompat(config: FilterConfig) {
        val schedule = prefs.schedule
        val summary = if (schedule.enabled) {
            SchedulePlanner.describe(schedule)
        } else {
            null
        }
        val nextEvent = SchedulePlanner.nextActivation(System.currentTimeMillis(), schedule)?.let {
            val formatted = android.text.format.DateFormat.getTimeFormat(this).format(java.util.Date(it))
            "Next change at $formatted"
        }
        val notification = NotificationHelper.buildServiceNotification(
            this,
            config,
            summary,
            nextEvent,
            prefs.notificationActions,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceCompat.startForeground(
                this,
                NotificationHelper.SERVICE_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NotificationHelper.SERVICE_NOTIFICATION_ID, notification)
        }
    }

    private fun ensureOverlay(config: FilterConfig) {
        val existing = overlayView
        if (existing != null) {
            existing.apply(config)
            return
        }
        val view = OverlayView(this)
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                setFitInsetsTypes(0)
                setFitInsetsSides(0)
            }
            title = "LumaShield filter"
        }
        view.apply(config)
        runCatching {
            windowManager.addView(view, params)
            overlayView = view
        }.onFailure {
            // Some vendors refuse the window even with permission granted.
            prefs.filter = prefs.filter.copy(enabled = false)
            publish()
            teardown()
        }
    }

    private fun detachOverlay() {
        overlayView?.let { view ->
            runCatching { windowManager.removeView(view) }
        }
        overlayView = null
    }

    private fun teardown() {
        stopProfileWatcher()
        detachOverlay()
        publish()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        NotificationHelper.cancelServiceNotification(this)
        isRunning = false
        stopSelf()
    }

    /**
     * Optional per-app profiles. Polling only runs while the screen is
     * interactive and the user turned the feature on, so it stays cheap.
     */
    private fun startProfileWatcher() {
        if (!prefs.perAppEnabled || prefs.profiles.isEmpty()) return
        if (profileWatcher != null) return
        val runnable = object : Runnable {
            override fun run() {
                tickProfiles()
                handler.postDelayed(this, 2500)
            }
        }
        profileWatcher = runnable
        handler.postDelayed(runnable, 1200)
    }

    private fun stopProfileWatcher() {
        profileWatcher?.let { handler.removeCallbacks(it) }
        profileWatcher = null
        lastProfilePackage = null
    }

    private fun tickProfiles() {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!power.isInteractive) return
        val foreground = ForegroundAppReader.currentPackage(this) ?: return
        if (foreground == packageName) return
        if (foreground == lastProfilePackage) return
        lastProfilePackage = foreground
        val profile = prefs.profiles.firstOrNull { it.packageName == foreground }
        val base = prefs.filter
        if (profile == null) {
            overlayView?.apply(base)
            return
        }
        if (!profile.enabled) {
            detachOverlay()
        } else {
            ensureOverlay(
                base.copy(
                    enabled = true,
                    intensity = profile.intensity,
                    kelvin = profile.kelvin,
                    modeLabel = "App: ${profile.label}",
                ),
            )
        }
    }

    private fun publish() {
        val config = prefs.filter
        val schedule = prefs.schedule
        val state = mapOf<String, Any?>(
            "running" to isRunning,
            "enabled" to config.enabled,
            "intensity" to config.safeIntensity,
            "kelvin" to config.safeKelvin,
            "dim" to config.safeDim,
            "modeLabel" to config.modeLabel,
            "strength" to FilterSupport.strengthPercent(config),
            "scheduleEnabled" to schedule.enabled,
            "nextActivation" to SchedulePlanner.nextActivation(System.currentTimeMillis(), schedule),
            "nextDeactivation" to SchedulePlanner.nextDeactivation(System.currentTimeMillis(), schedule),
        )
        FilterBus.emit(state)
        FilterTileService.requestTileUpdate(this)
        FilterWidgetProvider.refresh(this)
        if (isRunning) {
            NotificationHelper.updateServiceNotification(
                this,
                config,
                if (schedule.enabled) SchedulePlanner.describe(schedule) else null,
                null,
                prefs.notificationActions,
                prefs.showNotification,
            )
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        if (prefs.autoRestart && prefs.filter.enabled) {
            ScheduleAlarmScheduler.scheduleRestart(this)
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        stopProfileWatcher()
        detachOverlay()
        isRunning = false
        val shouldRestart = !userStopped && prefs.autoRestart && prefs.filter.enabled
        FilterBus.emit(mapOf("running" to false, "enabled" to prefs.filter.enabled))
        FilterTileService.requestTileUpdate(this)
        FilterWidgetProvider.refresh(this)
        if (shouldRestart) {
            ScheduleAlarmScheduler.scheduleRestart(this)
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

}

/** Reads the package currently in the foreground using the usage stats API. */
object ForegroundAppReader {

    fun currentPackage(context: Context): String? {
        if (!hasUsageAccess(context)) return null
        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return null
        val now = System.currentTimeMillis()
        val events = manager.queryEvents(now - 15_000, now) ?: return null
        var lastPackage: String? = null
        val event = android.app.usage.UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND ||
                event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED
            ) {
                lastPackage = event.packageName
            }
        }
        return lastPackage
    }

    fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName,
            )
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }
}
