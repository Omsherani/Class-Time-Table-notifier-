import 'package:flutter/services.dart';
import '../models/class_schedule.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.classalarm/alarms');

  Future<void> requestPermissions() async {
    try {
      await _channel.invokeMethod('requestPermissions');
    } on PlatformException catch (e) {
      print("Failed to request permissions: '${e.message}'.");
    }
  }

  Future<void> scheduleAlarm(ClassSchedule schedule) async {
    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'id': schedule.id,
        'courseName': schedule.courseName,
        'dayOfWeek': schedule.dayOfWeek,
        'startTime': schedule.startTime,
        'room': schedule.room,
        'alarmMinutesBefore': schedule.alarmMinutesBefore,
      });
    } on PlatformException catch (e) {
      print("Failed to schedule alarm: '${e.message}'.");
    }
  }

  Future<void> cancelAlarm(int id) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'id': id});
    } on PlatformException catch (e) {
      print("Failed to cancel alarm: '${e.message}'.");
    }
  }
}
