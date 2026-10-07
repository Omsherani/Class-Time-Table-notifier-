package com.example.class_alarm

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.classalarm/alarms"
    private val PREFS_NAME = "class_alarm_prefs"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermissions" -> {
                        requestAlarmPermissions()
                        result.success(true)
                    }
                    "scheduleAlarm" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val courseName = call.argument<String>("courseName") ?: ""
                        val dayOfWeek = call.argument<Int>("dayOfWeek") ?: 1
                        val startTime = call.argument<String>("startTime") ?: "08:00"
                        val room = call.argument<String>("room") ?: ""
                        val minutesBefore = call.argument<Int>("alarmMinutesBefore") ?: 15

                        scheduleWeeklyAlarm(id, courseName, dayOfWeek, startTime, room, minutesBefore)
                        result.success(true)
                    }
                    "cancelAlarm" -> {
                        val id = call.argument<Int>("id") ?: 0
                        cancelAlarm(id)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "class_alarm_channel",
                "Class Alarms",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alarms for upcoming classes"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun requestAlarmPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (!alarmManager.canScheduleExactAlarms()) {
                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                startActivity(intent)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
    }

    private fun scheduleWeeklyAlarm(
        id: Int,
        courseName: String,
        dayOfWeek: Int,
        startTime: String,
        room: String,
        minutesBefore: Int
    ) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // Parse start time and subtract minutes
        val parts = startTime.split(":")
        var hour = parts[0].toInt()
        var minute = parts[1].toInt()

        // Subtract minutesBefore
        var totalMinutes = hour * 60 + minute - minutesBefore
        var alarmDayOfWeek = dayOfWeek

        if (totalMinutes < 0) {
            totalMinutes += 24 * 60
            alarmDayOfWeek -= 1
            if (alarmDayOfWeek < 1) alarmDayOfWeek = 7
        }

        val alarmHour = totalMinutes / 60
        val alarmMinute = totalMinutes % 60

        // Convert our dayOfWeek (1=Mon, 7=Sun) to Calendar (2=Mon, 1=Sun)
        val calendarDay = if (alarmDayOfWeek == 7) Calendar.SUNDAY else alarmDayOfWeek + 1

        val calendar = Calendar.getInstance().apply {
            set(Calendar.DAY_OF_WEEK, calendarDay)
            set(Calendar.HOUR_OF_DAY, alarmHour)
            set(Calendar.MINUTE, alarmMinute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        // If time is in the past, move to next week
        if (calendar.timeInMillis <= System.currentTimeMillis()) {
            calendar.add(Calendar.WEEK_OF_YEAR, 1)
        }

        val intent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("courseName", courseName)
            putExtra("room", room)
            putExtra("minutesBefore", minutesBefore)
            putExtra("startTime", startTime)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Schedule repeating weekly alarm
        alarmManager.setRepeating(
            AlarmManager.RTC_WAKEUP,
            calendar.timeInMillis,
            AlarmManager.INTERVAL_DAY * 7,
            pendingIntent
        )

        // Save alarm data to SharedPreferences for boot receiver
        saveAlarmData(id, courseName, dayOfWeek, startTime, room, minutesBefore)
    }

    private fun cancelAlarm(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        pendingIntent?.let {
            alarmManager.cancel(it)
            it.cancel()
        }
        removeAlarmData(id)
    }

    private fun saveAlarmData(id: Int, courseName: String, dayOfWeek: Int, startTime: String, room: String, minutesBefore: Int) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = JSONObject().apply {
            put("id", id)
            put("courseName", courseName)
            put("dayOfWeek", dayOfWeek)
            put("startTime", startTime)
            put("room", room)
            put("minutesBefore", minutesBefore)
        }
        prefs.edit().putString("alarm_$id", json.toString()).apply()

        // Update alarm IDs list
        val ids = prefs.getStringSet("alarm_ids", mutableSetOf()) ?: mutableSetOf()
        val newIds = ids.toMutableSet()
        newIds.add(id.toString())
        prefs.edit().putStringSet("alarm_ids", newIds).apply()
    }

    private fun removeAlarmData(id: Int) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove("alarm_$id").apply()

        val ids = prefs.getStringSet("alarm_ids", mutableSetOf()) ?: mutableSetOf()
        val newIds = ids.toMutableSet()
        newIds.remove(id.toString())
        prefs.edit().putStringSet("alarm_ids", newIds).apply()
    }
}
