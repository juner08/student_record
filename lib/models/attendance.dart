import 'package:flutter/material.dart';

enum AttendanceStatus { present, absent, excused }

extension AttendanceStatusInfo on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.excused:
        return 'EXCUSED';
    }
  }

  String get shortLabel {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  /// One-tap system: every tap moves to the next status.
  /// PRESENT -> ABSENT -> EXCUSED -> PRESENT
  AttendanceStatus get next {
    switch (this) {
      case AttendanceStatus.present:
        return AttendanceStatus.absent;
      case AttendanceStatus.absent:
        return AttendanceStatus.excused;
      case AttendanceStatus.excused:
        return AttendanceStatus.present;
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.excused:
        return Icons.event_busy;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return const Color(0xFF1B8E4B);
      case AttendanceStatus.absent:
        return const Color(0xFFC62828);
      case AttendanceStatus.excused:
        return const Color(0xFFB26A00);
    }
  }
}

class AttendanceEntry {
  AttendanceEntry({required this.date, required this.status});

  DateTime date;
  AttendanceStatus status;
}

String dayKey(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

String formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatShortDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}