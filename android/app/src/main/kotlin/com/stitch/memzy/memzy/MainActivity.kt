package com.stitch.memzy.memzy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.RingtoneManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.stitch.memzy/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAlarmUri") {
                try {
                    val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    result.success(alarmUri?.toString())
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Alarm URI not available.", e.message)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
