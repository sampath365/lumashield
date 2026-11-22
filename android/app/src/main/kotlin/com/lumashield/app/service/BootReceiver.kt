package com.lumashield.app.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.lumashield.app.filter.FilterPrefs
import com.lumashield.app.filter.FilterSupport
import com.lumashield.app.filter.SchedulePlanner

/**
 * Restores the previous filter settings and schedule after a reboot or an app
 * update. This only runs when the user left "restore after restart" enabled and
 * the overlay permission is still granted.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        val prefs = FilterPrefs(context)
        val schedule = prefs.schedule

        if (schedule.enabled) {
            val applied = SchedulePlanner.stateAt(System.currentTimeMillis(), schedule)
            prefs.filter = prefs.filter.copy(
                enabled = applied.enabled,
                intensity = applied.intensity,
                kelvin = applied.kelvin,
            )
            ScheduleAlarmScheduler.scheduleNext(context)
        }

        val shouldRestore = prefs.restoreOnBoot && prefs.filter.enabled
        if (shouldRestore && FilterSupport.canDrawOverlays(context)) {
            OverlayFilterService.start(context)
        }
    }
}
