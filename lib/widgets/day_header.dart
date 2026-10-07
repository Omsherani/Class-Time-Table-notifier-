import 'package:flutter/material.dart';
import 'package:class_alarm/core/app_theme.dart';
import 'package:class_alarm/core/constants.dart';

class DayHeader extends StatelessWidget {
  final int dayOfWeek;
  final int classCount;

  const DayHeader({
    super.key,
    required this.dayOfWeek,
    this.classCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayColor = AppTheme.dayAccentColor(dayOfWeek, colorScheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: dayColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppConstants.getDayName(dayOfWeek),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: dayColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (classCount > 0) ...[
            const SizedBox(width: 8),
            Text(
              '$classCount ${classCount == 1 ? 'class' : 'classes'}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
