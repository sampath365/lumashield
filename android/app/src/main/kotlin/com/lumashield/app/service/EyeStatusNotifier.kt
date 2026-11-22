package com.lumashield.app.service

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.lumashield.app.MainActivity
import com.lumashield.app.R
import com.lumashield.app.filter.EyeScore
import com.lumashield.app.filter.FilterPrefs

/**
 * The eye comfort percentage that sits in the status bar.
 *
 * It is a plain, explainable score, not a medical measurement:
 *   start at 100, lose one point per minute of continuous screen time since the
 *   last break (capped at 70), and gain up to ten points for a strong filter.
 * The score resets when a break is completed or the screen has been off long
 * enough to count as rest.
 */
object EyeStatusNotifier {

    const val NOTIFICATION_ID = 1200
    const val CHANNEL_EYE_STATUS = "eye_status"
    private const val SCREEN_OFF_REST_MS = 5 * 60_000L

    fun ensureBaseline(prefs: FilterPrefs) {
        if (prefs.lastBreakAt <= 0L) prefs.lastBreakAt = System.currentTimeMillis()
    }

    fun computeScore(prefs: FilterPrefs, now: Long = System.currentTimeMillis()): Int {
        ensureBaseline(prefs)
        val minutes = EyeScore.minutesBetween(prefs.lastBreakAt, now)
        return EyeScore.score(minutes, prefs.filter.safeIntensity)
    }

    fun minutesUntilBreak(prefs: FilterPrefs, now: Long = System.currentTimeMillis()): Int? {
        if (!prefs.breaksEnabled || prefs.nextBreakAt <= 0L) return null
        val remaining = prefs.nextBreakAt - now
        if (remaining <= 0) return 0
        return ((remaining + 59_999) / 60_000L).toInt()
    }

    private fun contentIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_LAUNCH_ACTION, MainActivity.LAUNCH_ACTION_EYE_BREAK)
        }
        return PendingIntent.getActivity(
            context,
            21,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun update(context: Context) {
        val prefs = FilterPrefs(context)
        if (!prefs.eyeStatusEnabled) {
            cancel(context)
            return
        }
        ensureBaseline(prefs)
        val score = computeScore(prefs)
        val untilBreak = minutesUntilBreak(prefs)
        val filter = prefs.filter

        val detail = buildString {
            if (untilBreak != null) {
                append(if (untilBreak <= 0) "Break due now" else "Next break in ${untilBreak}m")
            } else {
                append("Breaks off")
            }
            if (filter.enabled) {
                append(" · filter ${filter.safeIntensity}%")
            }
            append(" · tap to rest your eyes")
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_EYE_STATUS)
            .setSmallIcon(R.drawable.ic_stat_shield)
            .setContentTitle("Eye comfort $score%")
            .setContentText(detail)
            .setProgress(100, score, false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(contentIntent(context))
            .build()

        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        runCatching { manager.notify(NOTIFICATION_ID, notification) }
    }

    fun cancel(context: Context) {
        runCatching {
            NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
        }
    }

    /** A rest, a completed break or a long screen-off period resets the clock. */
    fun registerRest(context: Context, resetScreenMinutes: Boolean = true) {
        val prefs = FilterPrefs(context)
        prefs.lastBreakAt = System.currentTimeMillis()
        if (resetScreenMinutes) prefs.screenMinutesSinceBreak = 0
        update(context)
    }

    fun handleScreenState(context: Context, interactive: Boolean, lastInteractiveAt: Long) {
        if (interactive) {
            // Returning after a long pause counts as rest.
            if (lastInteractiveAt > 0 &&
                System.currentTimeMillis() - lastInteractiveAt >= SCREEN_OFF_REST_MS
            ) {
                registerRest(context)
            }
            return
        }
        if (lastInteractiveAt > 0 &&
            System.currentTimeMillis() - lastInteractiveAt >= SCREEN_OFF_REST_MS
        ) {
            registerRest(context)
        }
    }

    fun cancelChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.cancel(NOTIFICATION_ID)
    }
}
