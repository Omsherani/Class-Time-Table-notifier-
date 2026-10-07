package com.example.class_alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject
import java.util.Calendar

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val prefs = context.getSharedPreferences("class_alarm_prefs", Context.MODE_PRIVATE)
        val ids = prefs.getStringSet("alarm_ids", emptySet()) ?: emptySet()

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        for (idStr in ids) {
            val jsonStr = prefs.getString("alarm_$idStr", null) ?: continue
            try {
                val json = JSONObject(jsonStr)
                val id = json.getInt("id")
                val courseName = json.getString("courseName")
                val dayOfWeek = json.getInt("dayOfWeek")
                val startTime = json.getString("startTime")
                val room = json.optString("room", "")
                val minutesBefore = json.getInt("minutesBefore")

                // Calculate alarm time
                val parts = startTime.split(":")
                var hour = parts[0].toInt()
                var minute = parts[1].toInt()
                var totalMinutes = hour * 60 + minute - minutesBefore
                var alarmDay = dayOfWeek

                if (totalMinutes < 0) {
                    totalMinutes += 24 * 60
                    alarmDay -= 1
                    if (alarmDay < 1) alarmDay = 7
                }

                val alarmHour = totalMinutes / 60
                val alarmMinute = totalMinutes % 60
                val calendarDay = if (alarmDay == 7) Calendar.SUNDAY else alarmDay + 1

                val calendar = Calendar.getInstance().apply {
                    set(Calendar.DAY_OF_WEEK, calendarDay)
                    set(Calendar.HOUR_OF_DAY, alarmHour)
                    set(Calendar.MINUTE, alarmMinute)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }

                if (calendar.timeInMillis <= System.currentTimeMillis()) {
                    calendar.add(Calendar.WEEK_OF_YEAR, 1)
                }

                val alarmIntent = Intent(context, AlarmReceiver::class.java).apply {
                    putExtra("id", id)
                    putExtra("courseName", courseName)
                    putExtra("room", room)
                    putExtra("minutesBefore", minutesBefore)
                    putExtra("startTime", startTime)
                }

                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    id,
                    alarmIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    AlarmManager.INTERVAL_DAY * 7,
                    pendingIntent
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
