package com.lumashield.app.service

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.lumashield.app.filter.FilterPrefs

/**
 * Fires the eye break reminder every N minutes, even when the app is closed.
 *
 * A one shot alarm is used rather than a repeating one so the interval and the
 * quiet hours are always read fresh from the preferences. Each alarm arms the
 * next one, which also means the schedule survives reboots and doze.
 */
object EyeBreakScheduler {

    private const val REQUEST_BREAK = 4101
    private const val REQUEST_STATUS = 4102

    private fun alarmManager(context: Context): AlarmManager? =
        context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

    private fun breakIntent(context: Context): PendingIntent {
        val intent = Intent(context, EyeBreakReceiver::class.java).apply {
            action = EyeBreakReceiver.ACTION_BREAK
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_BREAK,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun statusIntent(context: Context): PendingIntent {
        val intent = Intent(context, EyeBreakReceiver::class.java).apply {
            action = EyeBreakReceiver.ACTION_REFRESH_STATUS
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_STATUS,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun canExact(context: Context): Boolean {
        val manager = alarmManager(context) ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            manager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    fun scheduleNext(context: Context, delayMinutes: Int? = null) {
        val prefs = FilterPrefs(context)
        val manager = alarmManager(context) ?: return
        if (!prefs.breaksEnabled) {
            cancel(context)
            return
        }
        val minutes = delayMinutes ?: prefs.breakIntervalMin
        val whenMs = System.currentTimeMillis() + minutes * 60_000L
        prefs.nextBreakAt = whenMs
        val pending = breakIntent(context)
        runCatching {
            if (canExact(context)) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, whenMs, pending)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, whenMs, pending)
            }
        }.onFailure {
            runCatching { manager.set(AlarmManager.RTC_WAKEUP, whenMs, pending) }
        }
    }

    fun snooze(context: Context, minutes: Int = 5) {
        scheduleNext(context, delayMinutes = minutes)
    }

    fun cancel(context: Context) {
        val prefs = FilterPrefs(context)
        prefs.nextBreakAt = 0
        alarmManager(context)?.cancel(breakIntent(context))
    }

    /**
     * A cheap inexact repeating refresh keeps the eye percentage in the status
     * bar current without waking the device precisely every minute.
     */
    fun startStatusRefresh(context: Context) {
        val prefs = FilterPrefs(context)
        val manager = alarmManager(context) ?: return
        val pending = statusIntent(context)
        if (!prefs.eyeStatusEnabled) {
            manager.cancel(pending)
            EyeStatusNotifier.cancel(context)
            return
        }
        runCatching {
            manager.setInexactRepeating(
                AlarmManager.RTC,
                System.currentTimeMillis() + 15 * 60_000L,
                15 * 60_000L,
                pending,
            )
        }
    }
}
