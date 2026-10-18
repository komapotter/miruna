package com.komapotter.miruna.monitor

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WatchedAppEntityTest {
    @Test
    fun missingCooldownFieldsParseAsDisabled() {
        val obj =
            JSONObject(
                """
                {
                  "packageName": "com.instagram.android",
                  "displayName": "Instagram",
                  "warningPeriodMs": 3600000,
                  "enabled": true,
                  "lastClosedAtMs": 1000,
                  "sessionAllowed": false
                }
                """.trimIndent(),
            )

        val app = WatchedAppEntity.fromJson(obj)

        assertEquals(0L, app.cooldownPeriodMs)
        assertNull(app.unlockedUntilMs)
        assertEquals(1000L, app.lastClosedAtMs)
        assertEquals(false, app.sessionAllowed)
    }

    @Test
    fun cooldownFieldsRoundTrip() {
        val original =
            WatchedAppEntity(
                packageName = "com.instagram.android",
                displayName = "Instagram",
                warningPeriodMs = 3_600_000L,
                enabled = true,
                lastClosedAtMs = 1_000L,
                sessionAllowed = false,
                cooldownPeriodMs = 900_000L,
                unlockedUntilMs = 2_000L,
            )

        val parsed = WatchedAppEntity.fromJson(original.toJson())

        assertEquals(original, parsed)
    }

    @Test
    fun explicitNullUnlockedUntilParsesAsNull() {
        val obj =
            JSONObject(
                """
                {
                  "packageName": "com.instagram.android",
                  "displayName": "Instagram",
                  "warningPeriodMs": 3600000,
                  "enabled": true,
                  "lastClosedAtMs": null,
                  "sessionAllowed": false,
                  "cooldownPeriodMs": 900000,
                  "unlockedUntilMs": null
                }
                """.trimIndent(),
            )

        val app = WatchedAppEntity.fromJson(obj)

        assertEquals(900_000L, app.cooldownPeriodMs)
        assertNull(app.unlockedUntilMs)
        assertNull(app.lastClosedAtMs)
    }
}
