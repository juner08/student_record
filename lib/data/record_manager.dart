import '../models/attendance.dart';
import '../models/score.dart';
import '../models/section.dart';
import '../models/student.dart';
import 'record_storage.dart';
import 'sample_data.dart';

/// Simple dashboard numbers for one section on one date.
class SectionStats {
  SectionStats({
    required this.total,
    required this.present,
    required this.absent,
    required this.excused,
    required this.average,
  });

  final int total;
  final int present;
  final int absent;
  final int excused;
  final double average;

  String get averageLabel => total == 0 ? '--' : '${average.toStringAsFixed(1)}%';
}

/// In-memory store. Everything lives in plain List / Map objects that are
/// created when the app starts - no database is used in this project.
class RecordManager {
  RecordManager._();

  static final RecordManager instance = RecordManager._();

  final List<Section> sections = <Section>[];
  final List<Student> students = <Student>[];
  final List<Category> categories = <Category>[];

  int _counter = 0;

  void loadSampleData() {
    sections.clear();
    students.clear();
    categories.clear();
    _counter = 0;
    final SampleData data = buildSampleData();
    sections.addAll(data.sections);
    students.addAll(data.students);
    categories.addAll(data.categories);
  }

  /// Replaces everything with the given lists. Used when the saved snapshot is
  /// read back at start-up.
  void replaceAll({
    required List<Section> sections,
    required List<Student> students,
    required List<Category> categories,
  }) {
    this.sections
      ..clear()
      ..addAll(sections);
    this.students
      ..clear()
      ..addAll(students);
    this.categories
      ..clear()
      ..addAll(categories);
    _counter = 0;
  }

  /// Remembers the change so it survives an app restart / page refresh.
  void save() => RecordStorage.instance.scheduleSave(this);

  String _newId(String prefix) {
    _counter++;
    return '$prefix${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }

  // ----- Sections -------------------------------------------------------

  bool sectionNameExists(String name, {String? ignoreId}) {
    final String target = _clean(name);
    if (target.isEmpty) return false;
    for (final Section section in sections) {
      if (_clean(section.name) == target && section.id != ignoreId) return true;
    }
    return false;
  }

  /// Creates a section from any name the user typed. The text is kept exactly
  /// as entered (only surrounding spaces are removed) so custom names such as
  /// "BSCS 3A", "STEM 12-A" or "Section Jupiter" stay readable.
  Section addSection({required String name, String adviser = ''}) {
    final Section section = Section(
      id: _newId('sec_'),
      name: name.trim().replaceAll(RegExp(r'\s+'), ' '),
      adviser: adviser.trim(),
    );
    sections.add(section);
    save();
    return section;
  }

  /// Renames a section while keeping the same rules as [addSection].
  void updateSection(
    Section section, {
    required String name,
    String? adviser,
  }) {
    section
      ..name = name.trim().replaceAll(RegExp(r'\s+'), ' ')
      ..adviser = adviser?.trim() ?? section.adviser;
    save();
  }

  void deleteSection(String id) {
    sections.removeWhere((Section s) => s.id == id);
    students.removeWhere((Student s) => s.sectionId == id);
    save();
  }

  Section? sectionById(String id) {
    for (final Section section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  String sectionNameOf(String id) => sectionById(id)?.name ?? 'Unassigned';

  // ----- Students -------------------------------------------------------

  List<Student> studentsOf(String sectionId) {
    final List<Student> list = students
        .where((Student s) => s.sectionId == sectionId)
        .toList();
    list.sort(
      (Student a, Student b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return list;
  }

  List<Student> searchStudents(String sectionId, String query) {
    final String q = query.trim().toLowerCase();
    final List<Student> list = studentsOf(sectionId);
    if (q.isEmpty) return list;
    return list
        .where(
          (Student s) =>
              s.fullName.toLowerCase().contains(q) ||
              s.studentNumber.toLowerCase().contains(q),
        )
        .toList();
  }

  bool studentNumberExists(
    String sectionId,
    String number, {
    String? ignoreId,
  }) {
    final String target = _clean(number);
    for (final Student student in students) {
      if (student.sectionId == sectionId &&
          _clean(student.studentNumber) == target &&
          student.id != ignoreId) {
        return true;
      }
    }
    return false;
  }

  Student addStudent({
    required String studentNumber,
    required String fullName,
    required int age,
    required String gender,
    required String sectionId,
    String contact = '',
    String pictureUrl = '',
  }) {
    final Student student = Student(
      id: _newId('stu_'),
      studentNumber: studentNumber.trim(),
      fullName: fullName.trim(),
      age: age,
      gender: gender,
      sectionId: sectionId,
      contact: contact.trim(),
      pictureUrl: pictureUrl.trim(),
    );
    students.add(student);
    save();
    return student;
  }

  Student? studentById(String id) {
    for (final Student student in students) {
      if (student.id == id) return student;
    }
    return null;
  }

  void deleteStudent(String id) {
    students.removeWhere((Student s) => s.id == id);
    save();
  }

  int rankOf(Student student) {
    final List<Student> list = studentsOf(student.sectionId)
      ..sort(
        (Student a, Student b) =>
            b.overallAverage.compareTo(a.overallAverage),
      );
    final int index = list.indexWhere((Student s) => s.id == student.id);
    return index == -1 ? 0 : index + 1;
  }

  // ----- Categories & scores -------------------------------------------

  Category? categoryById(String id) {
    for (final Category category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  bool categoryNameExists(String name, {String? ignoreId}) {
    final String target = _clean(name);
    for (final Category category in categories) {
      if (_clean(category.name) == target && category.id != ignoreId) return true;
    }
    return false;
  }

  Category addCategory({
    required String name,
    required double maxScore,
    required CategoryKind kind,
  }) {
    final Category category = Category(
      id: _newId('cat_'),
      name: name.trim(),
      maxScore: maxScore,
      kind: kind,
    );
    categories.add(category);
    save();
    return category;
  }

  // ----- Attendance -----------------------------------------------------

  void cycleAttendance(Student student, DateTime date) {
    student.cycleAttendance(date);
    save();
  }

  void setAttendance(Student student, DateTime date, AttendanceStatus status) {
    student.setAttendance(date, status);
    save();
  }

  // ----- Dashboard ------------------------------------------------------

  SectionStats statsFor(String sectionId, DateTime date) {
    final List<Student> list = studentsOf(sectionId);
    int present = 0;
    int absent = 0;
    int excused = 0;
    double averageSum = 0;
    int graded = 0;
    for (final Student student in list) {
      switch (student.statusOn(date)) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.excused:
          excused++;
          break;
      }
      if (student.scores.isNotEmpty) {
        averageSum += student.overallAverage;
        graded++;
      }
    }
    return SectionStats(
      total: list.length,
      present: present,
      absent: absent,
      excused: excused,
      average: graded == 0 ? 0 : averageSum / graded,
    );
  }

  static String _clean(String value) => value.trim().toLowerCase();
}