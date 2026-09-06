package com.komapotter.miruna.monitor

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class WarningOverlay(private val context: Context) {
    companion object {
        /** 見る: sin. Keep in sync with DecisionBarChart.yesColor. */
        val LOOK_COLOR = 0xFFB91C1C.toInt()

        /** 見ない: resisted temptation. Keep in sync with DecisionBarChart.noColor. */
        val SKIP_COLOR = 0xFFD1D5DB.toInt()
    }

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
        todayYesCount: Int,
        onYes: () -> Unit,
        onNo: () -> Unit,
    ) {
        if (view != null && currentPackage == packageName) return
        dismiss()
        currentPackage = packageName
        val period = Cooldown.formatWarningPeriod(warningPeriodMs)
        val overlay = buildView(appName, period, todayYesCount, onYes, onNo)
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
        todayYesCount: Int,
        onYes: () -> Unit,
        onNo: () -> Unit,
    ): View {
        val density = context.resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()

        val root =
            LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(0xE6140C0C.toInt())
                gravity = Gravity.CENTER
                setPadding(dp(24), dp(24), dp(24), dp(24))
            }

        val card =
            LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                background =
                    GradientDrawable().apply {
                        setColor(0xFF1A1212.toInt())
                        setStroke(dp(1), 0xFF8B1A1A.toInt())
                    }
                setPadding(dp(24), dp(24), dp(24), dp(20))
                elevation = dp(8).toFloat()
            }

        val title =
            TextView(context).apply {
                text = appName
                setTextColor(0xFFF5F0F0.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                typeface = Typeface.DEFAULT_BOLD
            }
        val todayOpenMessage = DecisionCounts.formatTodayOpenMessage(todayYesCount)
        val message =
            TextView(context).apply {
                text = "前回の起動から${period}経っていません。本当に見ますか？"
                setTextColor(0xFFC4B8B8.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                setPadding(0, dp(12), 0, if (todayOpenMessage.isEmpty()) dp(20) else dp(8))
            }

        val buttons =
            LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.END
            }

        val yesButton =
            Button(context).apply {
                text = "見る"
                backgroundTintList = ColorStateList.valueOf(LOOK_COLOR)
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                setOnClickListener { onYes() }
            }
        val noButton =
            Button(context).apply {
                text = "見ない"
                backgroundTintList = ColorStateList.valueOf(SKIP_COLOR)
                setTextColor(0xFF1A1212.toInt())
                typeface = Typeface.DEFAULT_BOLD
                setOnClickListener { onNo() }
            }

        val buttonLp =
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            )
        buttonLp.marginStart = dp(8)
        buttons.addView(yesButton, buttonLp)
        buttons.addView(noButton, buttonLp)

        card.addView(title)
        card.addView(message)
        if (todayOpenMessage.isNotEmpty()) {
            val todayCount =
                TextView(context).apply {
                    text = todayOpenMessage
                    setTextColor(0xFF8A8080.toInt())
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                    setPadding(0, 0, 0, dp(20))
                }
            card.addView(todayCount)
        }
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
