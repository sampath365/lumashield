package com.lumashield.app.filter

import kotlin.math.ln
import kotlin.math.pow

/**
 * Immutable description of the screen filter that is currently requested.
 *
 * Values are produced by the Flutter layer and mirrored into [FilterPrefs] so
 * that the overlay service, boot receiver, alarm receiver and quick settings
 * tile all keep working while Flutter is not running.
 */
data class FilterConfig(
    val enabled: Boolean = false,
    val intensity: Int = 30,
    val kelvin: Int = 4500,
    val customColor: Int? = null,
    val dim: Int = 0,
    val modeLabel: String = "Eye Protection",
) {
    val safeIntensity: Int get() = intensity.coerceIn(0, 100)
    val safeKelvin: Int get() = kelvin.coerceIn(1900, 6500)
    val safeDim: Int get() = dim.coerceIn(0, 80)

    /** 0.0 at neutral daylight (6500 K) up to 1.0 at deep candle light (1900 K). */
    val warmth: Float get() = ((6500 - safeKelvin) / 4600f).coerceIn(0f, 1f)

    /** Colour composited above the screen. */
    val tintColor: Int
        get() = customColor?.let {
            packRgb((it shr 16) and 0xFF, (it shr 8) and 0xFF, it and 0xFF)
        } ?: kelvinToColor(safeKelvin)

    /**
     * Temperature defines the colour, intensity scales how much of it is laid
     * over the screen. A neutral 6500 K filter therefore adds no tint, which is
     * the physically honest result.
     */
    val tintAlpha: Int
        get() {
            val base = if (customColor != null) 1f else warmth
            return (safeIntensity / 100f * base * MAX_TINT_ALPHA * 255).toInt().coerceIn(0, 255)
        }

    /** Extra neutral darkening used by the brightness slider. */
    val dimAlpha: Int get() = (safeDim / 100f * MAX_DIM_ALPHA * 255).toInt().coerceIn(0, 255)

    fun toMap(): Map<String, Any?> = mapOf(
        "enabled" to enabled,
        "intensity" to safeIntensity,
        "kelvin" to safeKelvin,
        "customColor" to customColor,
        "dim" to safeDim,
        "modeLabel" to modeLabel,
    )

    companion object {
        /** Keeping some screen light through the tint preserves contrast. */
        const val MAX_TINT_ALPHA = 0.72f
        const val MAX_DIM_ALPHA = 0.55f

        fun fromMap(map: Map<*, *>?): FilterConfig {
            if (map == null) return FilterConfig()
            return FilterConfig(
                enabled = map["enabled"] as? Boolean ?: false,
                intensity = (map["intensity"] as? Number)?.toInt() ?: 30,
                kelvin = (map["kelvin"] as? Number)?.toInt() ?: 4500,
                customColor = (map["customColor"] as? Number)?.toInt(),
                dim = (map["dim"] as? Number)?.toInt() ?: 0,
                modeLabel = map["modeLabel"] as? String ?: "Eye Protection",
            )
        }

        /**
         * Black body approximation (Tanner Helland) in sRGB. Used for the
         * overlay tint and the in-app preview so both always agree.
         */
        fun packRgb(red: Int, green: Int, blue: Int): Int =
            (0xFF shl 24) or (red.coerceIn(0, 255) shl 16) or
                (green.coerceIn(0, 255) shl 8) or blue.coerceIn(0, 255)

        fun kelvinToColor(kelvin: Int): Int {
            val temp = kelvin.coerceIn(1000, 40000) / 100.0
            val red = if (temp <= 66) 255.0 else 329.698727446 * (temp - 60).pow(-0.1332047592)
            val green = if (temp <= 66) {
                99.4708025861 * ln(temp) - 161.1195681661
            } else {
                288.1221695283 * (temp - 60).pow(-0.0755148492)
            }
            val blue = when {
                temp >= 66 -> 255.0
                temp <= 19 -> 0.0
                else -> 138.5177312231 * ln(temp - 10) - 305.0447927307
            }
            return packRgb(
                red.toInt().coerceIn(0, 255),
                green.toInt().coerceIn(0, 255),
                blue.toInt().coerceIn(0, 255),
            )
        }
    }
}
