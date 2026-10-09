package com.komapotter.miruna.monitor

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LookTapGateTest {
    @Test
    fun tapsOneThroughSevenDoNotUnlock() {
        val gate = LookTapGate()
        assertEquals(LookTapGate.REQUIRED_LOOK_TAPS, gate.remainingTaps)
        assertEquals("見る（あと8回）", gate.lookButtonLabel())

        for (tap in 1 until LookTapGate.REQUIRED_LOOK_TAPS) {
            assertFalse("tap $tap should not unlock", gate.registerLookTap())
            assertFalse(gate.isUnlocked)
            val remaining = LookTapGate.REQUIRED_LOOK_TAPS - tap
            assertEquals(remaining, gate.remainingTaps)
            if (remaining > 1) {
                assertEquals("見る（あと${remaining}回）", gate.lookButtonLabel())
            } else {
                assertEquals("見る", gate.lookButtonLabel())
            }
        }
    }

    @Test
    fun eighthTapUnlocksExactlyOnce() {
        val gate = LookTapGate()
        repeat(LookTapGate.REQUIRED_LOOK_TAPS - 1) {
            assertFalse(gate.registerLookTap())
        }

        assertTrue(gate.registerLookTap())
        assertTrue(gate.isUnlocked)
        assertEquals(0, gate.remainingTaps)
        assertEquals("見る", gate.lookButtonLabel())

        assertFalse("further taps must not unlock again", gate.registerLookTap())
        assertFalse(gate.registerLookTap())
    }

    @Test
    fun resetStartsCountingFromZero() {
        val gate = LookTapGate()
        repeat(5) { gate.registerLookTap() }
        assertEquals(3, gate.remainingTaps)

        gate.reset()
        assertEquals(LookTapGate.REQUIRED_LOOK_TAPS, gate.remainingTaps)
        assertFalse(gate.isUnlocked)
        assertEquals("見る（あと8回）", gate.lookButtonLabel())

        assertFalse(gate.registerLookTap())
        assertEquals(7, gate.remainingTaps)
        assertEquals("見る（あと7回）", gate.lookButtonLabel())
    }

    @Test
    fun resetAfterUnlockAllowsUnlockAgain() {
        val gate = LookTapGate()
        repeat(LookTapGate.REQUIRED_LOOK_TAPS - 1) { gate.registerLookTap() }
        assertTrue(gate.registerLookTap())
        assertFalse(gate.registerLookTap())

        gate.reset()
        repeat(LookTapGate.REQUIRED_LOOK_TAPS - 1) {
            assertFalse(gate.registerLookTap())
        }
        assertTrue(gate.registerLookTap())
    }
}
