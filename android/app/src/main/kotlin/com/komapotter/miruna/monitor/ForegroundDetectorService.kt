package com.komapotter.miruna.monitor

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class ForegroundDetectorService : AccessibilityService() {
    override fun onServiceConnected() {
        super.onServiceConnected()
        MonitorEngine.init(this).accessibilityActive = true
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        MonitorEngine.get()?.onPackageForeground(pkg)
    }

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        MonitorEngine.get()?.accessibilityActive = false
        super.onDestroy()
    }
}
