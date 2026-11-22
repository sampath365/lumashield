package com.lumashield.app.service

import android.content.ComponentName
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.lumashield.app.R
import com.lumashield.app.filter.FilterBus
import com.lumashield.app.filter.FilterPrefs

/**
 * Android quick settings tile. Tapping it toggles protection without opening
 * the app; the tile label and state always mirror the real service state.
 */
class FilterTileService : TileService() {

    companion object {
        fun requestTileUpdate(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
            runCatching {
                requestListeningState(
                    context,
                    ComponentName(context, FilterTileService::class.java),
                )
            }
        }
    }

    private val listener: (Map<String, Any?>) -> Unit = { render() }

    override fun onStartListening() {
        super.onStartListening()
        FilterBus.register(listener)
        render()
    }

    override fun onStopListening() {
        FilterBus.unregister(listener)
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()
        ProtectionActionReceiver.toggle(this)
        render()
    }

    private fun render() {
        val tile = qsTile ?: return
        val config = FilterPrefs(this).filter
        val active = OverlayFilterService.isRunning && config.enabled
        tile.state = if (active) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = getString(R.string.tile_label)
        tile.contentDescription = getString(
            if (active) R.string.tile_state_on else R.string.tile_state_off,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = if (active) {
                getString(R.string.tile_subtitle_active, config.safeIntensity)
            } else {
                getString(R.string.tile_subtitle_inactive)
            }
        }
        runCatching {
            tile.icon = Icon.createWithResource(this, R.drawable.ic_tile)
        }
        tile.updateTile()
    }
}
