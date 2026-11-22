package com.lumashield.app.service

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.lumashield.app.MainActivity
import com.lumashield.app.filter.FilterPrefs

/**
 * Handles the eye break alarm and the actions on the reminder notification.
 *
 * The reminder is a heads-up notification with three actions, so the user can
 * start the guided exercise, snooze five minutes, or mark the break done
 * without opening the app.
 */
class EyeBreakReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_BREAK = "com.lumashield.app.action.EYE_BREAK"
        const val ACTION_DONE = "com.lumashield.app.action.EYE_BREAK_DONE"
        const val ACTION_SNOOZE = "com.lumashield.app.action.EYE_BREAK_SNOOZE"
        const val ACTION_START = "com.lumashield.app.action.EYE_BREAK_START"
        const val ACTION_REFRESH_STATUS = "com.lumashield.app.action.EYE_STATUS_REFRESH"
        const val NOTIFICATION_ID = 5200
    }

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = FilterPrefs(context)
        when (intent.action) {
            ACTION_BREAK -> {
                if (!prefs.breaksEnabled) {
                    EyeBreakScheduler.cancel(context)
                    return
                }
                if (prefs.isQuietNow()) {
                    // Do not buzz during quiet hours, just arm the next one.
                    EyeBreakScheduler.scheduleNext(context)
                    return
                }
                NotificationHelper.showEyeBreakNotification(context)
                EyeBreakScheduler.scheduleNext(context)
                EyeStatusNotifier.update(context)
            }

            ACTION_START -> {
                val launch = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(MainActivity.EXTRA_LAUNCH_ACTION, MainActivity.LAUNCH_ACTION_EYE_BREAK)
                }
                runCatching { context.startActivity(launch) }
                NotificationHelper.cancelEyeBreakNotification(context)
            }

            ACTION_DONE -> {
                EyeStatusNotifier.registerRest(context)
                NotificationHelper.cancelEyeBreakNotification(context)
                EyeBreakScheduler.scheduleNext(context)
            }

            ACTION_SNOOZE -> {
                NotificationHelper.cancelEyeBreakNotification(context)
                EyeBreakScheduler.snooze(context, minutes = 5)
                EyeStatusNotifier.update(context)
            }

            ACTION_REFRESH_STATUS -> EyeStatusNotifier.update(context)
        }
    }
}
