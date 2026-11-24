package com.sachincharles.native_bridge_kit

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and wires up the platform channels.
 *
 * Extends [FlutterFragmentActivity] (a ComponentActivity) so it can use the
 * modern Activity Result API for the camera permission and the scanner.
 */
class MainActivity : FlutterFragmentActivity() {

    private companion object {
        const val METHOD_CHANNEL = "com.sachincharles.native_bridge/methods"
        const val BATTERY_CHANNEL = "com.sachincharles.native_bridge/battery"
        const val PREFS = "native_bridge"
        const val KEY_ASKED_CAMERA = "asked_camera"
    }

    private lateinit var device: DeviceFeatures

    // Only one permission request / scan can be in flight at a time.
    private var pendingPermission: MethodChannel.Result? = null
    private var pendingScan: MethodChannel.Result? = null

    private val permissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) {
            pendingPermission?.success(cameraPermissionStatus())
            pendingPermission = null
        }

    private val scanLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            val code = result.data?.getStringExtra(QrScannerActivity.EXTRA_RESULT)
            val error = result.data?.getStringExtra(QrScannerActivity.EXTRA_ERROR)
            if (error != null) {
                pendingScan?.error("scanner_error", error, null)
            } else {
                pendingScan?.success(if (result.resultCode == RESULT_OK) code else null)
            }
            pendingScan = null
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        device = DeviceFeatures(applicationContext)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler(::onMethodCall)
        EventChannel(messenger, BATTERY_CHANNEL).setStreamHandler(BatteryStreamHandler(applicationContext))
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceInfo" -> result.success(device.deviceInfo())
            "getBatteryLevel" -> result.success(device.batteryLevel())
            "haptic" -> {
                device.haptic(call.argument<String>("pattern") ?: "light")
                result.success(null)
            }
            "checkCameraPermission" -> result.success(cameraPermissionStatus())
            "requestCameraPermission" -> requestCameraPermission(result)
            "scanQrCode" -> startScan(result)
            "openAppSettings" -> {
                startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (pendingPermission != null) {
            result.error("busy", "A permission request is already running", null)
            return
        }
        if (isCameraGranted()) {
            result.success("granted")
            return
        }
        getSharedPreferences(PREFS, MODE_PRIVATE).edit().putBoolean(KEY_ASKED_CAMERA, true).apply()
        pendingPermission = result
        permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    private fun startScan(result: MethodChannel.Result) {
        if (pendingScan != null) {
            result.error("busy", "The scanner is already open", null)
            return
        }
        if (!isCameraGranted()) {
            result.error("permission_denied", "Camera permission is required to scan", null)
            return
        }
        pendingScan = result
        scanLauncher.launch(Intent(this, QrScannerActivity::class.java))
    }

    private fun isCameraGranted() =
        ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED

    /**
     * Android has no direct "permanently denied" API. If we asked before and
     * the system won't show a rationale any more, the user chose "Don't ask
     * again", so only Settings can grant it.
     */
    private fun cameraPermissionStatus(): String {
        if (isCameraGranted()) return "granted"
        val askedBefore = getSharedPreferences(PREFS, MODE_PRIVATE).getBoolean(KEY_ASKED_CAMERA, false)
        if (!askedBefore) return "notDetermined"
        return if (shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)) "denied" else "permanentlyDenied"
    }
}
