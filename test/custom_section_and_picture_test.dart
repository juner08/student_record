import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_record/data/record_manager.dart';
import 'package:student_record/data/record_storage.dart';
import 'package:student_record/main.dart';
import 'package:student_record/models/attendance.dart';
import 'package:student_record/models/section.dart';
import 'package:student_record/models/student.dart';
import 'package:student_record/utils/picture_service.dart';
import 'package:student_record/widgets/student_picture.dart';

/// A real 1x1 PNG so the decoder path is exercised for real.
const String kPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
    'hQGAhKmMIQAAAABJRU5ErkJggg==';

Uint8List _pngBytes() => base64Decode(kPngBase64);

String _dataUri() => '${PictureService.dataUriPrefix}$kPngBase64';

/// Hands the picker a fixed image so the upload flow can be tested without a
/// device camera.
class _FakeImagePicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      XFile.fromData(_pngBytes(), name: 'student.png', mimeType: 'image/png');
}

Future<void> pumpApp(
  WidgetTester tester, {
  Size size = const Size(420, 1100),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const StudentRecordApp());
  await tester.pumpAndSettle();
}

/// Scrolls a widget into view before tapping it.
Future<void> tapText(WidgetTester tester, Finder finder) async {
  final Finder target = finder.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Waits for the picture picker to finish.
///
/// Reading the file and resizing it uses the real image decoder, so the test
/// has to give the real event loop a chance to run before pumping frames.
Future<void> waitForPicture(WidgetTester tester) async {
  for (int i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
  fail('the picture picker never finished');
}

/// Taps "Choose photo" and waits until the preview has the new picture.
Future<void> uploadPicture(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('pick-picture-gallery')));
  await tester.pump();
  await waitForPicture(tester);
  await tester.pumpAndSettle();
}

/// Creates a section through the UI, exactly like a user would.
Future<void> createSection(WidgetTester tester, String name) async {
  await tester.tap(find.text('Create Section'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey<String>('field-section-name')),
    name,
  );
  await tapText(tester, find.text('Save Section'));
}

void main() {
  setUp(() {
    RecordManager.instance.loadSampleData();
  });

  group('Custom section names', () {
    test('a section keeps the exact name the user typed', () {
      final RecordManager db = RecordManager.instance;
      for (final String name in <String>[
        'BSCS 3A',
        'BSIT 2A',
        'STEM 12-A',
        'Section Jupiter',
        'BSED 1 - Group 3',
      ]) {
        final Section section = db.addSection(name: name);
        expect(section.name, name);
      }
      expect(db.sections.length, 3 + 5);
    });

    test('extra spaces are collapsed but the name is not uppercased', () {
      final RecordManager db = RecordManager.instance;
      final Section section = db.addSection(name: '  Section   Jupiter  ');
      expect(section.name, 'Section Jupiter');
    });

    test('duplicate custom names are still rejected, case insensitively', () {
      final RecordManager db = RecordManager.instance;
      final Section section = db.addSection(name: 'Section Jupiter');
      expect(db.sectionNameExists('section jupiter'), isTrue);
      expect(db.sectionNameExists('SECTION JUPITER'), isTrue);
      expect(db.sectionNameExists('Section Jupiter', ignoreId: section.id),
          isFalse);
    });

    test('a custom section can be renamed', () {
      final RecordManager db = RecordManager.instance;
      final Section section = db.addSection(name: 'Section Jupiter');
      db.updateSection(section, name: 'Section Saturn', adviser: 'Prof. X');
      expect(section.name, 'Section Saturn');
      expect(section.adviser, 'Prof. X');
      expect(db.sectionNameExists('Section Saturn'), isTrue);
    });

    testWidgets('a brand new custom section shows up in the list',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await createSection(tester, 'Section Jupiter');

      expect(
        RecordManager.instance.sections.any(
          (Section s) => s.name == 'Section Jupiter',
        ),
        isTrue,
      );
      expect(find.text('Section Jupiter'), findsOneWidget);
    });

    testWidgets('a second custom section can be created too',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await createSection(tester, 'Section Jupiter');
      await createSection(tester, 'STEM 12-A');

      expect(find.text('Section Jupiter'), findsOneWidget);
      expect(find.text('STEM 12-A'), findsOneWidget);
      expect(find.text('5 sections'), findsOneWidget);
    });

    testWidgets('the new section is offered when adding a student',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await createSection(tester, 'Section Jupiter');

      await tapText(tester, find.text('Section Jupiter'));
      await tapText(tester, find.text('Add Student'));
      await tapText(
        tester,
        find.byKey(const ValueKey<String>('field-section')),
      );
      expect(find.text('Section Jupiter'), findsWidgets);
    });

    testWidgets('a student can be saved into the new custom section',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await createSection(tester, 'Section Jupiter');

      final Section section = RecordManager.instance.sections
          .firstWhere((Section s) => s.name == 'Section Jupiter');

      await tapText(tester, find.text('Section Jupiter'));
      await tapText(tester, find.text('Add Student'));
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-number')),
        '2024-55555',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-name')),
        'Luna Villanueva',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-age')),
        '20',
      );
      await tapText(
        tester,
        find.byKey(const ValueKey<String>('field-gender')),
      );
      await tapText(tester, find.text('Female').last);
      await tapText(tester, find.text('Save Student'));

      final List<Student> students =
          RecordManager.instance.studentsOf(section.id);
      expect(students.length, 1);
      expect(students.single.fullName, 'Luna Villanueva');
      expect(students.single.sectionId, section.id);
      // And the section shows the new student on its card.
      expect(find.text('Luna Villanueva'), findsOneWidget);
    });
  });

  group('Student profile picture', () {
    test('a picked image is turned into a storable value', () async {
      useFakePicker(_FakeImagePicker());

      final PicturePickResult result =
          await PictureService.instance.pick(ImageSource.gallery);

      expect(result.error, isNull);
      expect(result.isCancelled, isFalse);
      final String value = result.value!;
      expect(PictureService.isUploaded(value), isTrue);
      expect(PictureService.isDisplayable(value), isTrue);
      expect(PictureService.decode(value), isNotNull);
    });

    test('cancelling the picker leaves the picture untouched', () async {
      useFakePicker(_CancelledPicker());

      final PicturePickResult result =
          await PictureService.instance.pick(ImageSource.gallery);
      expect(result.isCancelled, isTrue);
      expect(result.value, isNull);
    });

    test('a missing or broken picture value is handled without throwing', () {
      expect(PictureService.isDisplayable(''), isFalse);
      expect(PictureService.isDisplayable('not a picture'), isFalse);
      expect(PictureService.isDisplayable('C:\\photos\\me.png'), isFalse);
      expect(PictureService.isDisplayable('data:image/png;base64,%%%'), isFalse);
      expect(PictureService.decode('data:image/png;base64'), isNull);
      expect(PictureService.decode('https://example.com/a.png'), isNull);
      expect(PictureService.isDisplayable('https://example.com/a.png'), isTrue);
    });

    test('the image type is read from the file itself', () {
      expect(PictureService.mimeOf(_pngBytes()), 'png');
      expect(
        PictureService.mimeOf(Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0])),
        'jpeg',
      );
      expect(
        PictureService.mimeOf(Uint8List.fromList(<int>[0x47, 0x49, 0x46, 0x38])),
        'gif',
      );
      expect(PictureService.mimeOf(Uint8List.fromList(<int>[1, 2, 3])), isNull);
    });

    test('bytes that are not an image are rejected', () async {
      final PicturePickResult result = await PictureService.instance.encode(
        Uint8List.fromList(List<int>.filled(64, 7)),
      );
      expect(result.value, isNull);
      expect(result.error, 'That file is not a valid image.');
    });

    testWidgets('a student without a picture still renders its initials',
        (WidgetTester tester) async {
      final RecordManager db = RecordManager.instance;
      final Student student = db.addStudent(
        studentNumber: '2024-1',
        fullName: 'Noel Pictures',
        age: 20,
        gender: 'Male',
        sectionId: 's_bscs3a',
      );
      expect(student.pictureUrl, '');

      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tester.enterText(find.byType(TextField).first, 'Noel');
      await tester.pumpAndSettle();

      expect(find.text('Noel Pictures'), findsOneWidget);
      expect(find.text('NP'), findsOneWidget);
    });

    testWidgets('an uploaded picture is shown on the student record',
        (WidgetTester tester) async {
      final RecordManager db = RecordManager.instance;
      final Student student = db.addStudent(
        studentNumber: '2024-2',
        fullName: 'Pia Uploaded',
        age: 21,
        gender: 'Female',
        sectionId: 's_bscs3a',
        pictureUrl: _dataUri(),
      );

      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tester.enterText(find.byType(TextField).first, 'Pia');
      await tester.pumpAndSettle();

      final Finder card =
          find.byKey(ValueKey<String>('student-${student.id}'));
      expect(
        find.descendant(of: card, matching: find.byType(StudentPicture)),
        findsOneWidget,
      );
      // The picture is rendered, so the initials badge is not used.
      expect(find.descendant(of: card, matching: find.byType(Image)),
          findsOneWidget);

      await tapText(tester, find.text('Pia Uploaded'));
      expect(find.byType(StudentPicture), findsWidgets);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('a broken picture link never breaks the student page',
        (WidgetTester tester) async {
      final RecordManager db = RecordManager.instance;
      db.addStudent(
        studentNumber: '2024-3',
        fullName: 'Bad Picture',
        age: 22,
        gender: 'Male',
        sectionId: 's_bscs3a',
        pictureUrl: 'C:\\pictures\\missing.png',
      );

      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tester.enterText(find.byType(TextField).first, 'Bad');
      await tester.pumpAndSettle();

      expect(find.text('Bad Picture'), findsOneWidget);
      // Falls back to the initials badge instead of a broken image.
      expect(find.text('BP'), findsOneWidget);

      await tapText(tester, find.text('Bad Picture'));
      expect(find.text('Overall Average'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uploading a picture previews it and saves it with the student',
        (WidgetTester tester) async {
      useFakePicker(_FakeImagePicker());

      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tapText(tester, find.text('Add Student'));

      // No picture yet: the placeholder is shown.
      expect(find.byKey(const ValueKey<String>('picture-preview')),
          findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('picture-preview')),
          matching: find.byType(Image),
        ),
        findsNothing,
      );

      await uploadPicture(tester);

      // Preview now renders the uploaded image, before saving.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('picture-preview')),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('field-number')),
        '2024-30001',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-name')),
        'Uploaded Person',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('field-age')),
        '23',
      );
      await tapText(
        tester,
        find.byKey(const ValueKey<String>('field-gender')),
      );
      await tapText(tester, find.text('Other').last);
      await tapText(tester, find.text('Save Student'));

      final Student student = RecordManager.instance
          .studentsOf('s_bscs3a')
          .firstWhere((Student s) => s.fullName == 'Uploaded Person');
      expect(PictureService.isUploaded(student.pictureUrl), isTrue);
      expect(PictureService.decode(student.pictureUrl), isNotNull);

      // The picture is on the student record.
      await tester.enterText(find.byType(TextField).first, 'Uploaded');
      await tester.pumpAndSettle();
      expect(find.byType(StudentPicture), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('editing a student can replace the picture',
        (WidgetTester tester) async {
      useFakePicker(_FakeImagePicker());
      final RecordManager db = RecordManager.instance;
      final Student student = db.addStudent(
        studentNumber: '2024-4',
        fullName: 'Change Picture',
        age: 20,
        gender: 'Male',
        sectionId: 's_bscs3a',
        pictureUrl: 'https://example.com/old.png',
      );

      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tester.enterText(find.byType(TextField).first, 'Change');
      await tester.pumpAndSettle();

      final Finder card =
          find.byKey(ValueKey<String>('student-${student.id}'));
      await tapText(
        tester,
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.more_vert),
        ),
      );
      await tapText(tester, find.text('Edit'));

      // The existing link is shown in the field and used by the preview.
      expect(find.text('Using the picture from the link below.'),
          findsOneWidget);

      // Replace it with a freshly uploaded picture.
      await uploadPicture(tester);
      expect(
        find.textContaining('Picture uploaded.'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('picture-preview')),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );

      await tapText(tester, find.text('Update'));

      expect(student.pictureUrl, isNot('https://example.com/old.png'));
      expect(PictureService.isUploaded(student.pictureUrl), isTrue);
      expect(PictureService.decode(student.pictureUrl), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a picture can be removed again', (WidgetTester tester) async {
      final RecordManager db = RecordManager.instance;
      final Student student = db.addStudent(
        studentNumber: '2024-5',
        fullName: 'Removable Picture',
        age: 20,
        gender: 'Male',
        sectionId: 's_bscs3a',
        pictureUrl: _dataUri(),
      );

      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tester.enterText(find.byType(TextField).first, 'Removable');
      await tester.pumpAndSettle();
      await tapText(tester, find.text('Removable Picture'));
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('picture-preview')),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      await tapText(tester, find.byKey(const ValueKey<String>('remove-picture')));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('picture-preview')),
          matching: find.byType(Image),
        ),
        findsNothing,
      );

      await tapText(tester, find.text('Update'));
      expect(student.pictureUrl, '');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the picture link field still works as before',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await tapText(tester, find.text('BSCS 3A'));
      await tapText(tester, find.text('Add Student'));

      await tester.enterText(
        find.byKey(const ValueKey<String>('field-picture')),
        'https://example.com/me.png',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('picture-preview')),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('field-picture')),
        'not-a-link',
      );
      await tapText(tester, find.text('Save Student'));
      expect(find.text('Picture link must start with http'), findsOneWidget);
    });

    testWidgets('the picture card fits a small phone screen',
        (WidgetTester tester) async {
      await pumpApp(tester, size: const Size(320, 640));
      await tapText(tester, find.text('BSCS 3A'));
      await tapText(tester, find.text('Add Student'));
      expect(find.byKey(const ValueKey<String>('picture-preview')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Saved data survives a refresh', () {
    test('sections, students and pictures are restored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await RecordStorage.instance.init();

      final RecordManager db = RecordManager.instance;
      db.loadSampleData();
      final Section section = db.addSection(
        name: 'Section Jupiter',
        adviser: 'Prof. Dela Cruz',
      );
      final Student student = db.addStudent(
        studentNumber: '2024-90001',
        fullName: 'Persisted Person',
        age: 21,
        gender: 'Female',
        sectionId: section.id,
        contact: '0917 555 0111',
        pictureUrl: _dataUri(),
      );
      student.setScore('c_quiz1', 17, 20);
      student.setAttendance(DateTime(2024, 5, 6), AttendanceStatus.excused);

      await RecordStorage.instance.save(db);

      // Simulate a page refresh / app restart: memory is gone, storage is not.
      db.replaceAll(sections: <Section>[], students: <Student>[], categories: []);
      expect(db.sections, isEmpty);
      expect(RecordStorage.instance.restore(db), isTrue);

      final Section? restoredSection = db.sectionById(section.id);
      expect(restoredSection, isNotNull);
      expect(restoredSection!.name, 'Section Jupiter');
      expect(restoredSection.adviser, 'Prof. Dela Cruz');

      final Student? restoredStudent = db.studentById(student.id);
      expect(restoredStudent, isNotNull);
      expect(restoredStudent!.fullName, 'Persisted Person');
      expect(restoredStudent.sectionId, section.id);
      expect(restoredStudent.scoreFor('c_quiz1')?.score, 17);
      expect(restoredStudent.countOf(AttendanceStatus.excused), 1);
      // The uploaded picture is still valid after the restart.
      expect(restoredStudent.pictureUrl, _dataUri());
      expect(PictureService.decode(restoredStudent.pictureUrl), isNotNull);

      await RecordStorage.instance.clear();
    });

    test('a missing or unreadable snapshot falls back to the sample data',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await RecordStorage.instance.init();

      final RecordManager db = RecordManager.instance;
      expect(RecordStorage.instance.restore(db), isFalse);

      SharedPreferences.setMockInitialValues(<String, Object>{
        'student_record.records.v1': 'this is not json',
        'student_record.pictures.v1': 'neither is this',
      });
      await RecordStorage.instance.init();
      expect(RecordStorage.instance.restore(db), isFalse);

      db.loadSampleData();
      expect(db.sections.length, 3);
      await RecordStorage.instance.clear();
    });
  });
}

/// Stands in for the user closing the system photo picker.
class _CancelledPicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      null;
}

/// Swaps in a fake picker for the duration of one test.
void useFakePicker(ImagePickerPlatform picker) {
  final ImagePickerPlatform original = ImagePickerPlatform.instance;
  ImagePickerPlatform.instance = picker;
  addTearDown(() => ImagePickerPlatform.instance = original);
}
