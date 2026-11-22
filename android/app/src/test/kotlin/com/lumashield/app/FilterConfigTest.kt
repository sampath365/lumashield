package com.lumashield.app

import com.lumashield.app.filter.FilterConfig
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Verifies the overlay maths that decides what the user actually sees.
 * These run on the JVM, so the values here are the same ones the service uses
 * when it draws the window.
 */
class FilterConfigTest {

    private fun red(color: Int) = (color shr 16) and 0xFF
    private fun green(color: Int) = (color shr 8) and 0xFF
    private fun blue(color: Int) = color and 0xFF

    @Test
    fun `candle light is warm and blue is reduced`() {
        val color = FilterConfig.kelvinToColor(1900)
        assertTrue("red should dominate", red(color) > blue(color))
        assertTrue("red should be strong", red(color) > 240)
        assertTrue("blue should be low", blue(color) < 80)
    }

    @Test
    fun `neutral daylight is white`() {
        val color = FilterConfig.kelvinToColor(6500)
        assertTrue("red channel should be saturated", red(color) >= 254)
        assertTrue("green channel should be near white", green(color) >= 254)
        assertTrue("blue channel should be near saturated", blue(color) >= 245)
    }

    @Test
    fun `warmth rises as temperature falls`() {
        assertEquals(0f, FilterConfig(kelvin = 6500).warmth, 0.001f)
        assertEquals(1f, FilterConfig(kelvin = 1900).warmth, 0.001f)
        assertTrue(FilterConfig(kelvin = 3400).warmth > FilterConfig(kelvin = 4500).warmth)
    }

    @Test
    fun `neutral temperature adds no tint`() {
        val config = FilterConfig(intensity = 100, kelvin = 6500)
        assertEquals(0, config.tintAlpha)
    }

    @Test
    fun `maximum warmth and intensity stays translucent`() {
        val config = FilterConfig(intensity = 100, kelvin = 1900)
        // 72% of 255 = 183, so the screen is never fully covered.
        assertEquals(183, config.tintAlpha)
    }

    @Test
    fun `intensity scales the tint linearly`() {
        val half = FilterConfig(intensity = 50, kelvin = 1900).tintAlpha
        val full = FilterConfig(intensity = 100, kelvin = 1900).tintAlpha
        assertTrue(kotlin.math.abs(full / 2 - half) <= 1)
    }

    @Test
    fun `dim is capped so the screen stays readable`() {
        assertEquals(0, FilterConfig(dim = 0).dimAlpha)
        // The dim slider is capped at 80%, so the darkest overlay is 112/255.
        val atCap = FilterConfig(dim = 80).dimAlpha
        assertEquals(112, atCap)
        assertEquals(atCap, FilterConfig(dim = 100).dimAlpha)
    }

    @Test
    fun `custom colour overrides the temperature and respects intensity`() {
        val config = FilterConfig(intensity = 50, kelvin = 6500, customColor = 0xFFE8823C.toInt())
        assertEquals(0xE8823C, config.tintColor and 0xFFFFFF)
        assertTrue(config.tintAlpha > 0)
    }

    @Test
    fun `out of range values are clamped`() {
        val config = FilterConfig(intensity = 500, kelvin = 10, dim = 500)
        assertEquals(100, config.safeIntensity)
        assertEquals(1900, config.safeKelvin)
        assertEquals(80, config.safeDim)
    }

    @Test
    fun `platform map round trip keeps the important fields`() {
        val original = FilterConfig(
            enabled = true,
            intensity = 55,
            kelvin = 3300,
            customColor = null,
            dim = 12,
            modeLabel = "Night Mode",
        )
        val restored = FilterConfig.fromMap(original.toMap())
        assertEquals(original.copy(enabled = true), restored)
    }
}
