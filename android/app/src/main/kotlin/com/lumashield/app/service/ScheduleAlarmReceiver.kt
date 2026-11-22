package com.lumashield.app.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.lumashield.app.filter.FilterPrefs
import com.lumashield.app.filter.FilterSupport
import com.lumashield.app.filter.SchedulePlanner

/**
 * Fires at schedule boundaries: turns the stronger night filter on at sunset or
 * at the configured start time, and restores the daytime state afterwards.
 */
class ScheduleAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_BOUNDARY = "com.lumashield.app.action.SCHEDULE_BOUNDARY"
        const val ACTION_RESTART = "com.lumashield.app.action.AUTO_RESTART"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_BOUNDARY -> handleBoundary(context)
            ACTION_RESTART -> handleRestart(context)
        }
    }

    private fun handleBoundary(context: Context) {
        val prefs = FilterPrefs(context)
        val schedule = prefs.schedule
        if (!schedule.enabled) {
            ScheduleAlarmScheduler.cancelBoundary(context)
            return
        }

        val now = System.currentTimeMillis()
        val applied = SchedulePlanner.stateAt(now, schedule)
        val current = prefs.filter
        prefs.filter = current.copy(
            enabled = applied.enabled,
            intensity = applied.intensity,
            kelvin = applied.kelvin,
            modeLabel = if (applied.enabled) "Scheduled night" else "Scheduled day",
        )

        if (applied.enabled && FilterSupport.canDrawOverlays(context)) {
            OverlayFilterService.start(context)
        } else if (!applied.enabled) {
            OverlayFilterService.stop(context)
            if (schedule.dayIntensity == 0) {
                NotificationHelper.showScheduleNotification(
                    context,
                    "Night protection finished",
                    "Tap to set tonight's schedule.",
                )
            }
        }

        ScheduleAlarmScheduler.scheduleNext(context)
    }

    private fun handleRestart(context: Context) {
        val prefs = FilterPrefs(context)
        if (prefs.filter.enabled && FilterSupport.canDrawOverlays(context)) {
            OverlayFilterService.start(context)
        }
    }
}
