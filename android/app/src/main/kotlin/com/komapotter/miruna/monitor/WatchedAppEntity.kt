package com.komapotter.miruna.monitor

import org.json.JSONObject

data class WatchedAppEntity(
    val packageName: String,
    val displayName: String,
    val warningPeriodMs: Long,
    val enabled: Boolean,
    val lastClosedAtMs: Long?,
    val sessionAllowed: Boolean,
    val cooldownPeriodMs: Long = 0L,
    val unlockedUntilMs: Long? = null,
) {
    fun toJson(): JSONObject =
        JSONObject().apply {
            put("packageName", packageName)
            put("displayName", displayName)
            put("warningPeriodMs", warningPeriodMs)
            put("enabled", enabled)
            if (lastClosedAtMs != null) {
                put("lastClosedAtMs", lastClosedAtMs)
            } else {
                put("lastClosedAtMs", JSONObject.NULL)
            }
            put("sessionAllowed", sessionAllowed)
            put("cooldownPeriodMs", cooldownPeriodMs)
            if (unlockedUntilMs != null) {
                put("unlockedUntilMs", unlockedUntilMs)
            } else {
                put("unlockedUntilMs", JSONObject.NULL)
            }
        }

    companion object {
        fun fromJson(obj: JSONObject): WatchedAppEntity {
            val closed =
                if (obj.isNull("lastClosedAtMs")) null else obj.optLong("lastClosedAtMs")
            val unlockedUntil =
                if (obj.isNull("unlockedUntilMs")) null else obj.optLong("unlockedUntilMs")
            return WatchedAppEntity(
                packageName = obj.getString("packageName"),
                displayName = obj.getString("displayName"),
                warningPeriodMs = obj.optLong("warningPeriodMs", Cooldown.DEFAULT_PERIOD_MS),
                enabled = obj.optBoolean("enabled", true),
                lastClosedAtMs = closed,
                sessionAllowed = obj.optBoolean("sessionAllowed", false),
                cooldownPeriodMs = obj.optLong("cooldownPeriodMs", 0L),
                unlockedUntilMs = unlockedUntil,
            )
        }
    }
}
