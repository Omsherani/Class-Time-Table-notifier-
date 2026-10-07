import 'package:flutter/material.dart';
import 'package:class_alarm/core/constants.dart';
import 'package:class_alarm/models/class_schedule.dart';

class AddEditClassScreen extends StatefulWidget {
  final ClassSchedule? existingClass;

  const AddEditClassScreen({super.key, this.existingClass});

  @override
  State<AddEditClassScreen> createState() => _AddEditClassScreenState();
}

class _AddEditClassScreenState extends State<AddEditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _courseNameController;
  late TextEditingController _roomController;
  int _selectedDay = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 30);
  int _alarmMinutesBefore = AppConstants.defaultReminderMinutes;

  bool get isEditing => widget.existingClass != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingClass;
    _courseNameController = TextEditingController(text: existing?.courseName ?? '');
    _roomController = TextEditingController(text: existing?.room ?? '');

    if (existing != null) {
      _selectedDay = existing.dayOfWeek;
      _startTime = _parseTimeOfDay(existing.startTime);
      _endTime = _parseTimeOfDay(existing.endTime);
      _alarmMinutesBefore = existing.alarmMinutesBefore;
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Class' : 'Add Class'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Name
              TextFormField(
                controller: _courseNameController,
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  hintText: 'e.g. Computer Science 101',
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Course name is required' : null,
              ),
              const SizedBox(height: 20),

              // Day Picker
              Text('Day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedDay,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: List.generate(7, (i) {
                  return DropdownMenuItem(
                    value: i + 1,
                    child: Text(AppConstants.dayNames[i]),
                  );
                }),
                onChanged: (v) => setState(() => _selectedDay = v ?? 1),
              ),
              const SizedBox(height: 20),

              // Time Pickers
              Row(
                children: [
                  Expanded(
                    child: _timePicker(
                      context,
                      label: 'Start Time',
                      time: _startTime,
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _timePicker(
                      context,
                      label: 'End Time',
                      time: _endTime,
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _endTime);
                        if (picked != null) setState(() => _endTime = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Room
              TextFormField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Room (optional)',
                  hintText: 'e.g. E-507',
                  prefixIcon: const Icon(Icons.room_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Alarm minutes
              Text('Remind me', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: AppConstants.reminderOptions.contains(_alarmMinutesBefore)
                    ? _alarmMinutesBefore
                    : AppConstants.defaultReminderMinutes,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.alarm),
                  suffixText: 'minutes before class',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: AppConstants.reminderOptions.map((m) {
                  return DropdownMenuItem(value: m, child: Text('$m'));
                }).toList(),
                onChanged: (v) => setState(() => _alarmMinutesBefore = v ?? 15),
              ),
              const SizedBox(height: 32),

              // Save
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(isEditing ? 'UPDATE CLASS' : 'SAVE CLASS'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timePicker(BuildContext context, {required String label, required TimeOfDay time, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  _formatTimeOfDay(time),
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final result = ClassSchedule(
      id: widget.existingClass?.id,
      courseName: _courseNameController.text.trim(),
      dayOfWeek: _selectedDay,
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      room: _roomController.text.trim(),
      alarmMinutesBefore: _alarmMinutesBefore,
      alarmEnabled: widget.existingClass?.alarmEnabled ?? true,
      scheduleId: widget.existingClass?.scheduleId ?? 0,
    );

    Navigator.pop(context, result);
  }
}
