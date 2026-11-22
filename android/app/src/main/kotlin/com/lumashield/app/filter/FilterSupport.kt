package com.lumashield.app.filter

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.provider.Settings

/**
 * Broadcasts protection state changes to whoever is listening in this process:
 * the Flutter event channel, the quick settings tile and the home screen widget.
 */
object FilterBus {
    private val listeners = mutableListOf<(Map<String, Any?>) -> Unit>()

    fun register(listener: (Map<String, Any?>) -> Unit) {
        listeners.add(listener)
    }

    fun unregister(listener: (Map<String, Any?>) -> Unit) {
        listeners.remove(listener)
    }

    fun emit(state: Map<String, Any?>) {
        listeners.toList().forEach { listener ->
            runCatching { listener(state) }
        }
    }
}

/** Small helpers shared by the service, receivers and tile. */
object FilterSupport {

    fun canDrawOverlays(context: Context): Boolean = Settings.canDrawOverlays(context)

    fun openOverlaySettings(context: Context) {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            android.net.Uri.parse("package:${context.packageName}"),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        runCatching { context.startActivity(intent) }
    }

    /** Rough perceived filter strength used by the UI and the notification. */
    fun strengthPercent(config: FilterConfig): Int {
        val tint = config.tintAlpha / 255f / FilterConfig.MAX_TINT_ALPHA
        val dim = config.dimAlpha / 255f / FilterConfig.MAX_DIM_ALPHA
        return ((tint * 0.8f + dim * 0.2f) * 100).toInt().coerceIn(0, 100)
    }

    fun tintColorFor(config: FilterConfig): Int = config.tintColor

    fun describeTemperature(kelvin: Int): String = when {
        kelvin <= 2400 -> "Candle"
        kelvin <= 3000 -> "Warm red"
        kelvin <= 3600 -> "Amber"
        kelvin <= 4200 -> "Warm"
        kelvin <= 5000 -> "Soft white"
        kelvin <= 5800 -> "Daylight"
        else -> "Neutral"
    }

    fun blend(base: Int, overlay: Int, amount: Float): Int {
        val a = amount.coerceIn(0f, 1f)
        return Color.rgb(
            (Color.red(base) * (1 - a) + Color.red(overlay) * a).toInt(),
            (Color.green(base) * (1 - a) + Color.green(overlay) * a).toInt(),
            (Color.blue(base) * (1 - a) + Color.blue(overlay) * a).toInt(),
        )
    }
}
