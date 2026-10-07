import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:class_alarm/models/class_schedule.dart';
import 'package:class_alarm/providers/schedule_provider.dart';
import 'package:class_alarm/widgets/class_card.dart';
import 'package:class_alarm/widgets/day_header.dart';

class WeeklyTimetableScreen extends StatelessWidget {
  const WeeklyTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Timetable'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_edit_class'),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          final classes = provider.classSchedules;

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_note, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No classes yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import a timetable or add classes manually.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
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

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: sortedDays.length,
            itemBuilder: (context, index) {
              final day = sortedDays[index];
              final dayClasses = grouped[day]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DayHeader(dayOfWeek: day, classCount: dayClasses.length),
                  ...dayClasses.map((c) => ClassCard(
                        classSchedule: c,
                        onEdit: () => Navigator.pushNamed(context, '/add_edit_class', arguments: c),
                        onAlarmToggle: (_) => provider.toggleAlarm(c.id!),
                        onDelete: () => _confirmDelete(context, provider, c),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ScheduleProvider provider, ClassSchedule c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Remove "${c.courseName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              provider.deleteClass(c.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
