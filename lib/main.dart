import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:class_alarm/core/app_theme.dart';
import 'package:class_alarm/models/class_schedule.dart';
import 'package:class_alarm/providers/schedule_provider.dart';
import 'package:class_alarm/features/home/home_screen.dart';
import 'package:class_alarm/features/ocr/import_screen.dart';
import 'package:class_alarm/features/ocr/verify_screen.dart';
import 'package:class_alarm/features/timetable/weekly_timetable_screen.dart';
import 'package:class_alarm/features/timetable/add_edit_class_screen.dart';
import 'package:class_alarm/features/alarms/manage_alarms_screen.dart';
import 'package:class_alarm/features/settings/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClassAlarmApp());
}

class ClassAlarmApp extends StatelessWidget {
  const ClassAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleProvider(),
      child: MaterialApp(
        title: 'Class Alarm',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case '/import':
              return MaterialPageRoute(builder: (_) => const ImportScreen());
            case '/verify':
              final classes = settings.arguments as List<ClassSchedule>;
              return MaterialPageRoute(
                builder: (_) => VerifyScreen(parsedClasses: classes),
              );
            case '/weekly_timetable':
              return MaterialPageRoute(builder: (_) => const WeeklyTimetableScreen());
            case '/add_edit_class':
              final existing = settings.arguments as ClassSchedule?;
              return MaterialPageRoute(
                builder: (_) => AddEditClassScreen(existingClass: existing),
              );
            case '/manage_alarms':
              return MaterialPageRoute(builder: (_) => const ManageAlarmsScreen());
            case '/settings':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            default:
              return MaterialPageRoute(builder: (_) => const HomeScreen());
          }
        },
      ),
    );
  }
}
