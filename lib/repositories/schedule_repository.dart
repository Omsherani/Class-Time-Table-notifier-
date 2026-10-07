import '../database/database_helper.dart';
import '../models/class_schedule.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Schedule> createSchedule(Schedule schedule) async {
    final db = await _dbHelper.database;
    
    // If making this active, deactivate others
    if (schedule.isActive) {
      await db.update('schedules', {'isActive': 0});
    }

    final id = await db.insert('schedules', schedule.toMap());
    return schedule.copyWith(id: id);
  }

  Future<Schedule?> getActiveSchedule() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedules',
      where: 'isActive = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      return Schedule.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Schedule>> getAllSchedules() async {
    final db = await _dbHelper.database;
    final maps = await db.query('schedules', orderBy: 'createdAt DESC');
    return maps.map((map) => Schedule.fromMap(map)).toList();
  }

  Future<int> updateSchedule(Schedule schedule) async {
    final db = await _dbHelper.database;
    
    if (schedule.isActive) {
      await db.update('schedules', {'isActive': 0});
    }
    
    return db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ClassSchedule> createClassSchedule(ClassSchedule classSchedule) async {
    final db = await _dbHelper.database;
    final id = await db.insert('class_schedules', classSchedule.toMap());
    return classSchedule.copyWith(id: id);
  }

  Future<List<ClassSchedule>> getClassSchedulesForSchedule(int scheduleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'class_schedules',
      where: 'scheduleId = ?',
      whereArgs: [scheduleId],
      orderBy: 'dayOfWeek ASC, startTime ASC',
    );

    return maps.map((map) => ClassSchedule.fromMap(map)).toList();
  }

  Future<int> updateClassSchedule(ClassSchedule classSchedule) async {
    final db = await _dbHelper.database;
    return db.update(
      'class_schedules',
      classSchedule.toMap(),
      where: 'id = ?',
      whereArgs: [classSchedule.id],
    );
  }

  Future<int> deleteClassSchedule(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'class_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
