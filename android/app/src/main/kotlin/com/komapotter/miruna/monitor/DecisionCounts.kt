package com.komapotter.miruna.monitor

import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

object DecisionCounts {
    fun localDateKey(nowMs: Long, timeZone: TimeZone = TimeZone.getDefault()): String {
        val calendar = Calendar.getInstance(timeZone)
        calendar.timeInMillis = nowMs
        return String.format(
            Locale.US,
            "%04d-%02d-%02d",
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )
    }

    fun dateInRange(dateKey: String, fromDate: String?, toDate: String?): Boolean {
        if (fromDate != null && dateKey < fromDate) return false
        if (toDate != null && dateKey > toDate) return false
        return true
    }

    fun formatTodayOpenMessage(yesCount: Int): String {
        val count = yesCount.coerceAtLeast(0)
        return "今日は${count}回このアプリを開きました"
    }
}
