import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_record/data/record_manager.dart';
import 'package:student_record/main.dart';
import 'package:student_record/models/attendance.dart';
import 'package:student_record/models/score.dart';
import 'package:student_record/models/section.dart';
import 'package:student_record/models/student.dart';

void main() {
  setUp(() {
    RecordManager.instance.loadSampleData();
  });

  Future<void> pumpApp(WidgetTester tester,
      {Size size = const Size(420, 1000)}) async {
    // Phone-like surface so every widget used in the test is on screen.
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const StudentRecordApp());
    await tester.pumpAndSettle();
  }

/// Scrolls the widget into view before tapping it (long lists).
Future<void> tapText(WidgetTester tester, Finder finder) async {
  final Finder target = finder.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target, warnIfMissed: false);
  await tester.pumpAndSettle();
}

  group('Sample data (local List only)', () {
    test('loads sections, students and categories', () {
      final RecordManager db = RecordManager.instance;
      expect(db.sections.length, 3);
      expect(db.categories.length, 7);
      expect(db.students.length, greaterThan(5));
    });

    test('students are filtered per section', () {
      final RecordManager db = RecordManager.instance;
      final List<Student> a = db.studentsOf('s_bscs3a');
      final List<Student> b = db.studentsOf('s_bscs3b');
      expect(a, isNotEmpty);
      expect(b, isNotEmpty);
      expect(a.every((Student s) => s.sectionId == 's_bscs3a'), isTrue);
      expect(b.every((Student s) => s.sectionId == 's_bscs3b'), isTrue);
      expect(a.length != b.length, isTrue);
    });
  });

  group('Grades computation', () {
    test('overall average uses the score percentage', () {
      final Student student = Student(
        id: '1',
        studentNumber: '2024-1',
        fullName: 'Test Student',
        age: 20,
        gender: 'Male',
        sectionId: 's_bscs3a',
      );
      expect(student.overallAverage, 0);
      expect(student.averageLabel, '--');

      student.setScore('c_quiz1', 18, 20);
      student.setScore('c_exam', 45, 50);
      expect(student.overallAverage, closeTo(90, 0.001));
      expect(student.scoreFor('c_quiz1')?.display, '18/20');

      student.setScore('c_quiz1', 10, 20);
      expect(student.scores.length, 2, reason: 'score should be updated');
      expect(student.scoreFor('c_quiz1')?.score, 10);
      expect(student.overallAverage, closeTo(70, 0.001));
    });

    test('dashboard numbers of a section add up', () {
      final RecordManager db = RecordManager.instance;
      final SectionStats stats = db.statsFor('s_bscs3a', DateTime.now());
      expect(stats.present + stats.absent + stats.excused, stats.total);
      expect(stats.total, db.studentsOf('s_bscs3a').length);
      expect(stats.average, greaterThan(0));
    });
  });

  group('One-tap attendance', () {
    test('cycles PRESENT -> ABSENT -> EXCUSED -> PRESENT', () {
      final Student student = Student(
        id: '1',
        studentNumber: '2024-1',
        fullName: 'Test Student',
        age: 20,
        gender: 'Male',
        sectionId: 's_bscs3a',
      );
      final DateTime date = DateTime(2024, 1, 8);

      expect(student.statusOn(date), AttendanceStatus.present);
      student.cycleAttendance(date);
      expect(student.statusOn(date), AttendanceStatus.absent);
      student.cycleAttendance(date);
      expect(student.statusOn(date), AttendanceStatus.excused);
      student.cycleAttendance(date);
      expect(student.statusOn(date), AttendanceStatus.present);
      expect(student.attendance.length, 1,
          reason: 'same day is updated, not duplicated');
    });

    test('records the date of the attendance', () {
      final Student student = Student(
        id: '1',
        studentNumber: '2024-1',
        fullName: 'Test Student',
        age: 20,
        gender: 'Male',
        sectionId: 's_bscs3a',
      );
      student.setAttendance(DateTime(2024, 3, 4), AttendanceStatus.absent);
      expect(student.attendance.first.date, DateTime(2024, 3, 4));
      expect(student.countOf(AttendanceStatus.absent), 1);
    });
  });

  group('Validation helpers (RecordManager rules)', () {
    test('section name must be unique', () {
      final RecordManager db = RecordManager.instance;
      expect(db.sectionNameExists('BSCS 3A'), isTrue);
      expect(db.sectionNameExists(' bsC3a '), isFalse);
      expect(db.sectionNameExists('BSCS 3Z'), isFalse);
      expect(db.sectionNameExists('BSCS 3A', ignoreId: 's_bscs3a'), isFalse);
    });

    test('student number must be unique inside a section', () {
      final RecordManager db = RecordManager.instance;
      expect(db.studentNumberExists('s_bscs3a', '2021-01234'), isTrue);
      expect(db.studentNumberExists('s_bscs3b', '2021-01234'), isFalse);
    });

    test('new student is added to the currently selected section', () {
      final RecordManager db = RecordManager.instance;
      final int before = db.studentsOf('s_bscs3b').length;
      db.addStudent(
        studentNumber: '2021-09999',
        fullName: 'New Student',
        age: 21,
        gender: 'Female',
        sectionId: 's_bscs3b',
      );
      expect(db.studentsOf('s_bscs3b').length, before + 1);
    });

    test('category can be added and used for scoring', () {
      final RecordManager db = RecordManager.instance;
      final Category category = db.addCategory(
        name: 'Quiz 4',
        maxScore: 25,
        kind: CategoryKind.quiz,
      );
      expect(db.categories.length, 8);
      final Student student = db.studentsOf('s_bscs3a').first;
      final double before = student.overallAverage;
      student.setScore(category.id, 20, 25);
      expect(student.overallAverage, isNot(before));
    });
  });

  group('Navigation', () {
    testWidgets('home shows sections and opens the student list',
        (WidgetTester tester) async {
      await pumpApp(tester);

      expect(find.text('BSCS 3A'), findsOneWidget);
      expect(find.text('BSIT 3A'), findsOneWidget);

      await tester.tap(find.text('BSCS 3A'));
      await tester.pumpAndSettle();

      expect(find.text('Class Dashboard'), findsOneWidget);
      expect(find.text('Juan Dela Cruz'), findsOneWidget);
      // Students of other sections must not be visible.
      expect(find.text('Kevin Uy'), findsNothing);
    });

    testWidgets('section search filters the grid', (WidgetTester tester) async {
      await pumpApp(tester);
      await tester.enterText(find.byType(TextField).first, 'BSIT');
      await tester.pumpAndSettle();
      expect(find.text('BSIT 3A'), findsOneWidget);
      expect(find.text('BSCS 3A'), findsNothing);
    });

    testWidgets('one tap on the status chip changes attendance',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('BSCS 3A'));
      await tester.pumpAndSettle();

      final Student student = RecordManager.instance
          .studentsOf('s_bscs3a')
          .firstWhere((Student s) => s.fullName == 'Juan Dela Cruz');
      expect(student.todayStatus, AttendanceStatus.present);

      final Finder card = find.byKey(ValueKey<String>('student-${student.id}'));

      await tapText(
        tester,
        find.descendant(of: card, matching: find.text('PRESENT')),
      );
      expect(student.todayStatus, AttendanceStatus.absent);

      await tapText(
        tester,
        find.descendant(of: card, matching: find.text('ABSENT')),
      );
      expect(student.todayStatus, AttendanceStatus.excused);

      await tapText(
        tester,
        find.descendant(of: card, matching: find.text('EXCUSED')),
      );
      expect(student.todayStatus, AttendanceStatus.present);
    });

    testWidgets('student detail shows grades, attendance and profile tabs',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tapText(tester, find.text('Juan Dela Cruz'));

      expect(find.text('Overall Average'), findsOneWidget);
      expect(find.text('Scores by category'), findsOneWidget);
      expect(find.text('Quiz 1'), findsOneWidget);

      await tapText(tester, find.text('Attendance'));
      expect(find.text('Attendance history'), findsOneWidget);

      await tapText(tester, find.text('Profile'));
      expect(find.text('Student profile'), findsOneWidget);
      expect(find.text('Class ranking'), findsOneWidget);
    });

    testWidgets('records screen lists every student of the section',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tester.tap(find.byIcon(Icons.assessment_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Class Records'), findsOneWidget);
      expect(find.text('Per student record'), findsOneWidget);
    });

    testWidgets('layout works on a small phone screen (no overflow)',
        (WidgetTester tester) async {
      await pumpApp(tester, size: const Size(320, 640));
      expect(find.text('BSCS 3A'), findsOneWidget);
      await tapText(tester, find.text('BSCS 3A'));
      expect(find.text('Class Dashboard'), findsOneWidget);
      expect(find.text('Add Student'), findsOneWidget);
    });

    testWidgets('layout works on a tablet width (grid view)',
        (WidgetTester tester) async {
      await pumpApp(tester, size: const Size(1000, 700));
      expect(find.text('BSCS 3A'), findsOneWidget);
      expect(find.text('BSCS 3B'), findsOneWidget);
      await tapText(tester, find.text('BSIT 3A'));
      expect(find.text('Class Dashboard'), findsOneWidget);
    });
  });

  group('Forms', () {
    testWidgets('section form validates the name field',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Create Section'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Section'));
      await tester.pumpAndSettle();
      expect(find.text('Section name is required'), findsOneWidget);

      // Duplicate name is not allowed.
      await tester.enterText(find.byType(TextFormField).first, 'BSCS 3A');
      await tester.tap(find.text('Save Section'));
      await tester.pumpAndSettle();
      expect(find.text('Section already exists'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'BSIS 4C');
      await tester.tap(find.text('Save Section'));
      await tester.pumpAndSettle();
      expect(
        RecordManager.instance
            .sections
            .any((Section s) => s.name == 'BSIS 4C'),
        isTrue,
      );
    });

    testWidgets('student form validates fields and saves a new student',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tapText(tester, find.text('Add Student'));

      await tapText(tester, find.text('Save Student'));
      expect(find.text('Student ID is required'), findsOneWidget);
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Age is required'), findsOneWidget);
      expect(find.text('Please choose a gender'), findsOneWidget);

      // Duplicate student number inside the same section.
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-number')),
        '2021-01234',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-name')),
        'Pepito Ramos',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-age')),
        '20',
      );
      await tapText(tester, find.text('Save Student'));
      expect(
        find.text('This student ID already exists in the section'),
        findsOneWidget,
      );

      // Invalid age.
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-number')),
        '2021-07777',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-age')),
        'abc',
      );
      await tapText(tester, find.text('Save Student'));
      expect(find.text('Age must be a number'), findsOneWidget);

      // Valid entry.
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-age')),
        '21',
      );
      await tapText(
        tester,
        find.byKey(const ValueKey<String>('field-gender')),
      );
      await tapText(tester, find.text('Female').last);

      await tapText(tester, find.text('Save Student'));

      final List<Student> students = RecordManager.instance.studentsOf('s_bscs3a');
      expect(
        students.any((Student s) => s.fullName == 'Pepito Ramos'),
        isTrue,
      );
      expect(
        students.firstWhere((Student s) => s.fullName == 'Pepito Ramos')
            .sectionId,
        's_bscs3a',
      );

      // The new student is visible in the list of the selected section.
      await tester.enterText(find.byType(TextField).first, 'Pepito');
      await tester.pumpAndSettle();
      expect(find.text('Pepito Ramos'), findsOneWidget);
    });

    testWidgets('score form rejects a score higher than the total',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      // The search field filters the list of students.
      await tester.enterText(find.byType(TextField).first, 'Maria');
      await tester.pumpAndSettle();
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('Juan Dela Cruz'), findsNothing);

      await tapText(tester, find.text('Maria Santos'));
      await tapText(tester, find.text('Add / edit score'));

      await tapText(
        tester,
        find.byKey(const ValueKey<String>('field-category')),
      );
      await tapText(tester, find.textContaining('Quiz 2').last);

      await tester.enterText(
        find.byKey(const ValueKey<String>('field-score')),
        '25',
      );
      await tapText(tester, find.text('Save Score'));
      expect(find.text('Score cannot be higher than the total'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('field-score')),
        '19',
      );
      await tapText(tester, find.text('Save Score'));

      final Student student = RecordManager.instance.studentsOf('s_bscs3a')
          .firstWhere((Student s) => s.fullName == 'Maria Santos');
      expect(student.scoreFor('c_quiz2')?.score, 19);
    });

    testWidgets('a new score category can be created while scoring',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tester.enterText(find.byType(TextField).first, 'Maria');
      await tester.pumpAndSettle();
      await tapText(tester, find.text('Maria Santos'));
      await tapText(tester, find.text('Add / edit score'));

      await tapText(tester, find.text('Create new category'));

      // Required field validation inside the dialog.
      await tapText(tester, find.text('Add'));
      expect(find.text('Category name is required'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('field-category-name')),
        'Quiz 4',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-category-max')),
        '25',
      );
      await tapText(tester, find.text('Add'));
      await tester.pumpAndSettle();

      expect(RecordManager.instance.categories.length, 8);
      expect(
        RecordManager.instance.categoryById(
          RecordManager.instance.categories.last.id,
        )?.name,
        'Quiz 4',
      );
      expect(find.text('Quiz 4 (/25)'), findsOneWidget);
    });
  });
}