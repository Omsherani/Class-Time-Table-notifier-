import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:class_alarm/core/constants.dart';
import 'package:class_alarm/providers/schedule_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Default Reminder
              _sectionHeader(context, 'Alarms'),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Default Reminder'),
                subtitle: Text('${provider.defaultReminderMinutes} minutes before class'),
                trailing: DropdownButton<int>(
                  value: provider.defaultReminderMinutes,
                  underline: const SizedBox(),
                  items: AppConstants.reminderOptions.map((m) {
                    return DropdownMenuItem(value: m, child: Text('$m min'));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) provider.setDefaultReminder(v);
                  },
                ),
              ),

              const Divider(),

              // Schedules
              _sectionHeader(context, 'Schedules'),
              ...provider.allSchedules.map((s) => ListTile(
                    leading: Icon(
                      s.isActive ? Icons.check_circle : Icons.circle_outlined,
                      color: s.isActive ? colorScheme.primary : colorScheme.outline,
                    ),
                    title: Text(s.name),
                    subtitle: Text(s.isActive ? 'Active' : 'Inactive'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!s.isActive)
                          TextButton(
                            onPressed: () => provider.switchSchedule(s.id!),
                            child: const Text('Activate'),
                          ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: colorScheme.error),
                          onPressed: () => _confirmDeleteSchedule(context, provider, s.id!, s.name),
                        ),
                      ],
                    ),
                  )),
              ListTile(
                leading: Icon(Icons.add, color: colorScheme.primary),
                title: const Text('Create New Schedule'),
                onTap: () => _createScheduleDialog(context, provider),
              ),

              const Divider(),

              // Permissions
              _sectionHeader(context, 'Permissions'),
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Manage Permissions'),
                subtitle: const Text('Alarm & notification permissions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => provider.requestPermissions(),
              ),

              const Divider(),

              // Danger Zone
              _sectionHeader(context, 'Data'),
              ListTile(
                leading: Icon(Icons.delete_forever, color: colorScheme.error),
                title: Text('Delete All Data', style: TextStyle(color: colorScheme.error)),
                subtitle: const Text('Remove all timetables and alarms'),
                onTap: () => _confirmDeleteAll(context, provider),
              ),

              const Divider(),

              // About
              _sectionHeader(context, 'About'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Class Alarm'),
                subtitle: Text('Version 1.0.0\nNever miss a class again.'),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  void _createScheduleDialog(BuildContext context, ScheduleProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Schedule'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Schedule Name',
            hintText: 'e.g. Fall 2026',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.createSchedule(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSchedule(BuildContext context, ScheduleProvider provider, int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Delete "$name" and all its classes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              provider.deleteSchedule(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text('This will remove ALL timetables, classes, and alarms. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              provider.deleteAllData();
              Navigator.pop(ctx);
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}
