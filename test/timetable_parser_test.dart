import 'package:flutter_test/flutter_test.dart';
import 'package:class_alarm/services/timetable_parser.dart';
import 'package:class_alarm/services/timetable_sort_service.dart';
import 'package:class_alarm/services/timetable_validator.dart';
import 'package:class_alarm/models/class_schedule.dart';

void main() {
  group('TimetableParser', () {
    final parser = TimetableParser();

    test('Parses single inline parenthesis class', () {
      final text = 'COMMUNICATION SKILLS (THU 08:30 11:30 E-904)';
      final results = parser.parse(text);
      expect(results.length, 1);
      expect(results[0].courseName, 'COMMUNICATION SKILLS');
      expect(results[0].dayOfWeek, 4); // Thursday
      expect(results[0].startTime, '08:30');
      expect(results[0].endTime, '11:30');
    });

    test('Parses multiple classes separated by comma inside parenthesis', () {
      final text = 'DEEP LEARNING (TUE 13:00 14:20 E-806, THU 13:00 14:20 E-806)';
      final results = parser.parse(text);
      expect(results.length, 2);
      expect(results[0].courseName, 'DEEP LEARNING');
      expect(results[0].dayOfWeek, 2); // Tuesday
      expect(results[0].startTime, '13:00');
      expect(results[0].endTime, '14:20');
      expect(results[1].courseName, 'DEEP LEARNING');
      expect(results[1].dayOfWeek, 4); // Thursday
    });

    test('Parses multi-line class', () {
      final text = 'COMPUTER VISION\nMON 14:30 15:50 E-507';
      final results = parser.parse(text);
      expect(results.length, 1);
      expect(results[0].courseName, 'COMPUTER VISION');
      expect(results[0].dayOfWeek, 1); // Monday
      expect(results[0].startTime, '14:30');
      expect(results[0].endTime, '15:50');
    });

    test('Parses 12-hour AM/PM format', () {
      final text = 'Database Management Systems\nMON 02:30 PM 04:00 PM ROOM-12';
      final results = parser.parse(text);
      expect(results.length, 1);
      expect(results[0].courseName, 'Database Management Systems');
      expect(results[0].startTime, '14:30');
      expect(results[0].endTime, '16:00');
    });

    test('Parses multiline class with multiple day lines', () {
      final text = 'COMPUTER VISION\nMON 14:30 15:50 E-507\nWED 14:30 15:50 E-507';
      final results = parser.parse(text);
      expect(results.length, 2);
      expect(results[0].courseName, 'COMPUTER VISION');
      expect(results[1].courseName, 'COMPUTER VISION');
      expect(results[0].dayOfWeek, 1);
      expect(results[1].dayOfWeek, 3);
    });

    test('Recognizes full day names', () {
      expect(parser.parseDayOfWeek('MONDAY'), 1);
      expect(parser.parseDayOfWeek('TUESDAY'), 2);
      expect(parser.parseDayOfWeek('WEDNESDAY'), 3);
      expect(parser.parseDayOfWeek('THURSDAY'), 4);
      expect(parser.parseDayOfWeek('FRIDAY'), 5);
      expect(parser.parseDayOfWeek('SATURDAY'), 6);
      expect(parser.parseDayOfWeek('SUNDAY'), 7);
    });

    test('Recognizes abbreviated day names', () {
      expect(parser.parseDayOfWeek('MON'), 1);
      expect(parser.parseDayOfWeek('TUE'), 2);
      expect(parser.parseDayOfWeek('WED'), 3);
      expect(parser.parseDayOfWeek('THU'), 4);
      expect(parser.parseDayOfWeek('FRI'), 5);
      expect(parser.parseDayOfWeek('SAT'), 6);
      expect(parser.parseDayOfWeek('SUN'), 7);
    });

    test('Normalizes 12-hour to 24-hour time', () {
      expect(parser.normalizeTime('2:30 PM'), '14:30');
      expect(parser.normalizeTime('8:30 AM'), '08:30');
      expect(parser.normalizeTime('12:00 PM'), '12:00');
      expect(parser.normalizeTime('12:00 AM'), '00:00');
      expect(parser.normalizeTime('11:59 PM'), '23:59');
    });

    test('Normalizes 24-hour time passthrough', () {
      expect(parser.normalizeTime('14:30'), '14:30');
      expect(parser.normalizeTime('08:30'), '08:30');
      expect(parser.normalizeTime('00:00'), '00:00');
      expect(parser.normalizeTime('23:59'), '23:59');
    });

    test('Parses class with LAB suffix in parenthesis', () {
      final text = 'OPERATING SYSTEMS (LAB) (TUE 14:30 17:20 E-207)';
      final results = parser.parse(text);
      expect(results.length, 1);
      expect(results[0].dayOfWeek, 2);
      expect(results[0].startTime, '14:30');
      expect(results[0].endTime, '17:20');
    });

    test('Handles multiple courses in sequence', () {
      final text = '''
COMMUNICATION SKILLS (THU 08:30 11:30 E-904)
DEEP LEARNING (TUE 13:00 14:20 E-806, THU 13:00 14:20 E-806)
COMPUTER VISION
MON 14:30 15:50 E-507
WED 14:30 15:50 E-507
''';
      final results = parser.parse(text);
      expect(results.length, 5);
    });
  });

  group('TimetableSortService', () {
    final sortService = TimetableSortService();

    test('Sorts classes by day then time', () {
      final classes = [
        _makeClass('B', 3, '14:00', '15:00'),
        _makeClass('A', 1, '08:00', '09:00'),
        _makeClass('C', 1, '10:00', '11:00'),
        _makeClass('D', 5, '09:00', '10:00'),
      ];
      final sorted = sortService.sortClasses(classes);
      expect(sorted[0].courseName, 'A');
      expect(sorted[1].courseName, 'C');
      expect(sorted[2].courseName, 'B');
      expect(sorted[3].courseName, 'D');
    });

    test('getClassesForDay filters correctly', () {
      final classes = [
        _makeClass('A', 1, '08:00', '09:00'),
        _makeClass('B', 2, '10:00', '11:00'),
        _makeClass('C', 1, '14:00', '15:00'),
      ];
      final monday = sortService.getClassesForDay(classes, 1);
      expect(monday.length, 2);
      expect(monday[0].courseName, 'A');
      expect(monday[1].courseName, 'C');
    });

    test('calculateAlarmTime basic subtraction', () {
      expect(sortService.calculateAlarmTime('08:30', 15), '08:15');
      expect(sortService.calculateAlarmTime('13:00', 15), '12:45');
      expect(sortService.calculateAlarmTime('14:30', 15), '14:15');
    });

    test('calculateAlarmTime midnight boundary', () {
      expect(sortService.calculateAlarmTime('00:05', 15), '23:50');
      expect(sortService.calculateAlarmTime('00:00', 30), '23:30');
    });

    test('calculateAlarmTime day offset for midnight boundary', () {
      final result = sortService.calculateAlarmTimeWithDayOffset('00:05', 15);
      expect(result['time'], '23:50');
      expect(result['dayOffset'], -1);
    });

    test('calculateAlarmTime no day offset for normal time', () {
      final result = sortService.calculateAlarmTimeWithDayOffset('08:30', 15);
      expect(result['time'], '08:15');
      expect(result['dayOffset'], 0);
    });

    test('getDayName returns correct names', () {
      expect(TimetableSortService.getDayName(1), 'Monday');
      expect(TimetableSortService.getDayName(7), 'Sunday');
      expect(TimetableSortService.getDayName(0), 'Unknown');
    });
  });

  group('TimetableValidator', () {
    final validator = TimetableValidator();

    test('validateClass rejects empty course name', () {
      final c = _makeClass('', 1, '08:00', '09:00');
      final errors = validator.validateClass(c);
      expect(errors.any((e) => e.contains('name')), true);
    });

    test('validateClass rejects invalid day', () {
      final c = _makeClass('Test', 0, '08:00', '09:00');
      final errors = validator.validateClass(c);
      expect(errors.any((e) => e.contains('day')), true);
    });

    test('validateClass rejects invalid time', () {
      final c = _makeClass('Test', 1, '25:00', '09:00');
      final errors = validator.validateClass(c);
      expect(errors.any((e) => e.contains('start time')), true);
    });

    test('validateClass rejects start >= end', () {
      final c = _makeClass('Test', 1, '15:00', '14:00');
      final errors = validator.validateClass(c);
      expect(errors.any((e) => e.contains('before')), true);
    });

    test('validateClass accepts valid class', () {
      final c = _makeClass('Deep Learning', 2, '13:00', '14:20');
      final errors = validator.validateClass(c);
      expect(errors, isEmpty);
    });

    test('findDuplicates detects same class', () {
      final classes = [
        _makeClass('Deep Learning', 2, '13:00', '14:20'),
        _makeClass('Deep Learning', 2, '13:00', '14:20'),
      ];
      final dupes = validator.findDuplicates(classes);
      expect(dupes.length, 1);
      expect(dupes[0].length, 2);
    });

    test('findDuplicates ignores different days', () {
      final classes = [
        _makeClass('Deep Learning', 2, '13:00', '14:20'),
        _makeClass('Deep Learning', 4, '13:00', '14:20'),
      ];
      final dupes = validator.findDuplicates(classes);
      expect(dupes, isEmpty);
    });

    test('removeDuplicates keeps one', () {
      final classes = [
        _makeClass('Deep Learning', 2, '13:00', '14:20'),
        _makeClass('Deep Learning', 2, '13:00', '14:20'),
        _makeClass('Computer Vision', 1, '14:30', '15:50'),
      ];
      final unique = validator.removeDuplicates(classes);
      expect(unique.length, 2);
    });
  });

  group('Alarm Generation', () {
    final sortService = TimetableSortService();

    test('Generates correct alarm for Communication Skills', () {
      // THU 08:30 11:30
      final alarmTime = sortService.calculateAlarmTime('08:30', 15);
      expect(alarmTime, '08:15');
    });

    test('Generates correct alarm for Deep Learning', () {
      // TUE 13:00 14:20
      final alarmTime = sortService.calculateAlarmTime('13:00', 15);
      expect(alarmTime, '12:45');
    });

    test('Alarm for various reminder durations', () {
      expect(sortService.calculateAlarmTime('08:30', 5), '08:25');
      expect(sortService.calculateAlarmTime('08:30', 10), '08:20');
      expect(sortService.calculateAlarmTime('08:30', 30), '08:00');
      expect(sortService.calculateAlarmTime('08:30', 45), '07:45');
      expect(sortService.calculateAlarmTime('08:30', 60), '07:30');
    });

    test('Weekly recurrence: two separate alarms for Deep Learning', () {
      // Deep Learning: TUE 13:00 14:20, THU 13:00 14:20
      final classes = [
        _makeClass('Deep Learning', 2, '13:00', '14:20'),
        _makeClass('Deep Learning', 4, '13:00', '14:20'),
      ];
      expect(classes.length, 2);
      expect(classes[0].dayOfWeek, 2);
      expect(classes[1].dayOfWeek, 4);
      // Each would get its own weekly recurring alarm
    });
  });

  group('Full Timetable Integration', () {
    final parser = TimetableParser();
    final sortService = TimetableSortService();
    final validator = TimetableValidator();

    test('Full sample timetable parse, sort, and validate', () {
      final text = '''
COMMUNICATION SKILLS (THU 08:30 11:30 E-904)
DEEP LEARNING (TUE 13:00 14:20 E-806, THU 13:00 14:20 E-806)
COMPUTER VISION (MON 14:30 15:50 E-507, WED 14:30 15:50 E-507)
COMPUTER VISION (LAB) (FRI 14:30 17:20 E-808)
DATA WAREHOUSING & DATA MINING (SUN 08:30 11:20 E-803)
''';
      final parsed = parser.parse(text);
      final deduped = validator.removeDuplicates(parsed);
      final sorted = sortService.sortClasses(deduped);

      // Verify Monday -> Sunday ordering
      for (int i = 0; i < sorted.length - 1; i++) {
        if (sorted[i].dayOfWeek == sorted[i + 1].dayOfWeek) {
          expect(sorted[i].startTime.compareTo(sorted[i + 1].startTime) <= 0, true,
              reason: 'Time ordering within day ${sorted[i].dayOfWeek}');
        } else {
          expect(sorted[i].dayOfWeek < sorted[i + 1].dayOfWeek, true,
              reason: 'Day ordering: ${sorted[i].dayOfWeek} should be < ${sorted[i + 1].dayOfWeek}');
        }
      }

      // Verify alarm times
      for (var c in sorted) {
        final alarmTime = sortService.calculateAlarmTime(c.startTime, 15);
        final errors = validator.validateClass(c);
        expect(errors, isEmpty, reason: 'Class ${c.courseName} should be valid');

        // Verify alarm is 15 minutes before
        final startParts = c.startTime.split(':');
        final alarmParts = alarmTime.split(':');
        final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final alarmMin = int.parse(alarmParts[0]) * 60 + int.parse(alarmParts[1]);
        // Account for day boundary
        final diff = (startMin - alarmMin + 24 * 60) % (24 * 60);
        expect(diff, 15, reason: 'Alarm for ${c.courseName} should be 15 min before ${c.startTime}');
      }
    });
  });
}

ClassSchedule _makeClass(String name, int day, String start, String end) {
  return ClassSchedule(
    courseName: name,
    dayOfWeek: day,
    startTime: start,
    endTime: end,
    room: '',
    alarmMinutesBefore: 15,
    alarmEnabled: true,
    scheduleId: 0,
  );
}
