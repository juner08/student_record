import 'package:flutter/material.dart';

import 'models/section.dart';
import 'screens/records_screen.dart';
import 'screens/score_form_screen.dart';
import 'screens/section_form_screen.dart';
import 'screens/section_list_screen.dart';
import 'screens/student_detail_screen.dart';
import 'screens/student_form_screen.dart';
import 'screens/student_list_screen.dart';

/// Page navigation table for the whole app.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String sectionForm = '/section-form';
  static const String studentList = '/student-list';
  static const String studentForm = '/student-form';
  static const String studentDetail = '/student-detail';
  static const String scoreForm = '/score-form';
  static const String records = '/records';

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        home: (BuildContext context) => const SectionListScreen(),
      };
}

Route<dynamic> appRouter(RouteSettings settings) {
  final Object? args = settings.arguments;
  switch (settings.name) {
    case AppRoutes.sectionForm:
      return MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            SectionFormScreen(section: args is Section ? args : null),
        settings: settings,
      );
    case AppRoutes.studentList:
      return MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            StudentListScreen(sectionId: args is String ? args : ''),
        settings: settings,
      );
    case AppRoutes.studentForm:
      final String sectionId =
          args is Map<String, dynamic> ? args['sectionId'] as String? ?? '' : '';
      final String studentId =
          args is Map<String, dynamic> ? args['studentId'] as String? ?? '' : '';
      return MaterialPageRoute<bool>(
        builder: (BuildContext context) => StudentFormScreen(
          sectionId: sectionId,
          studentId: studentId.isEmpty ? null : studentId,
        ),
        settings: settings,
      );
    case AppRoutes.studentDetail:
      return MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            StudentDetailScreen(studentId: args is String ? args : ''),
        settings: settings,
      );
    case AppRoutes.scoreForm:
      return MaterialPageRoute<bool>(
        builder: (BuildContext context) => ScoreFormScreen(
          studentId: args is String ? args : '',
        ),
        settings: settings,
      );
    case AppRoutes.records:
      return MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            RecordsScreen(sectionId: args is String ? args : ''),
        settings: settings,
      );
  }
  return MaterialPageRoute<void>(
    builder: (BuildContext context) => const SectionListScreen(),
    settings: settings,
  );
}