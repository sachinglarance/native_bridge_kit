package com.sachincharles.native_bridge_kit

import android.content.Context
import android.os.BatteryManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/** Stateless helpers behind the method channel. */
class DeviceFeatures(private val context: Context) {

    fun deviceInfo(): Map<String, Any> = mapOf(
        "platform" to "android",
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
        "osVersion" to Build.VERSION.RELEASE,
        "sdkInt" to Build.VERSION.SDK_INT,
        "isPhysicalDevice" to !isEmulator(),
    )

    fun batteryLevel(): Int {
        val manager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    fun haptic(pattern: String) {
        val vibrator = vibrator() ?: return
        if (!vibrator.hasVibrator()) return
        val effect = when (pattern) {
            "light" -> VibrationEffect.createOneShot(20, 80)
            "medium" -> VibrationEffect.createOneShot(40, 160)
            "heavy" -> VibrationEffect.createOneShot(60, 255)
            "success" -> VibrationEffect.createWaveform(longArrayOf(0, 30, 60, 30), intArrayOf(0, 180, 0, 255), -1)
            "error" -> VibrationEffect.createWaveform(longArrayOf(0, 80, 50, 80, 50, 80), -1)
            else -> VibrationEffect.createOneShot(20, VibrationEffect.DEFAULT_AMPLITUDE)
        }
        vibrator.vibrate(effect)
    }

    private fun vibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    private fun isEmulator(): Boolean =
        Build.FINGERPRINT.startsWith("generic") ||
            Build.FINGERPRINT.contains("emulator") ||
            Build.MODEL.contains("sdk_gphone") ||
            Build.MODEL.contains("Emulator") ||
            Build.HARDWARE.contains("ranchu") ||
            Build.PRODUCT.contains("sdk")
}
