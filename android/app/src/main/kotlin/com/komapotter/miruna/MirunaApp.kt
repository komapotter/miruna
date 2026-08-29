package com.komapotter.miruna

import android.app.Application
import com.komapotter.miruna.monitor.MonitorEngine
import com.komapotter.miruna.monitor.MonitorService
import com.komapotter.miruna.monitor.MonitorStore

class MirunaApp : Application() {
    override fun onCreate() {
        super.onCreate()
        MonitorEngine.init(this)
        if (MonitorStore(this).isMonitoringEnabled()) {
            MonitorService.start(this)
        }
    }
}
