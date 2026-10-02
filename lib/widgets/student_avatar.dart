import 'package:flutter/material.dart';

import '../models/student.dart';

/// Student picture with an initials fallback so the app still looks fine
/// without an image (offline or invalid picture link).
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({super.key, required this.student, this.radius = 24});

  final Student student;
  final double radius;

  static const List<Color> _palette = <Color>[
    Color(0xFF1B5E9E),
    Color(0xFF7B1FA2),
    Color(0xFF00695C),
    Color(0xFFAD1457),
    Color(0xFFEF6C00),
    Color(0xFF283593),
    Color(0xFF2E7D32),
  ];

  Color get _background {
    int sum = 0;
    for (final int unit in student.fullName.codeUnits) {
      sum += unit;
    }
    return _palette[sum % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final double size = radius * 2;
    final Widget fallback = _Initials(
      text: student.initials,
      size: size,
      background: _background,
    );

    if (student.pictureUrl.trim().isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        student.pictureUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            fallback,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? progress,
        ) {
          if (progress == null) return child;
          return fallback;
        },
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.text,
    required this.size,
    required this.background,
  });

  final String text;
  final double size;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}