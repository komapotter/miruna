package com.komapotter.miruna.monitor

import kotlin.random.Random

/**
 * Counts "見る" taps on a warning overlay before unlock is allowed.
 * One gate instance belongs to one overlay showing; call [reset] (or create a
 * new instance) whenever the overlay is shown again.
 *
 * The required tap count is drawn uniformly from [MIN_LOOK_TAPS]..[MAX_LOOK_TAPS]
 * (inclusive) on construction and again on [reset]. It stays fixed while one
 * overlay is showing. [random] and [requiredTaps] are injectable for tests.
 */
class LookTapGate(
    private val random: Random = Random.Default,
    requiredTaps: Int = drawRequiredTaps(random),
) {
    companion object {
        const val MIN_LOOK_TAPS = 5
        const val MAX_LOOK_TAPS = 50

        private fun drawRequiredTaps(random: Random): Int =
            random.nextInt(MIN_LOOK_TAPS, MAX_LOOK_TAPS + 1)
    }

    private var requiredTaps: Int = requiredTaps
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
        requiredTaps = drawRequiredTaps(random)
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
