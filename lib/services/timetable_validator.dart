import '../models/class_schedule.dart';

class TimetableValidator {
  /// Validate a single class schedule entry
  List<String> validateClass(ClassSchedule schedule) {
    List<String> errors = [];

    if (schedule.courseName.trim().isEmpty) {
      errors.add('Course name is required');
    }

    if (schedule.dayOfWeek < 1 || schedule.dayOfWeek > 7) {
      errors.add('Invalid day of week');
    }

    if (!_isValidTime(schedule.startTime)) {
      errors.add('Invalid start time: ${schedule.startTime}');
    }

    if (!_isValidTime(schedule.endTime)) {
      errors.add('Invalid end time: ${schedule.endTime}');
    }

    if (_isValidTime(schedule.startTime) && _isValidTime(schedule.endTime)) {
      if (schedule.startTime.compareTo(schedule.endTime) >= 0) {
        errors.add('Start time must be before end time');
      }
    }

    if (schedule.alarmMinutesBefore < 0) {
      errors.add('Alarm minutes must be positive');
    }

    return errors;
  }

  /// Find duplicate classes (same course, day, and start time)
  List<List<ClassSchedule>> findDuplicates(List<ClassSchedule> classes) {
    List<List<ClassSchedule>> duplicateGroups = [];
    Map<String, List<ClassSchedule>> groups = {};

    for (var c in classes) {
      String key = '${c.courseName.toLowerCase().trim()}_${c.dayOfWeek}_${c.startTime}';
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(c);
    }

    for (var entry in groups.entries) {
      if (entry.value.length > 1) {
        duplicateGroups.add(entry.value);
      }
    }

    return duplicateGroups;
  }

  /// Remove duplicate classes, keeping the first occurrence
  List<ClassSchedule> removeDuplicates(List<ClassSchedule> classes) {
    Set<String> seen = {};
    List<ClassSchedule> unique = [];

    for (var c in classes) {
      String key = '${c.courseName.toLowerCase().trim()}_${c.dayOfWeek}_${c.startTime}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(c);
      }
    }

    return unique;
  }

  bool _isValidTime(String time) {
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }
}
