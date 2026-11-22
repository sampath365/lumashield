package com.lumashield.app.filter

import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset
import kotlin.math.acos
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.tan

/**
 * Sunrise / sunset via the standard solar position equations. Accurate to
 * roughly a minute, which is plenty for scheduling a screen filter, and it runs
 * offline with no Play Services dependency.
 */
object SolarCalc {

    /** Returns local sunrise and sunset millis, or null during polar day/night. */
    fun sunTimes(date: LocalDate, latitude: Double, longitude: Double, zone: ZoneId): Pair<Long, Long>? {
        val dayOfYear = date.dayOfYear
        val lngHour = longitude / 15.0

        fun event(isSunrise: Boolean): Double? {
            val t = dayOfYear + ((if (isSunrise) 6.0 else 18.0) - lngHour) / 24.0
            val m = 0.9856 * t - 3.289
            val lRaw = m + 1.916 * sin(Math.toRadians(m)) +
                0.020 * sin(Math.toRadians(2 * m)) + 282.634
            val l = normalize(lRaw)
            var ra = normalize(Math.toDegrees(kotlin.math.atan(0.91764 * tan(Math.toRadians(l)))))
            val lQuadrant = (l / 90.0).toInt() * 90.0
            val raQuadrant = (ra / 90.0).toInt() * 90.0
            ra = (ra + (lQuadrant - raQuadrant)) / 15.0
            val sinDec = 0.39782 * sin(Math.toRadians(l))
            val cosDec = cos(asin(sinDec))
            val cosH = (cos(Math.toRadians(90.833)) - sinDec * sin(Math.toRadians(latitude))) /
                (cosDec * cos(Math.toRadians(latitude)))
            if (cosH > 1.0 || cosH < -1.0) return null
            val h = (if (isSunrise) 360.0 - Math.toDegrees(acos(cosH)) else Math.toDegrees(acos(cosH))) / 15.0
            val localMean = h + ra - 0.06571 * t - 6.622
            return ((localMean - lngHour) % 24.0 + 24.0) % 24.0
        }

        val sunriseHours = event(true) ?: return null
        val sunsetHours = event(false) ?: return null
        return toMillis(date, sunriseHours) to toMillis(date, sunsetHours)
    }

    private fun normalize(value: Double): Double = ((value % 360.0) + 360.0) % 360.0

    private fun toMillis(date: LocalDate, utcHours: Double): Long {
        val utcMinutes = Math.round(utcHours * 60.0).toLong()
        return date.atStartOfDay(ZoneOffset.UTC)
            .plusMinutes(utcMinutes)
            .toInstant()
            .toEpochMilli()
    }

}
