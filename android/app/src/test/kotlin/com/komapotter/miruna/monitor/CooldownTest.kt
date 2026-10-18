package com.komapotter.miruna.monitor

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class CooldownTest {
    private val now = 1_000_000L
    private val hourMs = 60L * 60L * 1000L
    private val minuteMs = 60L * 1000L

    @Test
    fun allowsReopenWhileUnlockCooldownIsActive() {
        val action =
            Cooldown.decide(
                watched = true,
                enabled = true,
                sessionAllowed = false,
                lastClosedAtMs = now - minuteMs,
                warningPeriodMs = hourMs,
                nowMs = now,
                unlockedUntilMs = now + 4 * minuteMs,
            )
        assertEquals(Cooldown.ACTION_ALLOW, action)
    }

    @Test
    fun usesWarningPeriodAfterUnlockCooldownExpires() {
        val action =
            Cooldown.decide(
                watched = true,
                enabled = true,
                sessionAllowed = false,
                lastClosedAtMs = now - 20 * minuteMs,
                warningPeriodMs = hourMs,
                nowMs = now,
                unlockedUntilMs = now - minuteMs,
            )
        assertEquals(Cooldown.ACTION_WARN, action)
    }

    @Test
    fun keepsOldBehaviourWhenCooldownIsDisabled() {
        val action =
            Cooldown.decide(
                watched = true,
                enabled = true,
                sessionAllowed = false,
                lastClosedAtMs = now - 5 * minuteMs,
                warningPeriodMs = hourMs,
                nowMs = now,
                unlockedUntilMs = null,
            )
        assertEquals(Cooldown.ACTION_WARN, action)
    }

    @Test
    fun allowsAfterWarningPeriodWhenCooldownExpired() {
        val action =
            Cooldown.decide(
                watched = true,
                enabled = true,
                sessionAllowed = false,
                lastClosedAtMs = now - hourMs,
                warningPeriodMs = hourMs,
                nowMs = now,
                unlockedUntilMs = now - minuteMs,
            )
        assertEquals(Cooldown.ACTION_ALLOW, action)
    }

    @Test
    fun unlockedUntilMsIsNullWhenCooldownDisabled() {
        assertNull(Cooldown.unlockedUntilMs(now, 0L))
    }

    @Test
    fun unlockedUntilMsCountsFromUnlockTime() {
        assertEquals(now + 5 * minuteMs, Cooldown.unlockedUntilMs(now, 5 * minuteMs))
    }
}
