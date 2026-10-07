class AppConstants {
  static const List<String> dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const List<String> dayAbbreviations = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
  ];

  static const int defaultReminderMinutes = 15;

  static const List<int> reminderOptions = [5, 10, 15, 20, 30, 45, 60];

  static String getDayName(int dayOfWeek) {
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return dayNames[dayOfWeek - 1];
    }
    return 'Unknown';
  }

  static String getDayAbbreviation(int dayOfWeek) {
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return dayAbbreviations[dayOfWeek - 1];
    }
    return '???';
  }
}
