package com.sachincharles.native_bridge_kit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.plugin.common.EventChannel

/**
 * Pushes battery level and charging state to Dart. The receiver is only
 * registered while Dart is listening, so nothing runs in the background.
 */
class BatteryStreamHandler(private val context: Context) : EventChannel.StreamHandler {

    private var receiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                events.success(parse(intent))
            }
        }
        // ACTION_BATTERY_CHANGED is sticky: registering returns the current
        // value immediately, and it's a protected system broadcast so no
        // exported flag is needed.
        context.registerReceiver(receiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    }

    override fun onCancel(arguments: Any?) {
        receiver?.let(context::unregisterReceiver)
        receiver = null
    }

    private fun parse(intent: Intent): Map<String, Any> {
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val state = when (intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
            BatteryManager.BATTERY_STATUS_FULL -> "full"
            BatteryManager.BATTERY_STATUS_DISCHARGING,
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "discharging"
            else -> "unknown"
        }
        val percent = if (level >= 0 && scale > 0) level * 100 / scale else -1
        return mapOf("level" to percent, "state" to state)
    }
}
