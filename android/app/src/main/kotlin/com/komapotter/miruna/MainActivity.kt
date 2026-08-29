package com.komapotter.miruna

import com.komapotter.miruna.monitor.MonitorChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MonitorChannel.register(flutterEngine.dartExecutor.binaryMessenger, this)
    }
}
