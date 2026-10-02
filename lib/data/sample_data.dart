import '../models/attendance.dart';
import '../models/score.dart';
import '../models/section.dart';
import '../models/student.dart';

class SampleData {
  SampleData({
    required this.sections,
    required this.students,
    required this.categories,
  });

  final List<Section> sections;
  final List<Student> students;
  final List<Category> categories;
}

SampleData buildSampleData() {
  final List<Category> categories = <Category>[
    Category(id: 'c_quiz1', name: 'Quiz 1', maxScore: 20, kind: CategoryKind.quiz),
    Category(id: 'c_quiz2', name: 'Quiz 2', maxScore: 20, kind: CategoryKind.quiz),
    Category(id: 'c_quiz3', name: 'Quiz 3', maxScore: 20, kind: CategoryKind.quiz),
    Category(id: 'c_exam', name: 'Exam', maxScore: 50, kind: CategoryKind.exam),
    Category(
      id: 'c_activity',
      name: 'Activity',
      maxScore: 30,
      kind: CategoryKind.activity,
    ),
    Category(
      id: 'c_assignment',
      name: 'Assignment',
      maxScore: 20,
      kind: CategoryKind.assignment,
    ),
    Category(
      id: 'c_project',
      name: 'Project',
      maxScore: 100,
      kind: CategoryKind.project,
    ),
  ];

  final List<Section> sections = <Section>[
    Section(id: 's_bscs3a', name: 'BSCS 3A', adviser: 'Prof. Ramon Dela Cruz'),
    Section(id: 's_bscs3b', name: 'BSCS 3B', adviser: 'Prof. Liza Mendoza'),
    Section(id: 's_bsit3a', name: 'BSIT 3A', adviser: 'Engr. Paolo Santos'),
  ];

  final DateTime today = DateTime.now();
  DateTime dayAgo(int days) =>
      DateTime(today.year, today.month, today.day - days);

  final List<Student> students = <Student>[
    Student(
      id: 'st_001',
      studentNumber: '2021-01234',
      fullName: 'Juan Dela Cruz',
      age: 20,
      gender: 'Male',
      sectionId: 's_bscs3a',
      contact: '0917 555 0142',
      pictureUrl: 'https://i.pravatar.cc/200?img=12',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 18, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 17, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz3', score: 19, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 45, maxScore: 50),
        ScoreEntry(categoryId: 'c_activity', score: 28, maxScore: 30),
        ScoreEntry(categoryId: 'c_assignment', score: 18, maxScore: 20),
        ScoreEntry(categoryId: 'c_project', score: 92, maxScore: 100),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(1), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(2), status: AttendanceStatus.excused),
        AttendanceEntry(date: dayAgo(3), status: AttendanceStatus.present),
      ],
    ),
    Student(
      id: 'st_002',
      studentNumber: '2021-01235',
      fullName: 'Maria Santos',
      age: 19,
      gender: 'Female',
      sectionId: 's_bscs3a',
      contact: '0918 555 0177',
      pictureUrl: 'https://i.pravatar.cc/200?img=32',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 20, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 19, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz3', score: 20, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 48, maxScore: 50),
        ScoreEntry(categoryId: 'c_activity', score: 29, maxScore: 30),
        ScoreEntry(categoryId: 'c_assignment', score: 20, maxScore: 20),
        ScoreEntry(categoryId: 'c_project', score: 95, maxScore: 100),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(1), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(2), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(3), status: AttendanceStatus.absent),
      ],
    ),
    Student(
      id: 'st_003',
      studentNumber: '2021-01236',
      fullName: 'Angelo Reyes',
      age: 20,
      gender: 'Male',
      sectionId: 's_bscs3a',
      contact: '0919 555 0110',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 15, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 14, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz3', score: 16, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 38, maxScore: 50),
        ScoreEntry(categoryId: 'c_activity', score: 24, maxScore: 30),
        ScoreEntry(categoryId: 'c_assignment', score: 16, maxScore: 20),
        ScoreEntry(categoryId: 'c_project', score: 80, maxScore: 100),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.absent),
        AttendanceEntry(date: dayAgo(1), status: AttendanceStatus.absent),
        AttendanceEntry(date: dayAgo(2), status: AttendanceStatus.present),
      ],
    ),
    Student(
      id: 'st_004',
      studentNumber: '2021-01237',
      fullName: 'Kristine Bautista',
      age: 19,
      gender: 'Female',
      sectionId: 's_bscs3a',
      contact: '0920 555 0198',
      pictureUrl: 'https://i.pravatar.cc/200?img=47',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 19, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 18, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 44, maxScore: 50),
        ScoreEntry(categoryId: 'c_activity', score: 27, maxScore: 30),
        ScoreEntry(categoryId: 'c_assignment', score: 19, maxScore: 20),
        ScoreEntry(categoryId: 'c_project', score: 90, maxScore: 100),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.excused),
        AttendanceEntry(date: dayAgo(1), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(2), status: AttendanceStatus.present),
      ],
    ),
    Student(
      id: 'st_005',
      studentNumber: '2021-01238',
      fullName: 'Miguel Torres',
      age: 21,
      gender: 'Male',
      sectionId: 's_bscs3a',
      contact: '0921 555 0165',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 16, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 17, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz3', score: 15, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 41, maxScore: 50),
        ScoreEntry(categoryId: 'c_activity', score: 26, maxScore: 30),
        ScoreEntry(categoryId: 'c_assignment', score: 17, maxScore: 20),
        ScoreEntry(categoryId: 'c_project', score: 85, maxScore: 100),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(1), status: AttendanceStatus.present),
      ],
    ),
    Student(
      id: 'st_006',
      studentNumber: '2021-01239',
      fullName: 'Grace Lim',
      age: 20,
      gender: 'Female',
      sectionId: 's_bscs3a',
      contact: '0922 555 0121',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 19, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 20, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz3', score: 18, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 47, maxScore: 50),
        ScoreEntry(categoryId: 'c_activity', score: 30, maxScore: 30),
        ScoreEntry(categoryId: 'c_assignment', score: 20, maxScore: 20),
        ScoreEntry(categoryId: 'c_project', score: 96, maxScore: 100),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(1), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(2), status: AttendanceStatus.excused),
      ],
    ),
    Student(
      id: 'st_007',
      studentNumber: '2021-01240',
      fullName: 'Carlo Mendoza',
      age: 22,
      gender: 'Male',
      sectionId: 's_bscs3a',
      contact: '0923 555 0154',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 13, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 12, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 35, maxScore: 50),
        ScoreEntry(categoryId: 'c_activity', score: 22, maxScore: 30),
        ScoreEntry(categoryId: 'c_assignment', score: 15, maxScore: 20),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.absent),
        AttendanceEntry(date: dayAgo(1), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(2), status: AttendanceStatus.absent),
      ],
    ),
    Student(
      id: 'st_008',
      studentNumber: '2021-01241',
      fullName: 'Bea Fernandez',
      age: 19,
      gender: 'Female',
      sectionId: 's_bscs3a',
      contact: '0924 555 0186',
      pictureUrl: 'https://i.pravatar.cc/200?img=25',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 18, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 19, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz3', score: 17, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 43, maxScore: 50),
        ScoreEntry(categoryId: 'c_activity', score: 28, maxScore: 30),
        ScoreEntry(categoryId: 'c_assignment', score: 19, maxScore: 20),
        ScoreEntry(categoryId: 'c_project', score: 91, maxScore: 100),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(1), status: AttendanceStatus.present),
        AttendanceEntry(date: dayAgo(2), status: AttendanceStatus.present),
      ],
    ),
    Student(
      id: 'st_101',
      studentNumber: '2021-02210',
      fullName: 'Paolo Aquino',
      age: 20,
      gender: 'Male',
      sectionId: 's_bscs3b',
      contact: '0930 555 0130',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 17, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 16, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 42, maxScore: 50),
        ScoreEntry(categoryId: 'c_assignment', score: 18, maxScore: 20),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.present),
      ],
    ),
    Student(
      id: 'st_102',
      studentNumber: '2021-02211',
      fullName: 'Nicole Villanueva',
      age: 19,
      gender: 'Female',
      sectionId: 's_bscs3b',
      contact: '0931 555 0144',
      pictureUrl: 'https://i.pravatar.cc/200?img=45',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 20, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 19, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 49, maxScore: 50),
        ScoreEntry(categoryId: 'c_activity', score: 30, maxScore: 30),
        ScoreEntry(categoryId: 'c_assignment', score: 20, maxScore: 20),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.excused),
      ],
    ),
    Student(
      id: 'st_103',
      studentNumber: '2021-02212',
      fullName: 'Rico Buenaventura',
      age: 21,
      gender: 'Male',
      sectionId: 's_bscs3b',
      contact: '0932 555 0171',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 14, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 36, maxScore: 50),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.absent),
      ],
    ),
    Student(
      id: 'st_201',
      studentNumber: '2021-03201',
      fullName: 'Kevin Uy',
      age: 20,
      gender: 'Male',
      sectionId: 's_bsit3a',
      contact: '0940 555 0125',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 18, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 17, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 44, maxScore: 50),
        ScoreEntry(categoryId: 'c_project', score: 88, maxScore: 100),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.present),
      ],
    ),
    Student(
      id: 'st_202',
      studentNumber: '2021-03202',
      fullName: 'Jasmine Cruz',
      age: 19,
      gender: 'Female',
      sectionId: 's_bsit3a',
      contact: '0941 555 0139',
      scores: <ScoreEntry>[
        ScoreEntry(categoryId: 'c_quiz1', score: 19, maxScore: 20),
        ScoreEntry(categoryId: 'c_quiz2', score: 20, maxScore: 20),
        ScoreEntry(categoryId: 'c_exam', score: 46, maxScore: 50),
        ScoreEntry(categoryId: 'c_project', score: 94, maxScore: 100),
      ],
      attendance: <AttendanceEntry>[
        AttendanceEntry(date: dayAgo(0), status: AttendanceStatus.present),
      ],
    ),
  ];

  return SampleData(
    sections: sections,
    students: students,
    categories: categories,
  );
}