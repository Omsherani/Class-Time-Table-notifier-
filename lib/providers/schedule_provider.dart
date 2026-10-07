import 'package:flutter/foundation.dart';
import '../models/class_schedule.dart';
import '../models/schedule.dart';
import '../repositories/schedule_repository.dart';
import '../services/alarm_service.dart';
import '../services/timetable_sort_service.dart';
import '../services/timetable_validator.dart';
import '../core/constants.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _repository = ScheduleRepository();
  final AlarmService _alarmService = AlarmService();
  final TimetableSortService _sortService = TimetableSortService();
  final TimetableValidator _validator = TimetableValidator();

  Schedule? _activeSchedule;
  List<Schedule> _allSchedules = [];
  List<ClassSchedule> _classSchedules = [];
  int _defaultReminderMinutes = AppConstants.defaultReminderMinutes;
  bool _isLoading = false;

  Schedule? get activeSchedule => _activeSchedule;
  List<Schedule> get allSchedules => _allSchedules;
  List<ClassSchedule> get classSchedules => _sortService.sortClasses(_classSchedules);
  int get defaultReminderMinutes => _defaultReminderMinutes;
  bool get isLoading => _isLoading;

  ClassSchedule? get nextClass => _sortService.getNextClass(_classSchedules);

  List<ClassSchedule> getClassesForDay(int day) {
    return _sortService.getClassesForDay(_classSchedules, day);
  }

  List<ClassSchedule> get todayClasses {
    return getClassesForDay(DateTime.now().weekday);
  }

  String calculateAlarmTime(String startTime, int minutesBefore) {
    return _sortService.calculateAlarmTime(startTime, minutesBefore);
  }

  Future<void> loadSchedules() async {
    _isLoading = true;
    notifyListeners();

    _allSchedules = await _repository.getAllSchedules();
    _activeSchedule = await _repository.getActiveSchedule();

    if (_activeSchedule != null) {
      await loadClassSchedules(_activeSchedule!.id!);
    } else {
      _classSchedules = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadClassSchedules(int scheduleId) async {
    _classSchedules = await _repository.getClassSchedulesForSchedule(scheduleId);
    notifyListeners();
  }

  Future<void> createSchedule(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final schedule = Schedule(
      name: name,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    _activeSchedule = await _repository.createSchedule(schedule);
    await loadSchedules();
  }

  Future<void> switchSchedule(int id) async {
    // Cancel existing alarms
    for (var c in _classSchedules) {
      if (c.id != null) {
        await _alarmService.cancelAlarm(c.id!);
      }
    }

    // Activate new schedule
    final schedules = await _repository.getAllSchedules();
    for (var s in schedules) {
      await _repository.updateSchedule(s.copyWith(isActive: s.id == id));
    }

    await loadSchedules();

    // Schedule alarms for new active schedule
    for (var c in _classSchedules) {
      if (c.alarmEnabled) {
        await _alarmService.scheduleAlarm(c);
      }
    }
  }

  Future<void> deleteSchedule(int id) async {
    // Cancel alarms if deleting the active schedule
    if (_activeSchedule?.id == id) {
      for (var c in _classSchedules) {
        if (c.id != null) await _alarmService.cancelAlarm(c.id!);
      }
    }
    await _repository.deleteSchedule(id);
    await loadSchedules();
  }

  Future<void> addClass(ClassSchedule classSchedule) async {
    if (_activeSchedule == null) {
      await createSchedule('My Timetable');
    }

    final cs = classSchedule.copyWith(
      scheduleId: _activeSchedule!.id!,
      alarmMinutesBefore: classSchedule.alarmMinutesBefore > 0
          ? classSchedule.alarmMinutesBefore
          : _defaultReminderMinutes,
    );

    final saved = await _repository.createClassSchedule(cs);
    if (saved.alarmEnabled) {
      await _alarmService.scheduleAlarm(saved);
    }
    await loadClassSchedules(_activeSchedule!.id!);
  }

  Future<void> addAllClasses(List<ClassSchedule> classes) async {
    if (_activeSchedule == null) {
      await createSchedule('My Timetable');
    }

    // Validate and deduplicate
    final validated = _validator.removeDuplicates(classes);

    for (var c in validated) {
      final cs = c.copyWith(
        scheduleId: _activeSchedule!.id!,
        alarmMinutesBefore: c.alarmMinutesBefore > 0
            ? c.alarmMinutesBefore
            : _defaultReminderMinutes,
      );
      final saved = await _repository.createClassSchedule(cs);
      if (saved.alarmEnabled) {
        await _alarmService.scheduleAlarm(saved);
      }
    }

    await loadClassSchedules(_activeSchedule!.id!);
  }

  Future<void> updateClass(ClassSchedule classSchedule) async {
    await _repository.updateClassSchedule(classSchedule);
    if (classSchedule.id != null) {
      await _alarmService.cancelAlarm(classSchedule.id!);
      if (classSchedule.alarmEnabled) {
        await _alarmService.scheduleAlarm(classSchedule);
      }
    }
    if (_activeSchedule != null) {
      await loadClassSchedules(_activeSchedule!.id!);
    }
  }

  Future<void> deleteClass(int id) async {
    await _alarmService.cancelAlarm(id);
    await _repository.deleteClassSchedule(id);
    if (_activeSchedule != null) {
      await loadClassSchedules(_activeSchedule!.id!);
    }
  }

  Future<void> toggleAlarm(int id) async {
    final classSchedule = _classSchedules.firstWhere((c) => c.id == id);
    final updated = classSchedule.copyWith(alarmEnabled: !classSchedule.alarmEnabled);
    await updateClass(updated);
  }

  void setDefaultReminder(int minutes) {
    _defaultReminderMinutes = minutes;
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    await _alarmService.requestPermissions();
  }

  Future<void> deleteAllData() async {
    for (var c in _classSchedules) {
      if (c.id != null) await _alarmService.cancelAlarm(c.id!);
    }
    for (var s in _allSchedules) {
      if (s.id != null) await _repository.deleteSchedule(s.id!);
    }
    _classSchedules = [];
    _allSchedules = [];
    _activeSchedule = null;
    notifyListeners();
  }
}
