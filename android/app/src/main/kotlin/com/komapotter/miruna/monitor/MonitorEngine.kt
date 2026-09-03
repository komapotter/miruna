package com.komapotter.miruna.monitor

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper

class MonitorEngine private constructor(context: Context) {
    private val appContext = context.applicationContext
    private val store = MonitorStore(appContext)
    private val overlay = WarningOverlay(appContext)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pendingCloses = HashMap<String, Runnable>()
    private val unconfirmedWarnings = HashSet<String>()
    private var currentPackage: String? = null
    var accessibilityActive: Boolean = false

    @Synchronized
    fun onPackageForeground(packageName: String) {
        if (!store.isMonitoringEnabled()) return
        if (shouldIgnore(packageName)) return
        val previous = currentPackage
        if (packageName == previous) return
        currentPackage = packageName

        if (previous != null) {
            scheduleClose(previous)
        }
        cancelClose(packageName)

        val app = store.getApp(packageName) ?: return
        val action =
            Cooldown.decide(
                watched = true,
                enabled = app.enabled,
                sessionAllowed = app.sessionAllowed,
                lastClosedAtMs = app.lastClosedAtMs,
                warningPeriodMs = app.warningPeriodMs,
                nowMs = System.currentTimeMillis(),
            )
        if (action == Cooldown.ACTION_WARN) {
            unconfirmedWarnings.add(packageName)
            mainHandler.post {
                overlay.show(
                    packageName = packageName,
                    appName = app.displayName,
                    warningPeriodMs = app.warningPeriodMs,
                    onYes = { confirmOpen(packageName) },
                    onNo = { declineOpen() },
                )
            }
        } else {
            mainHandler.post { overlay.dismiss() }
        }
    }

    fun hideOverlay() {
        mainHandler.post { overlay.dismiss() }
    }

    private fun confirmOpen(packageName: String) {
        unconfirmedWarnings.remove(packageName)
        store.setSessionAllowed(packageName, true)
        overlay.dismiss()
    }

    private fun declineOpen() {
        overlay.dismiss()
        val home =
            Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
        appContext.startActivity(home)
    }

    private fun scheduleClose(packageName: String) {
        if (store.getApp(packageName) == null) return
        cancelClose(packageName)
        val task = Runnable {
            synchronized(this) {
                pendingCloses.remove(packageName)
                if (currentPackage == packageName) return@Runnable
                val unconfirmed = unconfirmedWarnings.remove(packageName)
                if (Cooldown.shouldRecordClose(unconfirmedWarning = unconfirmed)) {
                    store.recordClose(packageName, System.currentTimeMillis())
                }
                if (overlay.currentPackage == packageName) {
                    overlay.dismiss()
                }
            }
        }
        pendingCloses[packageName] = task
        mainHandler.postDelayed(task, Cooldown.CLOSE_GRACE_MS)
    }

    private fun cancelClose(packageName: String) {
        pendingCloses.remove(packageName)?.let { mainHandler.removeCallbacks(it) }
    }

    private fun shouldIgnore(packageName: String): Boolean {
        if (packageName == appContext.packageName) return true
        if (packageName == "com.android.systemui") return true
        if (packageName.contains("permissioncontroller")) return true
        if (packageName.contains("inputmethod")) return true
        if (packageName == "android") return true
        return false
    }

    companion object {
        @Volatile private var instance: MonitorEngine? = null

        fun init(context: Context): MonitorEngine {
            return instance ?: synchronized(this) {
                instance ?: MonitorEngine(context).also { instance = it }
            }
        }

        fun get(): MonitorEngine? = instance
    }
}
