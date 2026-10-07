import '../models/class_schedule.dart';

class TimetableSortService {
  /// Sort classes by dayOfWeek (1=Monday to 7=Sunday) then by startTime
  List<ClassSchedule> sortClasses(List<ClassSchedule> classes) {
    final sorted = List<ClassSchedule>.from(classes);
    sorted.sort((a, b) {
      int dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayCompare != 0) return dayCompare;
      return a.startTime.compareTo(b.startTime);
    });
    return sorted;
  }

  /// Get classes for a specific day
  List<ClassSchedule> getClassesForDay(List<ClassSchedule> classes, int day) {
    return classes.where((c) => c.dayOfWeek == day).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get the next upcoming class based on current day/time
  ClassSchedule? getNextClass(List<ClassSchedule> classes) {
    if (classes.isEmpty) return null;

    final now = DateTime.now();
    // DateTime weekday: 1=Monday, 7=Sunday (matches our model)
    final currentDay = now.weekday;
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final sorted = sortClasses(classes);

    // First, find a class later today
    for (var c in sorted) {
      if (c.dayOfWeek == currentDay && c.startTime.compareTo(currentTime) > 0) {
        return c;
      }
    }

    // Then find the first class on a later day this week
    for (var c in sorted) {
      if (c.dayOfWeek > currentDay) {
        return c;
      }
    }

    // Otherwise wrap around to the first class next week
    return sorted.isNotEmpty ? sorted.first : null;
  }

  /// Calculate alarm time by subtracting minutes from start time.
  /// Handles day boundary correctly (e.g., 00:05 - 15 = 23:50).
  /// Returns a map with 'time' (HH:mm) and 'dayOffset' (-1 if previous day, 0 if same day).
  Map<String, dynamic> calculateAlarmTimeWithDayOffset(String startTime, int minutesBefore) {
    final parts = startTime.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    int totalMinutes = hour * 60 + minute - minutesBefore;
    int dayOffset = 0;

    if (totalMinutes < 0) {
      totalMinutes += 24 * 60; // Wrap to previous day
      dayOffset = -1;
    }

    int alarmHour = totalMinutes ~/ 60;
    int alarmMinute = totalMinutes % 60;

    return {
      'time': '${alarmHour.toString().padLeft(2, '0')}:${alarmMinute.toString().padLeft(2, '0')}',
      'dayOffset': dayOffset,
    };
  }

  /// Simple version that returns just the time string
  String calculateAlarmTime(String startTime, int minutesBefore) {
    return calculateAlarmTimeWithDayOffset(startTime, minutesBefore)['time'] as String;
  }

  /// Get the day name from day number
  static String getDayName(int dayOfWeek) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek - 1];
    }
    return 'Unknown';
  }

  /// Get short day name
  static String getDayShortName(int dayOfWeek) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek - 1];
    }
    return '???';
  }
}
