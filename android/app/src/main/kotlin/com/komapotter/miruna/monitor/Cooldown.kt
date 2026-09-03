package com.komapotter.miruna.monitor

object Cooldown {
    const val DEFAULT_PERIOD_MS = 60L * 60L * 1000L
    const val CLOSE_GRACE_MS = 3_000L

    const val ACTION_ALLOW = "allow"
    const val ACTION_WARN = "warn"

    fun decide(
        watched: Boolean,
        enabled: Boolean,
        sessionAllowed: Boolean,
        lastClosedAtMs: Long?,
        warningPeriodMs: Long,
        nowMs: Long,
    ): String {
        if (!watched || !enabled) return ACTION_ALLOW
        if (sessionAllowed) return ACTION_ALLOW
        if (lastClosedAtMs == null) return ACTION_ALLOW
        if (nowMs - lastClosedAtMs < warningPeriodMs) return ACTION_WARN
        return ACTION_ALLOW
    }

    fun shouldRecordClose(unconfirmedWarning: Boolean): Boolean = !unconfirmedWarning

    fun formatWarningPeriod(ms: Long): String {
        val totalMinutes = (ms / 60_000L).coerceAtLeast(0)
        val hours = totalMinutes / 60
        val minutes = totalMinutes % 60
        return when {
            hours > 0 && minutes > 0 -> "${hours}時間${minutes}分"
            hours > 0 -> "${hours}時間"
            else -> "${minutes}分"
        }
    }
}
