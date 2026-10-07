import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:class_alarm/core/app_theme.dart';
import 'package:class_alarm/core/constants.dart';
import 'package:class_alarm/models/class_schedule.dart';
import 'package:class_alarm/providers/schedule_provider.dart';

import 'package:class_alarm/widgets/class_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadSchedules();
      context.read<ScheduleProvider>().requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // Gradient App Bar
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Class Alarm',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient(colorScheme),
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 50),
                        child: Icon(Icons.alarm, size: 48, color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),

              // Next Class Hero
              SliverToBoxAdapter(child: _buildNextClassCard(context, provider)),

              // Today Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.today, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Today's classes
              if (provider.todayClasses.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 48, color: colorScheme.outline),
                          const SizedBox(height: 12),
                          Text(
                            'No classes today',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final c = provider.todayClasses[index];
                      return ClassCard(
                        classSchedule: c,
                        index: index,
                        onEdit: () => Navigator.pushNamed(context, '/add_edit_class', arguments: c),
                        onAlarmToggle: (val) => provider.toggleAlarm(c.id!),
                        onDelete: () => _confirmDelete(context, provider, c),
                      );
                    },
                    childCount: provider.todayClasses.length,
                  ),
                ),

              // Bottom Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/weekly_timetable'),
                          icon: const Icon(Icons.calendar_view_week),
                          label: const Text('View Weekly Timetable'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/import'),
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: const Text('Import Timetable'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/manage_alarms'),
                          icon: const Icon(Icons.alarm_on),
                          label: const Text('Manage Alarms'),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNextClassCard(BuildContext context, ScheduleProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final nextClass = provider.nextClass;

    if (nextClass == null) {
      // Empty state
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.school_outlined, size: 64, color: colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'Welcome to Class Alarm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Import your timetable to get started.\nNever miss a class again!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/import'),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Import Timetable'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final alarmTime = provider.calculateAlarmTime(
      nextClass.startTime,
      nextClass.alarmMinutesBefore,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.navigate_next, size: 18, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'NEXT CLASS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                nextClass.courseName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _infoChip(context, Icons.calendar_today,
                      AppConstants.getDayName(nextClass.dayOfWeek)),
                  const SizedBox(width: 12),
                  _infoChip(context, Icons.schedule,
                      '${nextClass.startTime} - ${nextClass.endTime}'),
                ],
              ),
              if (nextClass.room.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    _infoChip(context, Icons.room_outlined, nextClass.room),
                    const SizedBox(width: 12),
                    _infoChip(context, Icons.alarm, alarmTime),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onPrimaryContainer.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onPrimaryContainer.withOpacity(0.9),
          ),
        ),
      ],
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
