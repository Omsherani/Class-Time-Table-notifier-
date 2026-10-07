class ClassSchedule {
  final int? id;
  final String courseName;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String startTime; // "HH:mm" 24-hour format
  final String endTime; // "HH:mm" 24-hour format
  final String room;
  final int alarmMinutesBefore;
  final bool alarmEnabled;
  final int scheduleId;

  ClassSchedule({
    this.id,
    required this.courseName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.alarmMinutesBefore,
    required this.alarmEnabled,
    required this.scheduleId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseName': courseName,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'alarmMinutesBefore': alarmMinutesBefore,
      'alarmEnabled': alarmEnabled ? 1 : 0,
      'scheduleId': scheduleId,
    };
  }

  factory ClassSchedule.fromMap(Map<String, dynamic> map) {
    return ClassSchedule(
      id: map['id'],
      courseName: map['courseName'],
      dayOfWeek: map['dayOfWeek'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      room: map['room'] ?? '',
      alarmMinutesBefore: map['alarmMinutesBefore'],
      alarmEnabled: map['alarmEnabled'] == 1,
      scheduleId: map['scheduleId'],
    );
  }

  ClassSchedule copyWith({
    int? id,
    String? courseName,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
    int? alarmMinutesBefore,
    bool? alarmEnabled,
    int? scheduleId,
  }) {
    return ClassSchedule(
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      alarmMinutesBefore: alarmMinutesBefore ?? this.alarmMinutesBefore,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      scheduleId: scheduleId ?? this.scheduleId,
    );
  }
}
