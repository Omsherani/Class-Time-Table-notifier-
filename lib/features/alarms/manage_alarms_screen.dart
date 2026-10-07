import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:class_alarm/core/constants.dart';
import 'package:class_alarm/models/class_schedule.dart';
import 'package:class_alarm/providers/schedule_provider.dart';
import 'package:class_alarm/services/timetable_sort_service.dart';
import 'package:class_alarm/widgets/day_header.dart';

class ManageAlarmsScreen extends StatelessWidget {
  const ManageAlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortService = TimetableSortService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Alarms'),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          final classes = provider.classSchedules;

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alarm_off, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No alarms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text('Import a timetable first.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          // Group by day
          Map<int, List<ClassSchedule>> grouped = {};
          for (var c in classes) {
            grouped.putIfAbsent(c.dayOfWeek, () => []);
            grouped[c.dayOfWeek]!.add(c);
          }
          final sortedDays = grouped.keys.toList()..sort();

          // Reminder selector
          return Column(
            children: [
              // Reminder duration header
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Default Reminder', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                            Text('${provider.defaultReminderMinutes} minutes before class',
                                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      DropdownButton<int>(
                        value: provider.defaultReminderMinutes,
                        underline: const SizedBox(),
                        items: AppConstants.reminderOptions.map((m) {
                          return DropdownMenuItem(value: m, child: Text('${m}m'));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) provider.setDefaultReminder(v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: sortedDays.length,
                  itemBuilder: (context, index) {
                    final day = sortedDays[index];
                    final dayClasses = grouped[day]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DayHeader(dayOfWeek: day, classCount: dayClasses.length),
                        ...dayClasses.map((c) {
                          final alarmTime = sortService.calculateAlarmTime(c.startTime, c.alarmMinutesBefore);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                c.alarmEnabled ? Icons.alarm_on : Icons.alarm_off,
                                color: c.alarmEnabled ? colorScheme.primary : colorScheme.outline,
                              ),
                              title: Text(c.courseName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '🔔 $alarmTime  •  ${c.startTime} - ${c.endTime}${c.room.isNotEmpty ? '  •  ${c.room}' : ''}',
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                              trailing: Switch(
                                value: c.alarmEnabled,
                                onChanged: (_) => provider.toggleAlarm(c.id!),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
