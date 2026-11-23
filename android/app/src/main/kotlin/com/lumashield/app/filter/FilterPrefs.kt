package com.lumashield.app.filter

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

/**
 * Time based automation. `daysMask` uses bit 0 for Monday through bit 6 for
 * Sunday, matching `DateTime.weekday - 1` on the Flutter side.
 */
data class ScheduleSettings(
    val enabled: Boolean = false,
    val mode: String = MODE_CUSTOM,
    val startMinute: Int = 21 * 60,
    val endMinute: Int = 7 * 60,
    val daysMask: Int = 0b1111111,
    val nightIntensity: Int = 65,
    val nightKelvin: Int = 3200,
    val dayIntensity: Int = 15,
    val dayKelvin: Int = 5400,
    val useLocation: Boolean = false,
    val latitude: Double = 0.0,
    val longitude: Double = 0.0,
    val sunriseOffsetMin: Int = 0,
    val sunsetOffsetMin: Int = 0,
) {
    val hasLocation: Boolean
        get() = useLocation && latitude in -89.0..89.0 && longitude in -180.0..180.0 &&
            !(latitude == 0.0 && longitude == 0.0)

    fun isDayEnabled(dayIndex: Int): Boolean = daysMask and (1 shl dayIndex.coerceIn(0, 6)) != 0

    fun toMap(): Map<String, Any?> = mapOf(
        "enabled" to enabled,
        "mode" to mode,
        "startMinute" to startMinute,
        "endMinute" to endMinute,
        "daysMask" to daysMask,
        "nightIntensity" to nightIntensity,
        "nightKelvin" to nightKelvin,
        "dayIntensity" to dayIntensity,
        "dayKelvin" to dayKelvin,
        "useLocation" to useLocation,
        "latitude" to latitude,
        "longitude" to longitude,
        "sunriseOffsetMin" to sunriseOffsetMin,
        "sunsetOffsetMin" to sunsetOffsetMin,
    )

    companion object {
        const val MODE_CUSTOM = "custom"
        const val MODE_SUN = "sun"

        fun fromMap(map: Map<*, *>?): ScheduleSettings {
            if (map == null) return ScheduleSettings()
            return ScheduleSettings(
                enabled = map["enabled"] as? Boolean ?: false,
                mode = map["mode"] as? String ?: MODE_CUSTOM,
                startMinute = (map["startMinute"] as? Number)?.toInt() ?: 21 * 60,
                endMinute = (map["endMinute"] as? Number)?.toInt() ?: 7 * 60,
                daysMask = (map["daysMask"] as? Number)?.toInt() ?: 0b1111111,
                nightIntensity = (map["nightIntensity"] as? Number)?.toInt() ?: 65,
                nightKelvin = (map["nightKelvin"] as? Number)?.toInt() ?: 3200,
                dayIntensity = (map["dayIntensity"] as? Number)?.toInt() ?: 15,
                dayKelvin = (map["dayKelvin"] as? Number)?.toInt() ?: 5400,
                useLocation = map["useLocation"] as? Boolean ?: false,
                latitude = (map["latitude"] as? Number)?.toDouble() ?: 0.0,
                longitude = (map["longitude"] as? Number)?.toDouble() ?: 0.0,
                sunriseOffsetMin = (map["sunriseOffsetMin"] as? Number)?.toInt() ?: 0,
                sunsetOffsetMin = (map["sunsetOffsetMin"] as? Number)?.toInt() ?: 0,
            )
        }
    }
}

/** Per-app override for the filter. */
data class AppProfile(
    val packageName: String,
    val label: String,
    val enabled: Boolean = true,
    val intensity: Int = 0,
    val kelvin: Int = 4500,
)

/**
 * Single source of truth for the native side. Everything the service needs
 * survives process death and reboots here, so protection can be restored even
 * when the Flutter engine is not running.
 */
class FilterPrefs(context: Context) {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    var filter: FilterConfig
        get() = FilterConfig(
            enabled = prefs.getBoolean(KEY_ENABLED, false),
            intensity = prefs.getInt(KEY_INTENSITY, 30),
            kelvin = prefs.getInt(KEY_KELVIN, 4500),
            customColor = if (prefs.contains(KEY_CUSTOM_COLOR)) prefs.getInt(KEY_CUSTOM_COLOR, 0) else null,
            dim = prefs.getInt(KEY_DIM, 0),
            modeLabel = prefs.getString(KEY_MODE_LABEL, "Eye Protection") ?: "Eye Protection",
        )
        set(value) {
            prefs.edit()
                .putBoolean(KEY_ENABLED, value.enabled)
                .putInt(KEY_INTENSITY, value.safeIntensity)
                .putInt(KEY_KELVIN, value.safeKelvin)
                .putInt(KEY_DIM, value.safeDim)
                .putString(KEY_MODE_LABEL, value.modeLabel)
                .apply {
                    val color = value.customColor
                    if (color == null) remove(KEY_CUSTOM_COLOR) else putInt(KEY_CUSTOM_COLOR, color)
                }
                .apply()
        }

    var schedule: ScheduleSettings
        get() = ScheduleSettings(
            enabled = prefs.getBoolean(KEY_SCHEDULE_ENABLED, false),
            mode = prefs.getString(KEY_SCHEDULE_MODE, ScheduleSettings.MODE_CUSTOM)
                ?: ScheduleSettings.MODE_CUSTOM,
            startMinute = prefs.getInt(KEY_START_MIN, 21 * 60),
            endMinute = prefs.getInt(KEY_END_MIN, 7 * 60),
            daysMask = prefs.getInt(KEY_DAYS_MASK, 0b1111111),
            nightIntensity = prefs.getInt(KEY_NIGHT_INTENSITY, 65),
            nightKelvin = prefs.getInt(KEY_NIGHT_KELVIN, 3200),
            dayIntensity = prefs.getInt(KEY_DAY_INTENSITY, 15),
            dayKelvin = prefs.getInt(KEY_DAY_KELVIN, 5400),
            useLocation = prefs.getBoolean(KEY_USE_LOCATION, false),
            latitude = prefs.getString(KEY_LATITUDE, "0")!!.toDoubleOrNull() ?: 0.0,
            longitude = prefs.getString(KEY_LONGITUDE, "0")!!.toDoubleOrNull() ?: 0.0,
            sunriseOffsetMin = prefs.getInt(KEY_SUNRISE_OFFSET, 0),
            sunsetOffsetMin = prefs.getInt(KEY_SUNSET_OFFSET, 0),
        )
        set(value) {
            prefs.edit()
                .putBoolean(KEY_SCHEDULE_ENABLED, value.enabled)
                .putString(KEY_SCHEDULE_MODE, value.mode)
                .putInt(KEY_START_MIN, value.startMinute.coerceIn(0, 1439))
                .putInt(KEY_END_MIN, value.endMinute.coerceIn(0, 1439))
                .putInt(KEY_DAYS_MASK, value.daysMask and 0b1111111)
                .putInt(KEY_NIGHT_INTENSITY, value.nightIntensity.coerceIn(0, 100))
                .putInt(KEY_NIGHT_KELVIN, value.nightKelvin.coerceIn(1900, 6500))
                .putInt(KEY_DAY_INTENSITY, value.dayIntensity.coerceIn(0, 100))
                .putInt(KEY_DAY_KELVIN, value.dayKelvin.coerceIn(1900, 6500))
                .putBoolean(KEY_USE_LOCATION, value.useLocation)
                .putString(KEY_LATITUDE, value.latitude.toString())
                .putString(KEY_LONGITUDE, value.longitude.toString())
                .putInt(KEY_SUNRISE_OFFSET, value.sunriseOffsetMin.coerceIn(-180, 180))
                .putInt(KEY_SUNSET_OFFSET, value.sunsetOffsetMin.coerceIn(-180, 180))
                .apply()
        }

    var showNotification: Boolean
        get() = prefs.getBoolean(KEY_SHOW_NOTIFICATION, true)
        set(value) = prefs.edit().putBoolean(KEY_SHOW_NOTIFICATION, value).apply()

    var notificationActions: Boolean
        get() = prefs.getBoolean(KEY_NOTIFICATION_ACTIONS, true)
        set(value) = prefs.edit().putBoolean(KEY_NOTIFICATION_ACTIONS, value).apply()

    var restoreOnBoot: Boolean
        get() = prefs.getBoolean(KEY_RESTORE_ON_BOOT, true)
        set(value) = prefs.edit().putBoolean(KEY_RESTORE_ON_BOOT, value).apply()

    var autoRestart: Boolean
        get() = prefs.getBoolean(KEY_AUTO_RESTART, true)
        set(value) = prefs.edit().putBoolean(KEY_AUTO_RESTART, value).apply()

    var perAppEnabled: Boolean
        get() = prefs.getBoolean(KEY_PER_APP_ENABLED, false)
        set(value) = prefs.edit().putBoolean(KEY_PER_APP_ENABLED, value).apply()


    // --- Eye care -----------------------------------------------------------

    var breaksEnabled: Boolean
        get() = prefs.getBoolean(KEY_BREAKS_ENABLED, true)
        set(value) = prefs.edit().putBoolean(KEY_BREAKS_ENABLED, value).apply()

    /** Minutes between eye breaks, 20 or 30 in the UI. */
    var breakIntervalMin: Int
        get() = prefs.getInt(KEY_BREAK_INTERVAL, 30).coerceIn(5, 120)
        set(value) = prefs.edit().putInt(KEY_BREAK_INTERVAL, value.coerceIn(5, 120)).apply()

    var breakLengthSec: Int
        get() = prefs.getInt(KEY_BREAK_LENGTH, 20).coerceIn(5, 120)
        set(value) = prefs.edit().putInt(KEY_BREAK_LENGTH, value.coerceIn(5, 120)).apply()

    var quietHoursEnabled: Boolean
        get() = prefs.getBoolean(KEY_QUIET_ENABLED, true)
        set(value) = prefs.edit().putBoolean(KEY_QUIET_ENABLED, value).apply()

    var quietStartMin: Int
        get() = prefs.getInt(KEY_QUIET_START, 23 * 60)
        set(value) = prefs.edit().putInt(KEY_QUIET_START, value.coerceIn(0, 1439)).apply()

    var quietEndMin: Int
        get() = prefs.getInt(KEY_QUIET_END, 7 * 60)
        set(value) = prefs.edit().putInt(KEY_QUIET_END, value.coerceIn(0, 1439)).apply()

    var eyeSound: Boolean
        get() = prefs.getBoolean(KEY_EYE_SOUND, true)
        set(value) = prefs.edit().putBoolean(KEY_EYE_SOUND, value).apply()

    var eyeVibrate: Boolean
        get() = prefs.getBoolean(KEY_EYE_VIBRATE, true)
        set(value) = prefs.edit().putBoolean(KEY_EYE_VIBRATE, value).apply()

    /** Shows the eye comfort percentage as an ongoing status bar notification. */
    var eyeStatusEnabled: Boolean
        get() = prefs.getBoolean(KEY_EYE_STATUS, true)
        set(value) = prefs.edit().putBoolean(KEY_EYE_STATUS, value).apply()

    var lastBreakAt: Long
        get() = prefs.getLong(KEY_LAST_BREAK, 0L)
        set(value) = prefs.edit().putLong(KEY_LAST_BREAK, value).apply()

    var nextBreakAt: Long
        get() = prefs.getLong(KEY_NEXT_BREAK, 0L)
        set(value) = prefs.edit().putLong(KEY_NEXT_BREAK, value).apply()

    /** Minutes of continuous screen time recorded since the last break. */
    var screenMinutesSinceBreak: Int
        get() = prefs.getInt(KEY_SCREEN_MINUTES, 0)
        set(value) = prefs.edit().putInt(KEY_SCREEN_MINUTES, value.coerceAtLeast(0)).apply()

    fun isQuietNow(now: java.util.Calendar = java.util.Calendar.getInstance()): Boolean {
        if (!quietHoursEnabled) return false
        val minute = now.get(java.util.Calendar.HOUR_OF_DAY) * 60 + now.get(java.util.Calendar.MINUTE)
        return EyeScore.isQuiet(minute, quietStartMin, quietEndMin)
    }

    /** Applies the eye care settings pushed from Flutter. */
    fun applyEyeCare(map: Map<*, *>) {
        (map["breaksEnabled"] as? Boolean)?.let { breaksEnabled = it }
        (map["intervalMin"] as? Number)?.let { breakIntervalMin = it.toInt() }
        (map["breakLengthSec"] as? Number)?.let { breakLengthSec = it.toInt() }
        (map["quietEnabled"] as? Boolean)?.let { quietHoursEnabled = it }
        (map["quietStartMin"] as? Number)?.let { quietStartMin = it.toInt() }
        (map["quietEndMin"] as? Number)?.let { quietEndMin = it.toInt() }
        (map["sound"] as? Boolean)?.let { eyeSound = it }
        (map["vibrate"] as? Boolean)?.let { eyeVibrate = it }
        (map["showEyeStatus"] as? Boolean)?.let { eyeStatusEnabled = it }
    }

    /** Map of package name to profile, stored as JSON so it is easy to diff. */
    var profiles: List<AppProfile>
        get() {
            val raw = prefs.getString(KEY_PROFILES, null) ?: return emptyList()
            return runCatching {
                val root = JSONObject(raw)
                root.keys().asSequence().map { pkg ->
                    val item = root.getJSONObject(pkg)
                    AppProfile(
                        packageName = pkg,
                        label = item.optString("label", pkg),
                        enabled = item.optBoolean("enabled", true),
                        intensity = item.optInt("intensity", 0),
                        kelvin = item.optInt("kelvin", 4500),
                    )
                }.toList()
            }.getOrDefault(emptyList())
        }
        set(value) {
            val root = JSONObject()
            value.forEach { profile ->
                root.put(
                    profile.packageName,
                    JSONObject().apply {
                        put("label", profile.label)
                        put("enabled", profile.enabled)
                        put("intensity", profile.intensity)
                        put("kelvin", profile.kelvin)
                    },
                )
            }
            prefs.edit().putString(KEY_PROFILES, root.toString()).apply()
        }

    fun saveSchedule(value: ScheduleSettings) {
        schedule = value
    }

    companion object {
        const val FILE = "lumashield_native"

        private const val KEY_ENABLED = "filter_enabled"
        private const val KEY_INTENSITY = "filter_intensity"
        private const val KEY_KELVIN = "filter_kelvin"
        private const val KEY_CUSTOM_COLOR = "filter_custom_color"
        private const val KEY_DIM = "filter_dim"
        private const val KEY_MODE_LABEL = "filter_mode_label"

        private const val KEY_SCHEDULE_ENABLED = "schedule_enabled"
        private const val KEY_SCHEDULE_MODE = "schedule_mode"
        private const val KEY_START_MIN = "schedule_start_min"
        private const val KEY_END_MIN = "schedule_end_min"
        private const val KEY_DAYS_MASK = "schedule_days_mask"
        private const val KEY_NIGHT_INTENSITY = "schedule_night_intensity"
        private const val KEY_NIGHT_KELVIN = "schedule_night_kelvin"
        private const val KEY_DAY_INTENSITY = "schedule_day_intensity"
        private const val KEY_DAY_KELVIN = "schedule_day_kelvin"
        private const val KEY_USE_LOCATION = "schedule_use_location"
        private const val KEY_LATITUDE = "schedule_latitude"
        private const val KEY_LONGITUDE = "schedule_longitude"
        private const val KEY_SUNRISE_OFFSET = "schedule_sunrise_offset"
        private const val KEY_SUNSET_OFFSET = "schedule_sunset_offset"

        private const val KEY_SHOW_NOTIFICATION = "service_show_notification"
        private const val KEY_NOTIFICATION_ACTIONS = "service_notification_actions"
        private const val KEY_RESTORE_ON_BOOT = "service_restore_on_boot"
        private const val KEY_AUTO_RESTART = "service_auto_restart"
        private const val KEY_PER_APP_ENABLED = "profiles_enabled"
        private const val KEY_PROFILES = "profiles_json"

        private const val KEY_BREAKS_ENABLED = "eye_breaks_enabled"
        private const val KEY_BREAK_INTERVAL = "eye_break_interval"
        private const val KEY_BREAK_LENGTH = "eye_break_length"
        private const val KEY_QUIET_ENABLED = "eye_quiet_enabled"
        private const val KEY_QUIET_START = "eye_quiet_start"
        private const val KEY_QUIET_END = "eye_quiet_end"
        private const val KEY_EYE_SOUND = "eye_sound"
        private const val KEY_EYE_VIBRATE = "eye_vibrate"
        private const val KEY_EYE_STATUS = "eye_status_enabled"
        private const val KEY_LAST_BREAK = "eye_last_break"
        private const val KEY_NEXT_BREAK = "eye_next_break"
        private const val KEY_SCREEN_MINUTES = "eye_screen_minutes"
    }
}
