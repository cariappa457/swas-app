package com.example.swsas_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager
import android.os.Build

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.swsas_app/sms"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "swsas_channel_v2",
                "SWSAS Live Monitoring",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "Persistent safety monitoring"
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendDirectSms") {
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")
                if (phoneNumber != null && message != null) {
                    sendSMS(phoneNumber, message)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Phone number or message is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendSMS(phoneNumber: String, message: String) {
        try {
            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                this.getSystemService(SmsManager::class.java)
            } else {
                SmsManager.getDefault()
            }
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
