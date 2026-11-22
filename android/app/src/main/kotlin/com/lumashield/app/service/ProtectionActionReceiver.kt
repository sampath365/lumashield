package com.lumashield.app.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.lumashield.app.filter.FilterPrefs
import com.lumashield.app.widget.FilterWidgetProvider

/**
 * Single entry point for toggles that come from outside the Flutter UI: the
 * quick settings tile, the home screen widget and the emergency disable action.
 */
class ProtectionActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_TOGGLE = "com.lumashield.app.action.WIDGET_TOGGLE"
        const val ACTION_EMERGENCY_DISABLE = "com.lumashield.app.action.EMERGENCY_DISABLE"

        fun toggle(context: Context) {
            OverlayFilterService.toggle(context)
            refreshSurfaces(context)
        }

        fun emergencyDisable(context: Context) {
            val prefs = FilterPrefs(context)
            prefs.filter = prefs.filter.copy(enabled = false)
            OverlayFilterService.stop(context)
            refreshSurfaces(context)
        }

        private fun refreshSurfaces(context: Context) {
            FilterTileService.requestTileUpdate(context)
            FilterWidgetProvider.refresh(context)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TOGGLE -> toggle(context)
            ACTION_EMERGENCY_DISABLE -> emergencyDisable(context)
        }
    }
}
