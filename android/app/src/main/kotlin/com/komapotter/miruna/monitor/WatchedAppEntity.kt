package com.komapotter.miruna.monitor

data class WatchedAppEntity(
    val packageName: String,
    val displayName: String,
    val warningPeriodMs: Long,
    val enabled: Boolean,
    val lastClosedAtMs: Long?,
    val sessionAllowed: Boolean,
)
