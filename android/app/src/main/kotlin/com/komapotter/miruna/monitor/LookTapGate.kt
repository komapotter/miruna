package com.komapotter.miruna.monitor

/**
 * Counts "見る" taps on a warning overlay before unlock is allowed.
 * One gate instance belongs to one overlay showing; call [reset] (or create a
 * new instance) whenever the overlay is shown again.
 */
class LookTapGate(
    private val requiredTaps: Int = REQUIRED_LOOK_TAPS,
) {
    companion object {
        const val REQUIRED_LOOK_TAPS = 8
    }

    private var tapCount: Int = 0
    private var unlockedOnce: Boolean = false

    val remainingTaps: Int
        get() = (requiredTaps - tapCount).coerceAtLeast(0)

    val isUnlocked: Boolean
        get() = tapCount >= requiredTaps

    /**
     * Register one "見る" tap.
     *
     * @return `true` only on the tap that first reaches [requiredTaps]
     * (so [onYes] / `confirmOpen` runs once).
     */
    fun registerLookTap(): Boolean {
        if (unlockedOnce) return false
        tapCount += 1
        if (tapCount < requiredTaps) return false
        unlockedOnce = true
        return true
    }

    fun reset() {
        tapCount = 0
        unlockedOnce = false
    }

    /** Label for the look button: "見る（あとN回）" until one tap left, then "見る". */
    fun lookButtonLabel(): String {
        val remaining = remainingTaps
        return if (remaining > 1) {
            "見る（あと${remaining}回）"
        } else {
            "見る"
        }
    }
}
