package com.lumashield.app

import com.lumashield.app.filter.EyeScore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The eye comfort percentage is shown in the status bar, so its maths has to be
 * predictable and honest. These tests pin the exact behaviour.
 */
class EyeScoreTest {

    @Test
    fun `fresh after a break with no filter is 100`() {
        assertEquals(100, EyeScore.score(minutesSinceBreak = 0, filterIntensity = 0))
    }

    @Test
    fun `drops one point per minute of screen time`() {
        assertEquals(90, EyeScore.score(minutesSinceBreak = 10, filterIntensity = 0))
        assertEquals(80, EyeScore.score(minutesSinceBreak = 20, filterIntensity = 0))
        assertEquals(70, EyeScore.score(minutesSinceBreak = 30, filterIntensity = 0))
    }

    @Test
    fun `a strong filter adds up to ten points`() {
        assertEquals(90, EyeScore.score(minutesSinceBreak = 20, filterIntensity = 100))
        assertEquals(85, EyeScore.score(minutesSinceBreak = 20, filterIntensity = 50))
    }

    @Test
    fun `penalty is capped so the score never collapses to zero from time alone`() {
        val longSession = EyeScore.score(minutesSinceBreak = 500, filterIntensity = 0)
        assertEquals(30, longSession)
        assertTrue(longSession > 0)
    }

    @Test
    fun `score is clamped to one hundred`() {
        assertEquals(100, EyeScore.score(minutesSinceBreak = 0, filterIntensity = 100))
    }

    @Test
    fun `negative minutes are treated as zero`() {
        assertEquals(100, EyeScore.score(minutesSinceBreak = -30, filterIntensity = 0))
    }

    @Test
    fun `minutesBetween never goes negative`() {
        assertEquals(0, EyeScore.minutesBetween(10_000L, 5_000L))
        assertEquals(2, EyeScore.minutesBetween(0L, 120_000L))
    }

    @Test
    fun `quiet hours wrap around midnight`() {
        // 23:00 to 07:00
        val start = 23 * 60
        val end = 7 * 60
        assertTrue(EyeScore.isQuiet(23 * 60 + 30, start, end))
        assertTrue(EyeScore.isQuiet(2 * 60, start, end))
        assertFalse(EyeScore.isQuiet(12 * 60, start, end))
        assertFalse(EyeScore.isQuiet(7 * 60, start, end))
    }

    @Test
    fun `quiet hours inside one day work too`() {
        // 13:00 to 14:00
        val start = 13 * 60
        val end = 14 * 60
        assertTrue(EyeScore.isQuiet(13 * 60 + 30, start, end))
        assertFalse(EyeScore.isQuiet(12 * 60 + 30, start, end))
        assertFalse(EyeScore.isQuiet(14 * 60, start, end))
    }

    @Test
    fun `an empty quiet window disables itself`() {
        assertFalse(EyeScore.isQuiet(13 * 60, 13 * 60, 13 * 60))
    }
}
