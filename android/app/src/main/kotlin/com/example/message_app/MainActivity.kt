package com.example.message_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.oceanami.message_app/app_state"
    private var appState = "resumed"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 🔥 Setup MethodChannel để Flutter check app state
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppState" -> {
                    result.success(appState)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // 🔥 Tạo notification channel với Bubbles support
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannels()
        }
    }

    override fun onResume() {
        super.onResume()
        appState = "resumed"
    }

    override fun onPause() {
        super.onPause()
        appState = "paused"
    }

    override fun onStop() {
        super.onStop()
        appState = "stopped"
    }

    // 🔥 Tạo notification channels với Bubbles
    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannels() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Channel cho messages với Bubbles
        val messageChannel = NotificationChannel(
            "messages_channel",
            "Messages",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "New message notifications with chat bubbles"
            enableVibration(true)
            enableLights(true)
            setShowBadge(true)
            
            // 🔥 Bật Bubbles cho channel này (Android 11+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                setAllowBubbles(true)
            }
        }
        
        notificationManager.createNotificationChannel(messageChannel)
    }
}
