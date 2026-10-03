import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance.dart';
import '../models/score.dart';
import '../models/section.dart';
import '../models/student.dart';
import 'record_manager.dart';

/// Keeps the in-memory records of [RecordManager] alive between app starts.
///
/// The project stores everything in plain lists, so a refresh used to throw
/// every section, student and uploaded picture away. This class serialises the
/// same data to JSON and writes it through `shared_preferences`, which is
/// localStorage on the web and a small key/value store on desktop and mobile.
///
/// Design notes:
///  * Records and pictures use two separate keys, so a full picture store can
///    never stop the rest of the class record from being saved.
///  * Every operation is best effort. A missing plugin, a full store or a
///    corrupted value is logged and ignored - the app keeps working with the
///    data it already has in memory.
class RecordStorage {
  RecordStorage._();

  static final RecordStorage instance = RecordStorage._();

  /// Bump when the JSON shape changes so old snapshots are ignored.
  static const int schemaVersion = 1;
  static const String _recordsKey = 'student_record.records.v1';
  static const String _picturesKey = 'student_record.pictures.v1';
  static const Duration _debounce = Duration(milliseconds: 350);

  SharedPreferences? _prefs;
  Timer? _timer;

  /// True when a working preferences backend is available.
  bool get isAvailable => _prefs != null;

/// Opens the key/value backend. Never throws.
  ///
  /// `SharedPreferences` caches the platform instance internally, so calling
  /// this again is cheap and picks up a restarted platform.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (error) {
      _prefs = null;
      debugPrint('RecordStorage: preferences unavailable ($error)');
    }
  }

  /// Reads the saved snapshot back into [db].
  ///
  /// Returns `false` when nothing was stored yet or when the stored value
  /// cannot be read, so the caller can fall back to the sample data.
  bool restore(RecordManager db) {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return false;

    final String? raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return false;

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      if (decoded['version'] != schemaVersion) return false;

      final List<Section> sections = _readList(
        decoded['sections'],
        (Map<String, dynamic> json) => Section(
          id: _text(json['id']),
          name: _text(json['name']),
          adviser: _text(json['adviser']),
        ),
      );
      final List<Category> categories = _readList(
        decoded['categories'],
        (Map<String, dynamic> json) => Category(
          id: _text(json['id']),
          name: _text(json['name']),
          maxScore: _number(json['maxScore']),
          kind: CategoryKind.values.firstWhere(
            (CategoryKind k) => k.name == json['kind'],
            orElse: () => CategoryKind.quiz,
          ),
        ),
      );
      final List<Student> students = _readList(
        decoded['students'],
        (Map<String, dynamic> json) => Student(
          id: _text(json['id']),
          studentNumber: _text(json['studentNumber']),
          fullName: _text(json['fullName']),
          age: _integer(json['age']),
          gender: _text(json['gender']),
          sectionId: _text(json['sectionId']),
          contact: _text(json['contact']),
          scores: _readList(
            json['scores'],
            (Map<String, dynamic> s) => ScoreEntry(
              categoryId: _text(s['categoryId']),
              score: _number(s['score']),
              maxScore: _number(s['maxScore']),
            ),
          ),
          attendance: _readList(
            json['attendance'],
            (Map<String, dynamic> a) => AttendanceEntry(
              date: DateTime.tryParse(_text(a['date'])) ?? DateTime.now(),
              status: AttendanceStatus.values.firstWhere(
                (AttendanceStatus s) => s.name == a['status'],
                orElse: () => AttendanceStatus.present,
              ),
            ),
          ),
        ),
      );

      if (sections.isEmpty && students.isEmpty && categories.isEmpty) {
        return false;
      }

      db.replaceAll(
        sections: sections,
        students: students,
        categories: categories,
      );
      _applyPictures(db, prefs.getString(_picturesKey));
      return true;
    } catch (error) {
      debugPrint('RecordStorage: could not read snapshot ($error)');
      return false;
    }
  }

  void _applyPictures(RecordManager db, String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      for (final MapEntry<String, dynamic> entry in decoded.entries) {
        final Student? student = db.studentById(entry.key);
        final String value = entry.value is String ? entry.value as String : '';
        if (student == null || value.trim().isEmpty) continue;
        student.pictureUrl = value;
      }
    } catch (error) {
      debugPrint('RecordStorage: could not read pictures ($error)');
    }
  }

  /// Coalesces rapid changes (one tap attendance, typing) into one write.
  void scheduleSave(RecordManager db) {
    if (_prefs == null) return;
    _timer?.cancel();
    _timer = Timer(_debounce, () => unawaited(save(db)));
  }

  /// Writes the current state immediately.
  Future<void> save(RecordManager db) async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;
    _timer?.cancel();
    _timer = null;

    try {
      await prefs.setString(
        _recordsKey,
        jsonEncode(<String, Object?>{
          'version': schemaVersion,
          'sections': db.sections
              .map(
                (Section s) => <String, Object?>{
                  'id': s.id,
                  'name': s.name,
                  'adviser': s.adviser,
                },
              )
              .toList(),
          'categories': db.categories
              .map(
                (Category c) => <String, Object?>{
                  'id': c.id,
                  'name': c.name,
                  'maxScore': c.maxScore,
                  'kind': c.kind.name,
                },
              )
              .toList(),
          'students': db.students.map(_studentToJson).toList(),
        }),
      );
    } catch (error) {
      debugPrint('RecordStorage: could not save records ($error)');
    }

    try {
      final Map<String, String> pictures = <String, String>{
        for (final Student s in db.students)
          if (s.pictureUrl.trim().isNotEmpty) s.id: s.pictureUrl,
      };
      await prefs.setString(_picturesKey, jsonEncode(pictures));
    } catch (error) {
      debugPrint('RecordStorage: could not save pictures ($error)');
    }
  }

  /// Drops every stored value so the next start shows the sample data again.
  Future<void> clear() async {
    _timer?.cancel();
    _timer = null;
    try {
      await _prefs?.remove(_recordsKey);
      await _prefs?.remove(_picturesKey);
    } catch (error) {
      debugPrint('RecordStorage: could not clear snapshot ($error)');
    }
  }

  /// Student records never store the picture inline: the bytes live in the
  /// separate picture key so a big image cannot block the rest of the save.
  Map<String, Object?> _studentToJson(Student student) => <String, Object?>{
        'id': student.id,
        'studentNumber': student.studentNumber,
        'fullName': student.fullName,
        'age': student.age,
        'gender': student.gender,
        'sectionId': student.sectionId,
        'contact': student.contact,
        'scores': student.scores
            .map(
              (ScoreEntry s) => <String, Object?>{
                'categoryId': s.categoryId,
                'score': s.score,
                'maxScore': s.maxScore,
              },
            )
            .toList(),
        'attendance': student.attendance
            .map(
              (AttendanceEntry a) => <String, Object?>{
                'date': a.date.toIso8601String(),
                'status': a.status.name,
              },
            )
            .toList(),
      };

  // ----- Small JSON helpers ---------------------------------------------

  List<T> _readList<T>(Object? raw, T Function(Map<String, dynamic>) build) {
    if (raw is! List) return <T>[];
    final List<T> result = <T>[];
    for (final Object? item in raw) {
      if (item is Map<String, dynamic>) {
        try {
          result.add(build(item));
        } catch (error) {
          debugPrint('RecordStorage: skipped a record ($error)');
        }
      }
    }
    return result;
  }

  static String _text(Object? value) => value is String ? value : '';

  static double _number(Object? value) =>
      value is num ? value.toDouble() : 0;

  static int _integer(Object? value) =>
      value is num ? value.toInt() : 0;
}
