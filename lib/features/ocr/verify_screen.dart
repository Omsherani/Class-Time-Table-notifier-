import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:class_alarm/core/constants.dart';
import 'package:class_alarm/models/class_schedule.dart';
import 'package:class_alarm/providers/schedule_provider.dart';
import 'package:class_alarm/services/timetable_validator.dart';
import 'package:class_alarm/services/timetable_sort_service.dart';
import 'package:class_alarm/widgets/class_card.dart';
import 'package:class_alarm/widgets/day_header.dart';

class VerifyScreen extends StatefulWidget {
  final List<ClassSchedule> parsedClasses;

  const VerifyScreen({super.key, required this.parsedClasses});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  late List<ClassSchedule> _classes;
  final TimetableValidator _validator = TimetableValidator();
  final TimetableSortService _sortService = TimetableSortService();

  @override
  void initState() {
    super.initState();
    _classes = List.from(widget.parsedClasses);
    _classes = _validator.removeDuplicates(_classes);
    _classes = _sortService.sortClasses(_classes);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Group by day
    Map<int, List<ClassSchedule>> grouped = {};
    for (var c in _classes) {
      grouped.putIfAbsent(c.dayOfWeek, () => []);
      grouped[c.dayOfWeek]!.add(c);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Timetable'),
      ),
      body: _classes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'No classes detected',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try importing a clearer image or add classes manually.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Info bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: colorScheme.secondaryContainer,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: colorScheme.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Found ${_classes.length} classes. Review and edit before creating alarms.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, index) {
                      final day = grouped.keys.toList()..sort();
                      final dayNum = day[index];
                      final dayClasses = grouped[dayNum]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DayHeader(dayOfWeek: dayNum, classCount: dayClasses.length),
                          ...dayClasses.map((c) {
                            final errors = _validator.validateClass(c);
                            final hasWarnings = errors.isNotEmpty;

                            return Stack(
                              children: [
                                ClassCard(
                                  classSchedule: c,
                                  showAlarmToggle: false,
                                  onEdit: () => _editClass(c),
                                  onDelete: () => _deleteClass(c),
                                ),
                                if (hasWarnings)
                                  Positioned(
                                    top: 8,
                                    right: 24,
                                    child: Tooltip(
                                      message: errors.join('\n'),
                                      child: Icon(Icons.warning_amber, size: 18, color: colorScheme.error),
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),

                // Bottom bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/add_edit_class').then((result) {
                              if (result != null && result is ClassSchedule) {
                                setState(() {
                                  _classes.add(result);
                                  _classes = _sortService.sortClasses(_classes);
                                });
                              }
                            }),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Class'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _createAlarms,
                            icon: const Icon(Icons.alarm_add),
                            label: const Text('CREATE ALARMS'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _editClass(ClassSchedule original) async {
    final result = await Navigator.pushNamed(context, '/add_edit_class', arguments: original);
    if (result != null && result is ClassSchedule) {
      setState(() {
        final idx = _classes.indexWhere((c) =>
            c.courseName == original.courseName &&
            c.dayOfWeek == original.dayOfWeek &&
            c.startTime == original.startTime);
        if (idx >= 0) _classes[idx] = result;
        _classes = _sortService.sortClasses(_classes);
      });
    }
  }

  void _deleteClass(ClassSchedule c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Class'),
        content: Text('Remove "${c.courseName}" on ${AppConstants.getDayName(c.dayOfWeek)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _classes.removeWhere((x) =>
                    x.courseName == c.courseName &&
                    x.dayOfWeek == c.dayOfWeek &&
                    x.startTime == c.startTime);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _createAlarms() async {
    // Validate all classes
    bool allValid = true;
    for (var c in _classes) {
      if (_validator.validateClass(c).isNotEmpty) {
        allValid = false;
        break;
      }
    }

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all warnings before creating alarms.'),
        ),
      );
      return;
    }

    final provider = context.read<ScheduleProvider>();
    await provider.addAllClasses(_classes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_classes.length} alarms created successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }
}
