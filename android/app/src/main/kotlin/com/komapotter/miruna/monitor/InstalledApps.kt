package com.komapotter.miruna.monitor

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import java.io.ByteArrayOutputStream

object InstalledApps {
    fun list(context: Context): List<Map<String, Any?>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolved = queryLauncherActivities(pm, intent)
        val seen = HashSet<String>()
        val apps = ArrayList<Map<String, Any?>>()
        for (info in resolved) {
            val packageName = info.activityInfo.packageName
            if (!seen.add(packageName)) continue
            if (packageName == context.packageName) continue
            val label = info.loadLabel(pm).toString()
            val icon = runCatching { drawableToPng(info.loadIcon(pm), 96) }.getOrNull()
            apps.add(
                mapOf(
                    "packageName" to packageName,
                    "label" to label,
                    "icon" to icon,
                ),
            )
        }
        apps.sortBy { (it["label"] as String).lowercase() }
        return apps
    }

    private fun queryLauncherActivities(
        pm: PackageManager,
        intent: Intent,
    ): List<ResolveInfo> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, 0)
        }
    }

    private fun drawableToPng(drawable: Drawable, size: Int): ByteArray {
        val bitmap =
            if (drawable is BitmapDrawable && drawable.bitmap != null) {
                Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
            } else {
                val created = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(created)
                drawable.setBounds(0, 0, size, size)
                drawable.draw(canvas)
                created
            }
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 90, out)
        return out.toByteArray()
    }
}
