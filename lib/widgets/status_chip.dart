import 'package:flutter/material.dart';

import '../models/attendance.dart';

/// Small colored label that shows an attendance status.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final AttendanceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(status.icon, size: compact ? 12 : 15, color: status.color),
          const SizedBox(width: 4),
          Text(
            compact ? status.label.substring(0, 3) : status.label,
            style: TextStyle(
              color: status.color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// One-tap attendance button. Tapping it advances the status of the student.
class AttendanceTapButton extends StatelessWidget {
  const AttendanceTapButton({
    super.key,
    required this.status,
    required this.onTap,
  });

  final AttendanceStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tap to mark as ${status.next.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: StatusChip(status: status),
      ),
    );
  }
}