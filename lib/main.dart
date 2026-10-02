import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'data/record_manager.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // All data is simulated: it lives in plain List / Map objects in memory.
  RecordManager.instance.loadSampleData();
  runApp(const StudentRecordApp());
}

class StudentRecordApp extends StatelessWidget {
  const StudentRecordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Record Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
      onGenerateRoute: appRouter,
    );
  }
}