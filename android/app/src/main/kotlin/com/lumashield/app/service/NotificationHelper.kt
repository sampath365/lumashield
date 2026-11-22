package com.lumashield.app.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.lumashield.app.MainActivity
import com.lumashield.app.R
import com.lumashield.app.filter.FilterConfig
import com.lumashield.app.filter.FilterSupport

/**
 * Notification channels and the persistent protection notification.
 *
 * The protection notification is deliberately low importance so it never makes
 * a sound, and it carries a pause/resume action plus a shortcut back into the
 * app.
 */
object NotificationHelper {

    const val CHANNEL_SERVICE = "protection_service"
    const val CHANNEL_REMINDERS = "eye_reminders"
    const val CHANNEL_SCHEDULE = "schedule_changes"

    const val SERVICE_NOTIFICATION_ID = 1001
    const val REMINDER_NOTIFICATION_ID = 2001

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return

        val service = NotificationChannel(
            CHANNEL_SERVICE,
            context.getString(R.string.channel_service_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.channel_service_description)
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }

        val reminders = NotificationChannel(
            CHANNEL_REMINDERS,
            context.getString(R.string.channel_reminders_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = context.getString(R.string.channel_reminders_description)
            enableVibration(true)
        }

        val schedule = NotificationChannel(
            CHANNEL_SCHEDULE,
            context.getString(R.string.channel_schedule_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.channel_schedule_description)
            setShowBadge(false)
        }

        manager.createNotificationChannels(listOf(service, reminders, schedule))
    }

    private fun contentIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun toggleIntent(context: Context): PendingIntent {
        val intent = Intent(context, OverlayFilterService::class.java).apply {
            action = OverlayFilterService.ACTION_TOGGLE
        }
        return PendingIntent.getService(
            context,
            1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun buildServiceNotification(
        context: Context,
        config: FilterConfig,
        scheduleSummary: String?,
        nextEvent: String?,
        showActions: Boolean,
    ): Notification {
        val strength = FilterSupport.strengthPercent(config)
        val title = if (config.enabled) {
            context.getString(R.string.notification_active_title)
        } else {
            context.getString(R.string.notification_paused_title)
        }
        val detail = if (config.enabled) {
            context.getString(
                R.string.notification_active_text,
                strength,
                config.safeKelvin,
                config.modeLabel,
            )
        } else {
            context.getString(R.string.notification_paused_text)
        }
        val expanded = buildList {
            add(detail)
            if (!scheduleSummary.isNullOrBlank()) add(scheduleSummary)
            if (!nextEvent.isNullOrBlank()) add(nextEvent)
        }.joinToString("\n")

        val builder = NotificationCompat.Builder(context, CHANNEL_SERVICE)
            .setSmallIcon(R.drawable.ic_stat_shield)
            .setColor(Color.parseColor("#F0A44A"))
            .setContentTitle(title)
            .setContentText(detail)
            .setStyle(NotificationCompat.BigTextStyle().bigText(expanded))
            .setContentIntent(contentIntent(context))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)

        if (showActions) {
            builder.addAction(
                0,
                context.getString(
                    if (config.enabled) R.string.action_pause else R.string.action_resume,
                ),
                toggleIntent(context),
            )
        }

        return builder.build()
    }

    fun updateServiceNotification(
        context: Context,
        config: FilterConfig,
        scheduleSummary: String?,
        nextEvent: String?,
        showActions: Boolean,
        showNotification: Boolean,
    ) {
        if (!showNotification) return
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        runCatching {
            manager.notify(
                SERVICE_NOTIFICATION_ID,
                buildServiceNotification(context, config, scheduleSummary, nextEvent, showActions),
            )
        }
    }

    fun cancelServiceNotification(context: Context) {
        runCatching {
            NotificationManagerCompat.from(context).cancel(SERVICE_NOTIFICATION_ID)
        }
    }

    fun showScheduleNotification(context: Context, title: String, text: String) {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        val notification = NotificationCompat.Builder(context, CHANNEL_SCHEDULE)
            .setSmallIcon(R.drawable.ic_stat_shield)
            .setColor(Color.parseColor("#F0A44A"))
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(contentIntent(context))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        runCatching { manager.notify(REMINDER_NOTIFICATION_ID, notification) }
    }
}
