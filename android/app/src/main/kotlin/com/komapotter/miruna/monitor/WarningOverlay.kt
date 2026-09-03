package com.komapotter.miruna.monitor

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.os.Build
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class WarningOverlay(private val context: Context) {
    private val windowManager =
        context.applicationContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var view: View? = null
    var currentPackage: String? = null
        private set

    val isShowing: Boolean
        get() = view != null

    fun show(
        packageName: String,
        appName: String,
        warningPeriodMs: Long,
        onYes: () -> Unit,
        onNo: () -> Unit,
    ) {
        if (view != null && currentPackage == packageName) return
        dismiss()
        currentPackage = packageName
        val period = Cooldown.formatWarningPeriod(warningPeriodMs)
        val overlay = buildView(appName, period, onYes, onNo)
        val params =
            WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR,
                PixelFormat.TRANSLUCENT,
            )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            params.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        try {
            windowManager.addView(overlay, params)
            view = overlay
        } catch (_: Exception) {
            currentPackage = null
        }
    }

    fun dismiss() {
        val current = view ?: return
        view = null
        currentPackage = null
        try {
            windowManager.removeView(current)
        } catch (_: Exception) {
            // Already detached.
        }
    }

    private fun buildView(
        appName: String,
        period: String,
        onYes: () -> Unit,
        onNo: () -> Unit,
    ): View {
        val density = context.resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()

        val root =
            LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(0xCC0F172A.toInt())
                gravity = Gravity.CENTER
                setPadding(dp(24), dp(24), dp(24), dp(24))
            }

        val card =
            LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(Color.WHITE)
                setPadding(dp(24), dp(24), dp(24), dp(20))
                elevation = dp(8).toFloat()
            }

        val title =
            TextView(context).apply {
                text = appName
                setTextColor(0xFF0F172A.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                typeface = Typeface.DEFAULT_BOLD
            }
        val message =
            TextView(context).apply {
                text = "前回の起動から${period}経っていません。本当に開きますか？"
                setTextColor(0xFF334155.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                setPadding(0, dp(12), 0, dp(20))
            }

        val buttons =
            LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.END
            }

        val noButton =
            Button(context).apply {
                text = "いいえ"
                backgroundTintList = ColorStateList.valueOf(0xFF2563EB.toInt())
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                setOnClickListener { onNo() }
            }
        val yesButton =
            Button(context).apply {
                text = "はい"
                backgroundTintList = ColorStateList.valueOf(Color.TRANSPARENT)
                setTextColor(0xFF64748B.toInt())
                setOnClickListener { onYes() }
            }

        val buttonLp =
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            )
        buttonLp.marginStart = dp(8)
        buttons.addView(noButton, buttonLp)
        buttons.addView(yesButton, buttonLp)

        card.addView(title)
        card.addView(message)
        card.addView(buttons)
        root.addView(
            card,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ),
        )
        return root
    }
}
