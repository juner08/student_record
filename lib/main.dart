import 'dart:async';

import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'data/record_manager.dart';
import 'data/record_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sections, students and their pictures are kept in plain lists inside
  // RecordManager. RecordStorage mirrors that state to the device / browser
  // storage so a refresh does not throw the class record away.
  await RecordStorage.instance.init();
  final RecordManager db = RecordManager.instance;
  if (!RecordStorage.instance.restore(db)) {
    // First launch: show the demo class record as before.
    db.loadSampleData();
  }

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
      builder: (BuildContext context, Widget? child) =>
          _StorageFlushOnExit(child: child),
    );
  }
}

/// Writes any pending change when the app is backgrounded or closed. Saves are
/// already triggered on every edit, this is only a safety net.
class _StorageFlushOnExit extends StatefulWidget {
  const _StorageFlushOnExit({required this.child});

  final Widget? child;

  @override
  State<_StorageFlushOnExit> createState() => _StorageFlushOnExitState();
}

class _StorageFlushOnExitState extends State<_StorageFlushOnExit>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(RecordStorage.instance.save(RecordManager.instance));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
