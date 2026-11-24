package com.lumashield.app.service

import android.animation.ValueAnimator
import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.lumashield.app.MainActivity
import com.lumashield.app.filter.FilterPrefs
import com.lumashield.app.filter.FilterSupport
import kotlin.math.min
import kotlin.math.sin

/**
 * The eye break popup that appears above other apps.
 *
 * A notification is easy to miss, so when the overlay permission is granted the
 * break shows as a card over whatever is on screen, with an owl that blinks and
 * three actions. It never blocks the phone: it dismisses itself after a few
 * seconds and can always be closed with "Not now".
 */
object BreakPopup {

    private const val AUTO_DISMISS_MS = 30_000L
    private var view: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var dismissRunnable: Runnable? = null

    fun isShowing(): Boolean = view != null

    fun show(context: Context): Boolean {
        val prefs = FilterPrefs(context)
        if (!prefs.breakPopup) return false
        if (!FilterSupport.canDrawOverlays(context)) return false
        if (view != null) return true

        val app = context.applicationContext
        val windowManager =
            app.getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return false

        val screenWidth = app.resources.displayMetrics.widthPixels
        val cardWidth = min((screenWidth * 0.88f).toInt(), app.dp(360))

        val root = FrameLayout(app).apply {
            setBackgroundColor(Color.parseColor("#D90A1020"))
            alpha = 0f
        }

        val card = buildCard(app, cardWidth)
        val cardParams = FrameLayout.LayoutParams(cardWidth, FrameLayout.LayoutParams.WRAP_CONTENT)
            .apply { gravity = Gravity.CENTER }
        root.addView(card, cardParams)
        card.scaleX = 0.9f
        card.scaleY = 0.9f
        card.alpha = 0f

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            android.graphics.PixelFormat.TRANSLUCENT,
        )

        return try {
            windowManager.addView(root, params)
            view = root
            view?.setOnClickListener { dismiss(app) }

            root.animate().alpha(1f).setDuration(220).start()
            card.animate()
                .alpha(1f)
                .scaleX(1f)
                .scaleY(1f)
                .setInterpolator(DecelerateInterpolator())
                .setDuration(260)
                .start()

            dismissRunnable?.let { handler.removeCallbacks(it) }
            val runnable = Runnable { dismiss(app) }
            dismissRunnable = runnable
            handler.postDelayed(runnable, AUTO_DISMISS_MS)
            true
        } catch (error: Exception) {
            view = null
            false
        }
    }

    fun dismiss(context: Context) {
        val current = view ?: return
        view = null
        dismissRunnable?.let { handler.removeCallbacks(it) }
        dismissRunnable = null
        val windowManager =
            context.applicationContext.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        try {
            current.animate().alpha(0f).setDuration(180).withEndAction {
                runCatching { windowManager?.removeView(current) }
            }.start()
        } catch (_: Exception) {
            runCatching { windowManager?.removeView(current) }
        }
    }

    private fun buildCard(context: Context, width: Int): LinearLayout {
        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(context.dp(22), context.dp(22), context.dp(22), context.dp(18))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#151F33"))
                cornerRadius = context.dp(26).toFloat()
                setStroke(context.dp(1), Color.parseColor("#2A3A55"))
            }
            isClickable = true
            setOnClickListener { /* swallow taps so the app behind stays untouched */ }
        }

        card.addView(
            OwlView(context),
            LinearLayout.LayoutParams(context.dp(140), context.dp(140)),
        )

        card.addView(
            TextView(context).apply {
                text = "Time for an eye break"
                setTextColor(Color.parseColor("#F2F6FF"))
                textSize = 19f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                gravity = Gravity.CENTER
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = context.dp(10) },
        )

        val minutes = ((System.currentTimeMillis() - FilterPrefs(context).lastBreakAt) / 60_000L)
            .coerceAtLeast(0)
        card.addView(
            TextView(context).apply {
                text = "You have been looking at the screen for $minutes minutes. " +
                    "Look 20 feet away and blink slowly."
                setTextColor(Color.parseColor("#9FAFC8"))
                textSize = 13.5f
                gravity = Gravity.CENTER
                setLineSpacing(context.dp(3).toFloat(), 1f)
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = context.dp(8) },
        )

        val start = pillButton(context, "Start exercise", filled = true) {
            dismiss(context)
            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(MainActivity.EXTRA_LAUNCH_ACTION, MainActivity.LAUNCH_ACTION_EYE_BREAK)
            }
            runCatching { context.startActivity(launch) }
        }
        card.addView(
            start,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                context.dp(46),
            ).apply { topMargin = context.dp(16) },
        )

        val row = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
        }
        val snooze = pillButton(context, "Snooze 5m", filled = false) {
            dismiss(context)
            EyeBreakScheduler.snooze(context, minutes = 5)
            NotificationHelper.cancelEyeBreakNotification(context)
        }
        val notNow = pillButton(context, "Not now", filled = false) { dismiss(context) }
        row.addView(
            snooze,
            LinearLayout.LayoutParams(0, context.dp(42), 1f).apply { rightMargin = context.dp(8) },
        )
        row.addView(notNow, LinearLayout.LayoutParams(0, context.dp(42), 1f))
        card.addView(
            row,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = context.dp(8) },
        )

        return card
    }

    private fun pillButton(
        context: Context,
        label: String,
        filled: Boolean,
        onClick: () -> Unit,
    ): TextView = TextView(context).apply {
        text = label
        gravity = Gravity.CENTER
        textSize = 14f
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        setTextColor(if (filled) Color.parseColor("#1B1206") else Color.parseColor("#C9D4E6"))
        background = GradientDrawable().apply {
            setColor(if (filled) Color.parseColor("#F0A44A") else Color.parseColor("#1E2A40"))
            cornerRadius = context.dp(14).toFloat()
            if (!filled) setStroke(context.dp(1), Color.parseColor("#2A3A55"))
        }
        isClickable = true
        setOnClickListener { onClick() }
    }
}

/** The owl from the in-app exercise, animated with a slow blink. */
private class OwlView(context: Context) : View(context) {
    private val blink = ValueAnimator.ofFloat(0f, 1f).apply {
        duration = 4200
        repeatCount = ValueAnimator.INFINITE
        addUpdateListener { invalidate() }
        start()
    }

    private val body = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#1B2740") }
    private val feather = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#243453") }
    private val amber = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#F0A44A") }
    private val dark = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#0A1020") }
    private val white = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#F7FAFF") }
    private val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 3f
        color = Color.parseColor("#F0A44A")
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val t = blink.animatedFraction
        val blinkAmount = if (t > 0.9) sin((t - 0.9) / 0.1 * Math.PI).toFloat() else 0f
        val cx = w / 2
        val cy = h / 2 + h * 0.03f

        val tuft = Path().apply {
            moveTo(w * 0.24f, h * 0.30f)
            lineTo(w * 0.30f, h * 0.10f)
            lineTo(w * 0.44f, h * 0.27f)
            close()
        }
        val tuft2 = Path().apply {
            moveTo(w * 0.76f, h * 0.30f)
            lineTo(w * 0.70f, h * 0.10f)
            lineTo(w * 0.56f, h * 0.27f)
            close()
        }
        canvas.drawPath(tuft, feather)
        canvas.drawPath(tuft2, feather)

        canvas.drawCircle(cx, cy, w * 0.36f, body)
        canvas.drawOval(
            RectF(cx - w * 0.26f, h * 0.63f, cx + w * 0.26f, h * 0.95f),
            body,
        )
        canvas.drawOval(
            RectF(cx - w * 0.16f, h * 0.70f, cx + w * 0.16f, h * 0.90f),
            feather,
        )

        val eyeR = w * 0.155f
        val eyeY = cy
        for (dx in listOf(-w * 0.12f, w * 0.12f)) {
            val ex = cx + dx
            canvas.drawCircle(ex, eyeY, eyeR, white)
            canvas.drawCircle(ex, eyeY, eyeR, stroke)
            canvas.drawCircle(ex, eyeY + eyeR * 0.05f, eyeR * 0.46f, dark)
            canvas.drawCircle(ex - eyeR * 0.14f, eyeY - eyeR * 0.2f, eyeR * 0.12f, white)
            if (blinkAmount > 0.02f) {
                val lid = RectF(
                    ex - eyeR,
                    eyeY - eyeR,
                    ex + eyeR,
                    eyeY - eyeR + eyeR * 2 * blinkAmount,
                )
                canvas.save()
                canvas.clipRect(lid)
                canvas.drawCircle(ex, eyeY, eyeR, body)
                canvas.restore()
            }
        }

        val beak = Path().apply {
            moveTo(cx - w * 0.04f, h * 0.60f)
            lineTo(cx + w * 0.04f, h * 0.60f)
            lineTo(cx, h * 0.70f)
            close()
        }
        canvas.drawPath(beak, amber)
        canvas.drawCircle(cx - w * 0.08f, h * 0.93f, w * 0.035f, amber)
        canvas.drawCircle(cx + w * 0.08f, h * 0.93f, w * 0.035f, amber)
    }

    override fun onDetachedFromWindow() {
        blink.cancel()
        super.onDetachedFromWindow()
    }
}

private fun Context.dp(value: Int): Int =
    (value * resources.displayMetrics.density).toInt()
