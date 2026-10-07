import '../models/class_schedule.dart';

class TimetableParser {
  static final RegExp dayRegex = RegExp(
      r'\b(MON|TUE|WED|THU|FRI|SAT|SUN|MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY|SATURDAY|SUNDAY)\b',
      caseSensitive: false);

  static final RegExp timeRegex = RegExp(
      r'\b((?:0?[1-9]|1[0-2]):[0-5][0-9]\s*(?:AM|PM|am|pm)?|(?:[01]?[0-9]|2[0-3]):[0-5][0-9])\b',
      caseSensitive: false);

  int parseDayOfWeek(String dayStr) {
    dayStr = dayStr.toUpperCase().trim();
    if (dayStr.startsWith('MON')) return 1;
    if (dayStr.startsWith('TUE')) return 2;
    if (dayStr.startsWith('WED')) return 3;
    if (dayStr.startsWith('THU')) return 4;
    if (dayStr.startsWith('FRI')) return 5;
    if (dayStr.startsWith('SAT')) return 6;
    if (dayStr.startsWith('SUN')) return 7;
    return 1;
  }

  String normalizeTime(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    bool isPM = timeStr.contains('PM');
    bool isAM = timeStr.contains('AM');
    
    timeStr = timeStr.replaceAll(RegExp(r'\s*(AM|PM)'), '');
    
    List<String> parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;
    
    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = int.tryParse(parts[1]) ?? 0;

    if (isPM && hour < 12) hour += 12;
    if (isAM && hour == 12) hour = 0;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  List<ClassSchedule> parse(String text) {
    List<ClassSchedule> schedules = [];
    
    text = text.replaceAll('\r\n', '\n');
    List<String> lines = text.split('\n');
    
    String currentCourseContext = "Unknown Class";

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      bool hasDay = dayRegex.hasMatch(line);
      bool hasTimes = timeRegex.allMatches(line).length >= 2;

      if (hasDay && hasTimes) {
        // Line has schedule info. Does it also have course info?
        // e.g. "COMMUNICATION SKILLS (THU 08:30 11:30 E-904)"
        // Check for parens
        var parenMatches = RegExp(r'\((.*?)\)').allMatches(line);
        if (parenMatches.isNotEmpty) {
          for (var match in parenMatches) {
            String inner = match.group(1) ?? '';
            if (dayRegex.hasMatch(inner) && timeRegex.allMatches(inner).length >= 2) {
              String course = line.replaceAll(match.group(0) ?? '', '').trim();
              if (course.isNotEmpty) {
                currentCourseContext = course;
              }
              List<String> subParts = inner.split(',');
              for (var part in subParts) {
                if (dayRegex.hasMatch(part) && timeRegex.allMatches(part).length >= 2) {
                  schedules.addAll(_extractFromLine(part, currentCourseContext));
                }
              }
            }
          }
        } else {
          // No parens, but has schedule info.
          // Is there non-schedule text?
          String textWithoutSchedule = line;
          for (var m in dayRegex.allMatches(line)) {
            textWithoutSchedule = textWithoutSchedule.replaceFirst(m.group(0)!, '');
          }
          for (var m in timeRegex.allMatches(line)) {
            textWithoutSchedule = textWithoutSchedule.replaceFirst(m.group(0)!, '');
          }
          // The remaining might be room, or course name. It's ambiguous without parens or newlines.
          // We will just use currentCourseContext if there's no obvious course name.
          schedules.addAll(_extractFromLine(line, currentCourseContext));
        }
      } else {
        // No schedule info, update course context
        if (line.length > 3 && !line.toLowerCase().contains("timetable")) {
           String cleanLine = line.replaceAll(RegExp(r'\(.*\)'), '').trim();
           if (cleanLine.isNotEmpty) {
             currentCourseContext = cleanLine;
           }
        }
      }
    }

    return schedules;
  }

  List<ClassSchedule> _extractFromLine(String text, String courseContext) {
    List<ClassSchedule> schedules = [];
    // Could have multiple days in one line? usually no, but maybe separated by commas.
    // Let's just find all days and times in this snippet.
    
    // Try to find Day
    Iterable<RegExpMatch> dayMatches = dayRegex.allMatches(text);
    Iterable<RegExpMatch> timeMatches = timeRegex.allMatches(text);
    
    if (dayMatches.isEmpty || timeMatches.length < 2) return schedules;

    // Room is whatever is left after removing days, times, and punctuation
    String roomStr = text;
    for (var m in dayMatches) roomStr = roomStr.replaceFirst(m.group(0)!, '');
    for (var m in timeMatches) roomStr = roomStr.replaceFirst(m.group(0)!, '');
    roomStr = roomStr.replaceAll(RegExp(r'[(),\-]'), ' ').trim();
    // remove extra spaces
    roomStr = roomStr.replaceAll(RegExp(r'\s+'), ' ');

    // For each day match (if multiple), assume they share the same times.
    // Though usually it's e.g., "TUE 13:00 14:20"
    // Let's just process the first day and first 2 times for simplicity, unless we iterate correctly.
    // Often it's one day per chunk.
    int day = parseDayOfWeek(dayMatches.first.group(0)!);
    String startTime = normalizeTime(timeMatches.elementAt(0).group(0)!);
    String endTime = normalizeTime(timeMatches.elementAt(1).group(0)!);

    schedules.add(ClassSchedule(
      courseName: courseContext,
      dayOfWeek: day,
      startTime: startTime,
      endTime: endTime,
      room: roomStr,
      alarmMinutesBefore: 15, // Default
      alarmEnabled: true,
      scheduleId: 0, // Assigned later
    ));
    
    return schedules;
  }
}
