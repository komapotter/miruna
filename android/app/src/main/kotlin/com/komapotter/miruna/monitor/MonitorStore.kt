package com.komapotter.miruna.monitor

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class MonitorStore(context: Context) {
    private val prefs =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun getApps(): List<WatchedAppEntity> {
        val raw = prefs.getString(KEY_APPS, "[]") ?: "[]"
        val array = JSONArray(raw)
        val apps = ArrayList<WatchedAppEntity>(array.length())
        for (i in 0 until array.length()) {
            apps.add(fromJson(array.getJSONObject(i)))
        }
        return apps
    }

    fun getApp(packageName: String): WatchedAppEntity? =
        getApps().firstOrNull { it.packageName == packageName }

    fun upsertConfig(
        packageName: String,
        displayName: String,
        warningPeriodMs: Long,
        enabled: Boolean,
    ) {
        val current = getApps().toMutableList()
        val index = current.indexOfFirst { it.packageName == packageName }
        val updated =
            if (index >= 0) {
                current[index].copy(
                    displayName = displayName,
                    warningPeriodMs = warningPeriodMs,
                    enabled = enabled,
                )
            } else {
                WatchedAppEntity(
                    packageName = packageName,
                    displayName = displayName,
                    warningPeriodMs = warningPeriodMs,
                    enabled = enabled,
                    lastClosedAtMs = null,
                    sessionAllowed = false,
                )
            }
        if (index >= 0) {
            current[index] = updated
        } else {
            current.add(updated)
        }
        saveApps(current)
    }

    fun remove(packageName: String) {
        saveApps(getApps().filterNot { it.packageName == packageName })
    }

    fun recordClose(packageName: String, closedAtMs: Long) {
        update(packageName) { it.copy(lastClosedAtMs = closedAtMs, sessionAllowed = false) }
    }

    fun setSessionAllowed(packageName: String, allowed: Boolean) {
        update(packageName) { it.copy(sessionAllowed = allowed) }
    }

    fun getDefaultWarningPeriodMs(): Long =
        prefs.getLong(KEY_DEFAULT_PERIOD, Cooldown.DEFAULT_PERIOD_MS)

    fun setDefaultWarningPeriodMs(ms: Long) {
        prefs.edit().putLong(KEY_DEFAULT_PERIOD, ms).apply()
    }

    fun isMonitoringEnabled(): Boolean = prefs.getBoolean(KEY_MONITORING, false)

    fun setMonitoringEnabled(enabled: Boolean) {
        prefs.edit().putBoolean(KEY_MONITORING, enabled).apply()
    }

    fun recordDecision(packageName: String, yes: Boolean, nowMs: Long = System.currentTimeMillis()) {
        val root = JSONObject(prefs.getString(KEY_DECISIONS, "{}") ?: "{}")
        val appObj = root.optJSONObject(packageName) ?: JSONObject().also { root.put(packageName, it) }
        val date = DecisionCounts.localDateKey(nowMs)
        val day = appObj.optJSONObject(date) ?: JSONObject().also { appObj.put(date, it) }
        val key = if (yes) "yes" else "no"
        day.put(key, day.optInt(key, 0) + 1)
        prefs.edit().putString(KEY_DECISIONS, root.toString()).apply()
    }

    fun getDecisionCounts(
        packageName: String?,
        fromDate: String?,
        toDate: String?,
    ): List<Map<String, Any>> {
        val root = JSONObject(prefs.getString(KEY_DECISIONS, "{}") ?: "{}")
        val packages =
            if (packageName.isNullOrEmpty()) {
                root.keys().asSequence().toList().sorted()
            } else {
                listOf(packageName)
            }
        val result = ArrayList<Map<String, Any>>()
        for (pkg in packages) {
            val days = root.optJSONObject(pkg) ?: continue
            val dateKeys = days.keys().asSequence().toList().sorted()
            for (date in dateKeys) {
                if (!DecisionCounts.dateInRange(date, fromDate, toDate)) continue
                val tally = days.optJSONObject(date) ?: continue
                result.add(
                    mapOf(
                        "packageName" to pkg,
                        "date" to date,
                        "yesCount" to tally.optInt("yes", 0),
                        "noCount" to tally.optInt("no", 0),
                    ),
                )
            }
        }
        return result
    }

    private fun update(
        packageName: String,
        transform: (WatchedAppEntity) -> WatchedAppEntity,
    ) {
        val current = getApps().toMutableList()
        val index = current.indexOfFirst { it.packageName == packageName }
        if (index < 0) return
        current[index] = transform(current[index])
        saveApps(current)
    }

    private fun saveApps(apps: List<WatchedAppEntity>) {
        val array = JSONArray()
        apps.forEach { array.put(toJson(it)) }
        prefs.edit().putString(KEY_APPS, array.toString()).apply()
    }

    private fun toJson(app: WatchedAppEntity): JSONObject =
        JSONObject().apply {
            put("packageName", app.packageName)
            put("displayName", app.displayName)
            put("warningPeriodMs", app.warningPeriodMs)
            put("enabled", app.enabled)
            if (app.lastClosedAtMs != null) {
                put("lastClosedAtMs", app.lastClosedAtMs)
            } else {
                put("lastClosedAtMs", JSONObject.NULL)
            }
            put("sessionAllowed", app.sessionAllowed)
        }

    private fun fromJson(obj: JSONObject): WatchedAppEntity {
        val closed =
            if (obj.isNull("lastClosedAtMs")) null else obj.optLong("lastClosedAtMs")
        return WatchedAppEntity(
            packageName = obj.getString("packageName"),
            displayName = obj.getString("displayName"),
            warningPeriodMs = obj.optLong("warningPeriodMs", Cooldown.DEFAULT_PERIOD_MS),
            enabled = obj.optBoolean("enabled", true),
            lastClosedAtMs = closed,
            sessionAllowed = obj.optBoolean("sessionAllowed", false),
        )
    }

    companion object {
        private const val PREFS = "miruna_monitor"
        private const val KEY_APPS = "watched_apps"
        private const val KEY_DEFAULT_PERIOD = "default_warning_period_ms"
        private const val KEY_MONITORING = "monitoring_enabled"
        private const val KEY_DECISIONS = "decision_counts"
    }
}
