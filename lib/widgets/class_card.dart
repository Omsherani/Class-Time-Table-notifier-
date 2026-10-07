import 'package:flutter/material.dart';
import 'package:class_alarm/core/app_theme.dart';

import 'package:class_alarm/models/class_schedule.dart';
import 'package:class_alarm/services/timetable_sort_service.dart';

class ClassCard extends StatelessWidget {
  final ClassSchedule classSchedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onAlarmToggle;
  final bool showAlarmToggle;
  final int index;

  const ClassCard({
    super.key,
    required this.classSchedule,
    this.onEdit,
    this.onDelete,
    this.onAlarmToggle,
    this.showAlarmToggle = true,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortService = TimetableSortService();
    final alarmTime = sortService.calculateAlarmTime(
      classSchedule.startTime,
      classSchedule.alarmMinutesBefore,
    );
    final dayColor = AppTheme.dayAccentColor(classSchedule.dayOfWeek, colorScheme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time indicator bar
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: dayColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Time column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classSchedule.startTime,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    classSchedule.endTime,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classSchedule.courseName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (classSchedule.room.isNotEmpty) ...[
                          Icon(Icons.room_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            classSchedule.room,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.alarm, size: 14, color: classSchedule.alarmEnabled ? dayColor : colorScheme.outline),
                        const SizedBox(width: 2),
                        Text(
                          alarmTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: classSchedule.alarmEnabled ? dayColor : colorScheme.outline,
                            fontWeight: classSchedule.alarmEnabled ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              if (showAlarmToggle)
                Switch(
                  value: classSchedule.alarmEnabled,
                  onChanged: onAlarmToggle,
                ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
