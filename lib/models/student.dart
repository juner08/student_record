import 'attendance.dart';
import 'score.dart';

class Student {
  Student({
    required this.id,
    required this.studentNumber,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.sectionId,
    this.contact = '',
    this.pictureUrl = '',
    List<ScoreEntry>? scores,
    List<AttendanceEntry>? attendance,
  })  : scores = scores ?? <ScoreEntry>[],
        attendance = attendance ?? <AttendanceEntry>[];

  final String id;
  String studentNumber;
  String fullName;
  int age;
  String gender;
  String sectionId;
  String contact;
  String pictureUrl;
  final List<ScoreEntry> scores;
  final List<AttendanceEntry> attendance;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Overall average = mean of the percentage of every recorded score.
  double get overallAverage {
    if (scores.isEmpty) return 0;
    double total = 0;
    for (final ScoreEntry entry in scores) {
      total += entry.percentage;
    }
    return total / scores.length;
  }

  String get averageLabel {
    if (scores.isEmpty) return '--';
    return '${overallAverage.toStringAsFixed(1)}%';
  }

  ScoreEntry? scoreFor(String categoryId) {
    for (final ScoreEntry entry in scores) {
      if (entry.categoryId == categoryId) return entry;
    }
    return null;
  }

  void setScore(String categoryId, double score, double maxScore) {
    final ScoreEntry? existing = scoreFor(categoryId);
    if (existing != null) {
      existing
        ..score = score
        ..maxScore = maxScore;
    } else {
      scores.add(
        ScoreEntry(categoryId: categoryId, score: score, maxScore: maxScore),
      );
    }
  }

  void clearScore(String categoryId) {
    scores.removeWhere((ScoreEntry e) => e.categoryId == categoryId);
  }

  /// Average percentage per category, used by the records/summary screen.
  Map<String, double> get categoryAverages {
    final Map<String, double> sums = <String, double>{};
    final Map<String, int> counts = <String, int>{};
    for (final ScoreEntry entry in scores) {
      sums[entry.categoryId] = (sums[entry.categoryId] ?? 0) + entry.percentage;
      counts[entry.categoryId] = (counts[entry.categoryId] ?? 0) + 1;
    }
    return sums.map(
      (String key, double value) =>
          MapEntry<String, double>(key, value / counts[key]!),
    );
  }

  AttendanceEntry? entryOn(DateTime date) {
    final String key = dayKey(date);
    for (final AttendanceEntry entry in attendance) {
      if (dayKey(entry.date) == key) return entry;
    }
    return null;
  }

  /// Defaults to PRESENT so the class totals always add up.
  AttendanceStatus statusOn(DateTime date) =>
      entryOn(date)?.status ?? AttendanceStatus.present;

  AttendanceStatus get todayStatus => statusOn(DateTime.now());

  List<AttendanceEntry> get sortedAttendance {
    final List<AttendanceEntry> list = List<AttendanceEntry>.from(attendance);
    list.sort(
      (AttendanceEntry a, AttendanceEntry b) => b.date.compareTo(a.date),
    );
    return list;
  }

  int countOf(AttendanceStatus status) =>
      attendance.where((AttendanceEntry e) => e.status == status).length;

  void setAttendance(DateTime date, AttendanceStatus status) {
    final AttendanceEntry? existing = entryOn(date);
    if (existing != null) {
      existing.status = status;
    } else {
      attendance.add(
        AttendanceEntry(
          date: DateTime(date.year, date.month, date.day),
          status: status,
        ),
      );
    }
  }

  /// One-tap attendance: PRESENT -> ABSENT -> EXCUSED -> PRESENT.
  void cycleAttendance(DateTime date) => setAttendance(date, statusOn(date).next);
}