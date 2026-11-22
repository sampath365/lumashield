package com.lumashield.app.service

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.lumashield.app.filter.FilterPrefs
import com.lumashield.app.filter.SchedulePlanner

/**
 * Schedules the next schedule boundary and the optional auto restart.
 *
 * Exact alarms are used when the user granted the special access; otherwise the
 * app falls back to inexact alarms, which may fire a few minutes late. Nothing
 * here tries to bypass the platform's alarm limits.
 */
object ScheduleAlarmScheduler {

    private const val REQUEST_CODE_BOUNDARY = 3001
    private const val REQUEST_CODE_RESTART = 3002

    private fun alarmManager(context: Context): AlarmManager? =
        context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

    private fun boundaryIntent(context: Context): PendingIntent {
        val intent = Intent(context, ScheduleAlarmReceiver::class.java).apply {
            action = ScheduleAlarmReceiver.ACTION_BOUNDARY
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_BOUNDARY,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun restartIntent(context: Context): PendingIntent {
        val intent = Intent(context, ScheduleAlarmReceiver::class.java).apply {
            action = ScheduleAlarmReceiver.ACTION_RESTART
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_RESTART,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun canScheduleExact(context: Context): Boolean {
        val manager = alarmManager(context) ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            manager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    fun scheduleNext(context: Context) {
        val prefs = FilterPrefs(context)
        val schedule = prefs.schedule
        val manager = alarmManager(context) ?: return
        val pending = boundaryIntent(context)

        if (!schedule.enabled) {
            manager.cancel(pending)
            return
        }

        val next = SchedulePlanner.nextTransition(System.currentTimeMillis(), schedule) ?: run {
            manager.cancel(pending)
            return
        }

        runCatching {
            if (canScheduleExact(context)) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.first, pending)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.first, pending)
            }
        }.onFailure {
            // Some OEMs still throw on exact alarms; degrade to an inexact one.
            runCatching { manager.set(AlarmManager.RTC_WAKEUP, next.first, pending) }
        }
    }

    fun cancelBoundary(context: Context) {
        alarmManager(context)?.cancel(boundaryIntent(context))
    }

    fun scheduleRestart(context: Context) {
        val manager = alarmManager(context) ?: return
        val pending = restartIntent(context)
        val whenMs = System.currentTimeMillis() + 15_000
        runCatching {
            if (canScheduleExact(context)) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, whenMs, pending)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, whenMs, pending)
            }
        }
    }
}
