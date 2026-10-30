package com.komapotter.miruna.monitor

import kotlin.random.Random
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LookTapGateTest {
    @Test
    fun drawnRequiredTapsAlwaysInInclusiveRange() {
        repeat(300) {
            val gate = LookTapGate()
            assertTrue(
                "drawn ${gate.remainingTaps} should be in " +
                    "${LookTapGate.MIN_LOOK_TAPS}..${LookTapGate.MAX_LOOK_TAPS}",
                gate.remainingTaps in LookTapGate.MIN_LOOK_TAPS..LookTapGate.MAX_LOOK_TAPS,
            )
        }
    }

    @Test
    fun minAndMaxDrawsAreInclusive() {
        assertEquals(
            LookTapGate.MIN_LOOK_TAPS,
            LookTapGate(random = ScriptedRandom(LookTapGate.MIN_LOOK_TAPS)).remainingTaps,
        )
        assertEquals(
            LookTapGate.MAX_LOOK_TAPS,
            LookTapGate(random = ScriptedRandom(LookTapGate.MAX_LOOK_TAPS)).remainingTaps,
        )
    }

    @Test
    fun injectedRequiredTapsUnlocksAtExactlyThatCount() {
        val required = 7
        val gate = LookTapGate(requiredTaps = required)
        assertEquals(required, gate.remainingTaps)
        assertEquals("見る（あと7回）", gate.lookButtonLabel())

        for (tap in 1 until required) {
            assertFalse("tap $tap should not unlock", gate.registerLookTap())
            assertFalse(gate.isUnlocked)
            val remaining = required - tap
            assertEquals(remaining, gate.remainingTaps)
            if (remaining > 1) {
                assertEquals("見る（あと${remaining}回）", gate.lookButtonLabel())
            } else {
                assertEquals("見る", gate.lookButtonLabel())
            }
        }

        assertTrue(gate.registerLookTap())
        assertTrue(gate.isUnlocked)
        assertEquals(0, gate.remainingTaps)
        assertEquals("見る", gate.lookButtonLabel())
    }

    @Test
    fun unlockFiresOnce() {
        val gate = LookTapGate(requiredTaps = 5)
        repeat(4) { assertFalse(gate.registerLookTap()) }

        assertTrue(gate.registerLookTap())
        assertTrue(gate.isUnlocked)
        assertEquals(0, gate.remainingTaps)
        assertEquals("見る", gate.lookButtonLabel())

        assertFalse("further taps must not unlock again", gate.registerLookTap())
        assertFalse(gate.registerLookTap())
    }

    @Test
    fun resetRedrawsRequiredTaps() {
        val gate = LookTapGate(random = ScriptedRandom(6, 11, 5))
        assertEquals(6, gate.remainingTaps)
        assertEquals("見る（あと6回）", gate.lookButtonLabel())

        repeat(2) { gate.registerLookTap() }
        assertEquals(4, gate.remainingTaps)

        gate.reset()
        assertEquals(11, gate.remainingTaps)
        assertFalse(gate.isUnlocked)
        assertEquals("見る（あと11回）", gate.lookButtonLabel())

        gate.reset()
        assertEquals(5, gate.remainingTaps)
        assertFalse(gate.isUnlocked)
        assertEquals("見る（あと5回）", gate.lookButtonLabel())
    }

    @Test
    fun resetAfterUnlockUsesNewlyDrawnCount() {
        val gate = LookTapGate(random = ScriptedRandom(5, 8))
        repeat(4) { gate.registerLookTap() }
        assertTrue(gate.registerLookTap())
        assertFalse(gate.registerLookTap())

        gate.reset()
        assertEquals(8, gate.remainingTaps)
        assertFalse(gate.isUnlocked)
        assertEquals("見る（あと8回）", gate.lookButtonLabel())

        repeat(7) { assertFalse(gate.registerLookTap()) }
        assertTrue(gate.registerLookTap())
        assertFalse(gate.registerLookTap())
    }

    /** Supplies [nextInt] values in order for [Random.nextInt] `(from, until)`. */
    private class ScriptedRandom(private vararg val values: Int) : Random() {
        private var index = 0

        override fun nextBits(bitCount: Int): Int =
            throw UnsupportedOperationException("nextBits")

        override fun nextInt(from: Int, until: Int): Int {
            check(index < values.size) { "no more scripted values" }
            val value = values[index++]
            check(value in from until until) { "scripted $value not in [$from, $until)" }
            return value
        }
    }
}
