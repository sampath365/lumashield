package com.lumashield.app.filter

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * Turns a [ScheduleSettings] description into concrete windows of time and
 * answers two questions for the rest of the app:
 *
 *  - what should the filter look like right now?
 *  - when is the next boundary, so an alarm can be set for it?
 *
 * Both custom clock times and sunrise/sunset schedules are supported, including
 * windows that cross midnight and weekday selections.
 */
object SchedulePlanner {

    /** A night window during which the stronger night filter applies. */
    data class Window(val startMs: Long, val endMs: Long)

    data class Applied(val enabled: Boolean, val intensity: Int, val kelvin: Int)

    fun windowsAround(
        nowMs: Long,
        settings: ScheduleSettings,
        zone: ZoneId = ZoneId.systemDefault(),
    ): List<Window> {
        if (!settings.enabled) return emptyList()
        val today = Instant.ofEpochMilli(nowMs).atZone(zone).toLocalDate()
        val windows = mutableListOf<Window>()

        for (offset in -2..8) {
            val date = today.plusDays(offset.toLong())
            // DateTime.weekday - 1 semantics: Monday is 0.
            val dayIndex = date.dayOfWeek.value - 1
            if (!settings.isDayEnabled(dayIndex)) continue

            if (settings.mode == ScheduleSettings.MODE_SUN && settings.hasLocation) {
                val todayTimes = SolarCalc.sunTimes(date, settings.latitude, settings.longitude, zone)
                    ?: continue
                val tomorrowTimes = SolarCalc.sunTimes(date.plusDays(1), settings.latitude, settings.longitude, zone)
                    ?: continue
                val start = todayTimes.second + settings.sunsetOffsetMin * 60_000L
                val end = tomorrowTimes.first + settings.sunriseOffsetMin * 60_000L
                if (end > start) windows += Window(start, end)
            } else {
                val dayStart = date.atStartOfDay(zone)
                val start = dayStart.plusMinutes(settings.startMinute.toLong()).toInstant().toEpochMilli()
                val endMinutes = if (settings.endMinute <= settings.startMinute) {
                    settings.endMinute + 24 * 60
                } else {
                    settings.endMinute
                }
                val end = dayStart.plusMinutes(endMinutes.toLong()).toInstant().toEpochMilli()
                windows += Window(start, end)
            }
        }
        return windows.sortedBy { it.startMs }
    }

    fun isNight(nowMs: Long, settings: ScheduleSettings, zone: ZoneId = ZoneId.systemDefault()): Boolean =
        windowsAround(nowMs, settings, zone).any { nowMs >= it.startMs && nowMs < it.endMs }

    /** The filter that should be active at [nowMs]. */
    fun stateAt(nowMs: Long, settings: ScheduleSettings, zone: ZoneId = ZoneId.systemDefault()): Applied {
        if (!settings.enabled) return Applied(false, settings.dayIntensity, settings.dayKelvin)
        val night = isNight(nowMs, settings, zone)
        return if (night) {
            Applied(true, settings.nightIntensity, settings.nightKelvin)
        } else {
            Applied(settings.dayIntensity > 0, settings.dayIntensity, settings.dayKelvin)
        }
    }

    /** Next boundary in millis plus the state that begins at it. */
    fun nextTransition(
        nowMs: Long,
        settings: ScheduleSettings,
        zone: ZoneId = ZoneId.systemDefault(),
    ): Pair<Long, Applied>? {
        if (!settings.enabled) return null
        val boundaries = mutableListOf<Long>()
        windowsAround(nowMs, settings, zone).forEach { window ->
            if (window.startMs > nowMs) boundaries += window.startMs
            if (window.endMs > nowMs) boundaries += window.endMs
        }
        val next = boundaries.minOrNull() ?: return null
        return next to stateAt(next + 1000, settings, zone)
    }

    /** Next moment the stronger night filter switches on. */
    fun nextActivation(
        nowMs: Long,
        settings: ScheduleSettings,
        zone: ZoneId = ZoneId.systemDefault(),
    ): Long? {
        if (!settings.enabled) return null
        return windowsAround(nowMs, settings, zone)
            .map { it.startMs }
            .filter { it > nowMs }
            .minOrNull()
    }

    fun nextDeactivation(
        nowMs: Long,
        settings: ScheduleSettings,
        zone: ZoneId = ZoneId.systemDefault(),
    ): Long? {
        if (!settings.enabled) return null
        return windowsAround(nowMs, settings, zone)
            .map { it.endMs }
            .filter { it > nowMs }
            .minOrNull()
    }

    /** Human readable summary used in the persistent notification. */
    fun describe(settings: ScheduleSettings): String {
        if (!settings.enabled) return "Schedule off"
        return if (settings.mode == ScheduleSettings.MODE_SUN && settings.hasLocation) {
            "Sunset to sunrise"
        } else {
            "%s - %s".format(formatMinutes(settings.startMinute), formatMinutes(settings.endMinute))
        }
    }

    fun formatMinutes(minutes: Int): String {
        val normalized = ((minutes % 1440) + 1440) % 1440
        return "%02d:%02d".format(normalized / 60, normalized % 60)
    }

    fun nowIn(zone: ZoneId = ZoneId.systemDefault()): ZonedDateTime = ZonedDateTime.now(zone)

    fun todayIn(zone: ZoneId = ZoneId.systemDefault()): LocalDate = LocalDate.now(zone)
}
