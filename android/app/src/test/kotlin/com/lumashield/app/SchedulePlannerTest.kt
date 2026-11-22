package com.lumashield.app

import com.lumashield.app.filter.SchedulePlanner
import com.lumashield.app.filter.ScheduleSettings
import com.lumashield.app.filter.SolarCalc
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The schedule decides when protection switches itself on. These tests pin the
 * behaviour that the alarm receiver relies on: overnight windows, weekday
 * masks and the sunrise/sunset path.
 */
class SchedulePlannerTest {

    private val zone: ZoneId = ZoneId.of("Europe/London")

    private fun millis(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0): Long =
        ZonedDateTime.of(year, month, day, hour, minute, 0, 0, zone).toInstant().toEpochMilli()

    private val overnight = ScheduleSettings(
        enabled = true,
        startMinute = 21 * 60,
        endMinute = 7 * 60,
        nightIntensity = 65,
        nightKelvin = 3200,
        dayIntensity = 15,
        dayKelvin = 5400,
    )

    @Test
    fun `overnight window is active late at night`() {
        assertTrue(SchedulePlanner.isNight(millis(2026, 3, 10, 22, 30), overnight, zone))
    }

    @Test
    fun `overnight window is active in the early morning`() {
        assertTrue(SchedulePlanner.isNight(millis(2026, 3, 10, 2, 30), overnight, zone))
    }

    @Test
    fun `midday is outside the overnight window`() {
        assertFalse(SchedulePlanner.isNight(millis(2026, 3, 10, 12), overnight, zone))
    }

    @Test
    fun `night state uses the night intensity and temperature`() {
        val state = SchedulePlanner.stateAt(millis(2026, 3, 10, 23), overnight, zone)
        assertTrue(state.enabled)
        assertEquals(65, state.intensity)
        assertEquals(3200, state.kelvin)
    }

    @Test
    fun `day state uses the daytime filter`() {
        val state = SchedulePlanner.stateAt(millis(2026, 3, 10, 12), overnight, zone)
        assertTrue(state.enabled)
        assertEquals(15, state.intensity)
        assertEquals(5400, state.kelvin)
    }

    @Test
    fun `zero daytime intensity means the filter is off by day`() {
        val settings = overnight.copy(dayIntensity = 0)
        val state = SchedulePlanner.stateAt(millis(2026, 3, 10, 12), settings, zone)
        assertFalse(state.enabled)
    }

    @Test
    fun `next activation is the evening boundary`() {
        val next = SchedulePlanner.nextActivation(millis(2026, 3, 10, 12), overnight, zone)
        assertNotNull(next)
        assertEquals(millis(2026, 3, 10, 21), next)
    }

    @Test
    fun `next deactivation is the morning boundary`() {
        val next = SchedulePlanner.nextDeactivation(millis(2026, 3, 10, 23), overnight, zone)
        assertNotNull(next)
        assertEquals(millis(2026, 3, 11, 7), next)
    }

    @Test
    fun `weekday mask skips days that are not selected`() {
        val mondaysOnly = overnight.copy(daysMask = 0b0000001)
        // Tuesday 10 March 2026 midday.
        val now = millis(2026, 3, 10, 12)
        assertFalse(SchedulePlanner.isNight(now, mondaysOnly, zone))
        assertEquals(millis(2026, 3, 16, 21), SchedulePlanner.nextActivation(now, mondaysOnly, zone))
    }

    @Test
    fun `disabled schedule never activates`() {
        val disabled = overnight.copy(enabled = false)
        assertFalse(SchedulePlanner.isNight(millis(2026, 3, 10, 23), disabled, zone))
        assertNull(SchedulePlanner.nextActivation(millis(2026, 3, 10, 12), disabled, zone))
        assertNull(SchedulePlanner.nextTransition(millis(2026, 3, 10, 12), disabled, zone))
    }

    @Test
    fun `sunset mode uses real solar times`() {
        val sunSchedule = ScheduleSettings(
            enabled = true,
            mode = ScheduleSettings.MODE_SUN,
            useLocation = true,
            latitude = 51.5074,
            longitude = -0.1278,
            nightIntensity = 60,
            nightKelvin = 3000,
        )
        val next = SchedulePlanner.nextActivation(millis(2026, 6, 21, 12), sunSchedule, zone)
        assertNotNull(next)
        val local = java.time.Instant.ofEpochMilli(next!!).atZone(zone)
        assertTrue("sunset should be in the evening", local.hour in 20..22)
    }

    @Test
    fun `solar calculation returns a plausible day length`() {
        val times = SolarCalc.sunTimes(LocalDate.of(2026, 6, 21), 51.5074, -0.1278, zone)
        assertNotNull(times)
        val daylightHours = (times!!.second - times.first) / 3_600_000.0
        assertTrue(daylightHours in 15.0..18.0)
    }

    @Test
    fun `polar night has no sunrise`() {
        assertNull(SolarCalc.sunTimes(LocalDate.of(2026, 12, 21), 78.2, 15.6, zone))
    }
}
