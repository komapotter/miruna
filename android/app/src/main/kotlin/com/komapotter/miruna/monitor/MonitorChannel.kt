package com.komapotter.miruna.monitor

import android.Manifest
import android.app.Activity
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MonitorChannel(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler {
    private val store = MonitorStore(activity)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getPermissionStatus" -> result.success(PermissionHelper.status(activity))
                "openSettings" -> {
                    val type = call.argument<String>("type") ?: ""
                    val intent = PermissionHelper.settingsIntent(activity, type)
                    if (intent == null) {
                        result.error("unknown_type", type, null)
                    } else {
                        activity.startActivity(intent)
                        result.success(null)
                    }
                }
                "requestNotifications" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ActivityCompat.requestPermissions(
                            activity,
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            1001,
                        )
                    }
                    result.success(null)
                }
                "listInstalledApps" -> {
                    thread {
                        try {
                            val apps = InstalledApps.list(activity)
                            mainHandler.post {
                                try {
                                    result.success(apps)
                                } catch (_: Exception) {
                                    // Channel already closed.
                                }
                            }
                        } catch (error: Exception) {
                            mainHandler.post {
                                try {
                                    result.error("monitor_error", error.message, null)
                                } catch (_: Exception) {
                                    // Channel already closed.
                                }
                            }
                        }
                    }
                }
                "getWatchedApps" -> result.success(store.getApps().map { it.toMap() })
                "upsertWatchedApp" -> {
                    store.upsertConfig(
                        packageName = call.argument<String>("packageName")!!,
                        displayName = call.argument<String>("displayName")!!,
                        warningPeriodMs =
                            (call.argument<Number>("warningPeriodMs") ?: Cooldown.DEFAULT_PERIOD_MS)
                                .toLong(),
                        enabled = call.argument<Boolean>("enabled") ?: true,
                    )
                    result.success(null)
                }
                "removeWatchedApp" -> {
                    store.remove(call.argument<String>("packageName")!!)
                    result.success(null)
                }
                "getDefaultWarningPeriodMs" ->
                    result.success(store.getDefaultWarningPeriodMs())
                "setDefaultWarningPeriodMs" -> {
                    store.setDefaultWarningPeriodMs(
                        (call.argument<Number>("ms") ?: Cooldown.DEFAULT_PERIOD_MS).toLong(),
                    )
                    result.success(null)
                }
                "isMonitoring" -> result.success(store.isMonitoringEnabled())
                "setMonitoring" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    store.setMonitoringEnabled(enabled)
                    if (enabled) {
                        MonitorEngine.init(activity)
                        MonitorService.start(activity)
                    } else {
                        MonitorService.stop(activity)
                        MonitorEngine.get()?.hideOverlay()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error("monitor_error", error.message, null)
        }
    }

    companion object {
        const val CHANNEL = "com.komapotter.miruna/monitor"

        fun register(messenger: BinaryMessenger, activity: Activity) {
            MethodChannel(messenger, CHANNEL).setMethodCallHandler(MonitorChannel(activity))
        }
    }
}

private fun WatchedAppEntity.toMap(): Map<String, Any?> =
    mapOf(
        "packageName" to packageName,
        "displayName" to displayName,
        "warningPeriodMs" to warningPeriodMs,
        "enabled" to enabled,
        "lastClosedAtMs" to lastClosedAtMs,
        "sessionAllowed" to sessionAllowed,
    )
