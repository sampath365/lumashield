package com.lumashield.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.lumashield.app.MainActivity
import com.lumashield.app.R
import com.lumashield.app.filter.FilterConfig
import com.lumashield.app.filter.FilterPrefs
import com.lumashield.app.service.OverlayFilterService
import com.lumashield.app.service.ProtectionActionReceiver

/** Home screen widget with a live status line and a one tap toggle. */
class FilterWidgetProvider : AppWidgetProvider() {

    companion object {
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, FilterWidgetProvider::class.java),
            )
            ids.forEach { id -> manager.updateAppWidget(id, buildViews(context)) }
        }

        private fun buildViews(context: Context): RemoteViews {
            val prefs = FilterPrefs(context)
            val config = prefs.filter
            val active = OverlayFilterService.isRunning && config.enabled
            val views = RemoteViews(context.packageName, R.layout.filter_widget)
            views.setTextViewText(
                R.id.widget_status,
                if (active) {
                    context.getString(R.string.widget_active, config.safeIntensity)
                } else {
                    context.getString(R.string.widget_inactive)
                },
            )
            views.setTextViewText(
                R.id.widget_detail,
                if (active) {
                    context.getString(R.string.widget_detail, config.safeKelvin, config.modeLabel)
                } else {
                    context.getString(R.string.widget_tap_hint)
                },
            )
            views.setInt(
                R.id.widget_root,
                "setBackgroundResource",
                if (active) R.drawable.widget_background_active else R.drawable.widget_background,
            )
            views.setInt(
                R.id.widget_dot,
                "setBackgroundResource",
                if (active) R.drawable.widget_dot_active else R.drawable.widget_dot_idle,
            )

            val openIntent = Intent(context, MainActivity::class.java)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(
                    context,
                    10,
                    openIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            val toggleIntent = Intent(context, ProtectionActionReceiver::class.java).apply {
                action = ProtectionActionReceiver.ACTION_TOGGLE
            }
            views.setOnClickPendingIntent(
                R.id.widget_toggle,
                PendingIntent.getBroadcast(
                    context,
                    11,
                    toggleIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            return views
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, buildViews(context))
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.lumashield.app.widget.TOGGLE") {
            ProtectionActionReceiver.toggle(context)
            refresh(context)
            return
        }
        super.onReceive(context, intent)
    }
}
