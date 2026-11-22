package com.lumashield.app.filter

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.view.View

/**
 * The view that is added to WindowManager above all apps.
 *
 * Two layers are drawn: an optional neutral dim used by the brightness slider,
 * then the warm tint. Compositing an amber layer over the screen removes
 * proportionally more blue than red, which is exactly the effect of a blue
 * light filter, and it needs no root access.
 */
@SuppressLint("ViewConstructor")
class OverlayView(context: Context) : View(context) {

    private val tintPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val dimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.BLACK
    }

    fun apply(config: FilterConfig) {
        tintPaint.color = config.tintColor
        tintPaint.alpha = config.tintAlpha
        dimPaint.alpha = config.dimAlpha
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val h = height.toFloat()
        if (dimPaint.alpha > 0) canvas.drawRect(0f, 0f, w, h, dimPaint)
        if (tintPaint.alpha > 0) canvas.drawRect(0f, 0f, w, h, tintPaint)
    }
}
