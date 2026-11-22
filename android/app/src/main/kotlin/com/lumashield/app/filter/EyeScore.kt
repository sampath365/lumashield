package com.lumashield.app.filter

/**
 * The eye comfort percentage shown in the status bar.
 *
 * The formula is deliberately simple and explainable, because a made up number
 * would be worse than no number:
 *
 *  - start at 100,
 *  - lose one point per minute of continuous screen time, capped at 70,
 *  - gain up to ten points for a strong filter,
 *  - clamp to 0..100.
 *
 * A completed break, or five minutes with the screen off, resets the clock.
 * It is a pacing guide, not a medical measurement.
 */
object EyeScore {

    const val MAX_PENALTY = 70
    const val MAX_FILTER_BONUS = 10

    fun score(minutesSinceBreak: Int, filterIntensity: Int): Int {
        val minutes = minutesSinceBreak.coerceAtLeast(0)
        val penalty = minutes.coerceAtMost(MAX_PENALTY)
        val bonus = (filterIntensity.coerceIn(0, 100) / 10).coerceAtMost(MAX_FILTER_BONUS)
        return (100 - penalty + bonus).coerceIn(0, 100)
    }

    /** True when [minuteOfDay] falls inside a quiet window that may wrap midnight. */
    fun isQuiet(minuteOfDay: Int, startMinute: Int, endMinute: Int): Boolean {
        if (startMinute == endMinute) return false
        val minute = ((minuteOfDay % 1440) + 1440) % 1440
        return if (startMinute < endMinute) {
            minute >= startMinute && minute < endMinute
        } else {
            minute >= startMinute || minute < endMinute
        }
    }

    /** Whole minutes between two instants, never negative. */
    fun minutesBetween(fromMs: Long, toMs: Long): Int =
        ((toMs - fromMs).coerceAtLeast(0) / 60_000L).toInt()
}
