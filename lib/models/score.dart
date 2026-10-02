import 'package:flutter/material.dart';

/// A score category such as Quiz 1, Quiz 2, Exam, Activity, Assignment,
/// Project. Categories are kept in a plain List inside the RecordManager.
class Category {
  Category({
    required this.id,
    required this.name,
    required this.maxScore,
    this.kind = CategoryKind.quiz,
  });

  final String id;
  String name;
  double maxScore;
  CategoryKind kind;

  bool get isExam => kind == CategoryKind.exam;
}

enum CategoryKind { quiz, exam, activity, assignment, project }

extension CategoryKindInfo on CategoryKind {
  String get label {
    switch (this) {
      case CategoryKind.quiz:
        return 'Quiz';
      case CategoryKind.exam:
        return 'Exam';
      case CategoryKind.activity:
        return 'Activity';
      case CategoryKind.assignment:
        return 'Assignment';
      case CategoryKind.project:
        return 'Project';
    }
  }

  IconData get icon {
    switch (this) {
      case CategoryKind.quiz:
        return Icons.quiz_outlined;
      case CategoryKind.exam:
        return Icons.assignment_outlined;
      case CategoryKind.activity:
        return Icons.sports_esports_outlined;
      case CategoryKind.assignment:
        return Icons.bookmark_outline;
      case CategoryKind.project:
        return Icons.folder_special_outlined;
    }
  }
}

/// One score a student earned in one category.
class ScoreEntry {
  ScoreEntry({
    required this.categoryId,
    required this.score,
    required this.maxScore,
  });

  String categoryId;
  double score;
  double maxScore;

  double get percentage => maxScore <= 0 ? 0 : (score / maxScore) * 100;

  String get display => '${_trim(score)}/${_trim(maxScore)}';

  static String _trim(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}