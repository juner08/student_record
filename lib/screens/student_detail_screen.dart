import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../data/record_manager.dart';
import '../models/attendance.dart';
import '../models/score.dart';
import '../models/student.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';
import '../widgets/student_avatar.dart';

/// Complete digital record of one student: picture, grades, quizzes, exams,
/// attendance history and overall average.
class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  RecordManager get _db => RecordManager.instance;
  Student? get _student => _db.studentById(widget.studentId);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _editStudent() async {
    final Student? student = _student;
    if (student == null) return;
    await Navigator.of(context).pushNamed<bool>(
      AppRoutes.studentForm,
      arguments: <String, dynamic>{
        'sectionId': student.sectionId,
        'studentId': student.id,
      },
    );
    if (!mounted) return;
    _refresh();
  }

  Future<void> _deleteStudent() async {
    final Student? student = _student;
    if (student == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Remove ${student.fullName} from the class record?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    _db.deleteStudent(student.id);
    Navigator.of(context).pop();
  }

  Future<void> _addScore() async {
    final bool? saved = await Navigator.of(context)
        .pushNamed<bool>(AppRoutes.scoreForm, arguments: widget.studentId);
    if (!mounted || saved != true) return;
    _refresh();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final Student? student = _student;
    if (student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student not found')),
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Record not available',
          message: 'This student was deleted from the list.',
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit student',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editStudent,
          ),
          IconButton(
            tooltip: 'Delete student',
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteStudent,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const <Widget>[
            Tab(text: 'Grades'),
            Tab(text: 'Attendance'),
            Tab(text: 'Profile'),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          _ProfileHeader(student: student),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _GradesTab(
                  student: student,
                  onAddScore: _addScore,
                  onChanged: _refresh,
                ),
                _AttendanceTab(
                  student: student,
                  selectedDate: _selectedDate,
                  onPickDate: _pickDate,
                  onChanged: _refresh,
                ),
                _ProfileTab(student: student),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final RecordManager db = RecordManager.instance;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          StudentAvatar(student: student, radius: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  student.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.studentNumber} • ${db.sectionNameOf(student.sectionId)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF5A6472)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    StatusChip(status: student.todayStatus, compact: true),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Overall ${student.averageLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradesTab extends StatelessWidget {
  const _GradesTab({
    required this.student,
    required this.onAddScore,
    required this.onChanged,
  });

  final Student student;
  final VoidCallback onAddScore;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final RecordManager db = RecordManager.instance;
    final List<Category> categories = db.categories;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Overall Average',
                              style: TextStyle(color: Color(0xFF5A6472)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student.averageLabel,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${student.scores.length} of ${categories.length} categories scored',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5A6472),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 92,
                        height: 92,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 92,
                              height: 92,
                              child: CircularProgressIndicator(
                                value:
                                    (student.overallAverage / 100).clamp(0.0, 1.0),
                                strokeWidth: 9,
                                backgroundColor: const Color(0xFFE2E8F0),
                              ),
                            ),
                            Text(
                              '${student.overallAverage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SectionHeader(
                        title: 'Scores by category',
                        icon: Icons.grading_outlined,
                      ),
                      const SizedBox(height: 10),
                      if (categories.isEmpty)
                        const Text('No score category yet.')
                      else
                        ...categories.map(
                          (Category c) => _ScoreRow(
                            category: c,
                            entry: student.scoreFor(c.id),
                            onTap: () async {
                              final bool? saved = await Navigator.of(context)
                                  .pushNamed<bool>(
                                AppRoutes.scoreForm,
                                arguments: student.id,
                              );
                              if (saved == true) onChanged();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddScore,
              icon: const Icon(Icons.add),
              label: const Text('Add / edit score'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.category,
    required this.entry,
    required this.onTap,
  });

  final Category category;
  final ScoreEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double percent = entry?.percentage ?? 0;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color barColor = percent >= 90
        ? const Color(0xFF1B8E4B)
        : percent >= 75
            ? scheme.primary
            : const Color(0xFFC62828);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(category.kind.icon, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (entry == null)
                  const Chip(
                    label: Text('No score'),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Text(
                    '${entry!.display}  (${percent.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: barColor,
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.edit, size: 15, color: Color(0xFF9AA5B1)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (percent / 100).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: const Color(0xFFE2E8F0),
                color: barColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({
    required this.student,
    required this.selectedDate,
    required this.onPickDate,
    required this.onChanged,
  });

  final Student student;
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final RecordManager db = RecordManager.instance;
    final AttendanceStatus current = student.statusOn(selectedDate);
    final List<AttendanceEntry> history = student.sortedAttendance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionHeader(
                  title: 'Mark ${formatDate(selectedDate)}',
                  icon: Icons.event_note_outlined,
                  trailing: TextButton.icon(
                    onPressed: onPickDate,
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Change'),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: current.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      StatusChip(status: current),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          current == AttendanceStatus.present
                              ? 'Student is present on this date.'
                              : current == AttendanceStatus.absent
                                  ? 'Student is absent on this date.'
                                  : 'Student is excused on this date.',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    for (final AttendanceStatus status
                        in AttendanceStatus.values) ...<Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: status.color,
                              side: BorderSide(
                                color: status.color.withValues(alpha: 0.6),
                              ),
                            ),
                            onPressed: () {
                              db.setAttendance(student, selectedDate, status);
                              onChanged();
                            },
                            icon: Icon(status.icon, size: 16),
                            label: Text(status.shortLabel),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionHeader(
                  title: 'Attendance history',
                  icon: Icons.history,
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    _countBox('Present', student.countOf(AttendanceStatus.present),
                        AttendanceStatus.present.color),
                    const SizedBox(width: 8),
                    _countBox('Absent', student.countOf(AttendanceStatus.absent),
                        AttendanceStatus.absent.color),
                    const SizedBox(width: 8),
                    _countBox('Excused', student.countOf(AttendanceStatus.excused),
                        AttendanceStatus.excused.color),
                  ],
                ),
                const Divider(height: 22),
                if (history.isEmpty)
                  const Text(
                    'No attendance record yet. Mark a date above to start.',
                    style: TextStyle(color: Color(0xFF5A6472)),
                  )
                else
                  ...history.map(
                    (AttendanceEntry entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            dayKey(entry.date) == dayKey(DateTime.now())
                                ? Icons.today
                                : Icons.calendar_today_outlined,
                            size: 16,
                            color: const Color(0xFF9AA5B1),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formatDate(entry.date),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          StatusChip(status: entry.status, compact: true),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _countBox(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: <Widget>[
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final RecordManager db = RecordManager.instance;
    final Map<String, double> categoryAverages = student.categoryAverages;
    final List<Category> categories = db.categories
        .where((Category c) => categoryAverages.containsKey(c.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionHeader(
                  title: 'Student profile',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.badge_outlined, 'Student ID', student.studentNumber),
                _infoRow(Icons.person_outline, 'Full name', student.fullName),
                _infoRow(Icons.cake_outlined, 'Age', '${student.age} years old'),
                _infoRow(Icons.wc, 'Gender', student.gender),
                _infoRow(
                  Icons.groups_outlined,
                  'Section',
                  db.sectionNameOf(student.sectionId),
                ),
                _infoRow(
                  Icons.call_outlined,
                  'Contact',
                  student.contact.isEmpty ? 'Not provided' : student.contact,
                ),
                _infoRow(
                  Icons.image_outlined,
                  'Picture',
                  _pictureLabel(student),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionHeader(
                  title: 'Class ranking',
                  icon: Icons.leaderboard_outlined,
                ),
                const SizedBox(height: 12),
                _infoRow(
                  Icons.emoji_events_outlined,
                  'Rank',
                  '#${db.rankOf(student)} of ${db.studentsOf(student.sectionId).length}',
                ),
                _infoRow(
                  Icons.trending_up,
                  'Overall average',
                  student.averageLabel,
                ),
                if (categories.isNotEmpty) ...<Widget>[
                  const Divider(height: 22),
                  ...categories.map(
                    (Category c) => _infoRow(
                      c.kind.icon,
                      c.name,
                      '${categoryAverages[c.id]!.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The picture value can be a long base64 string, so describe it instead of
  /// printing it in the profile list.
  static String _pictureLabel(Student student) {
    final String value = student.pictureUrl.trim();
    if (value.isEmpty) return 'None';
    if (value.startsWith('data:')) return 'Uploaded photo';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return 'Photo link';
    }
    return 'None';
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFF9AA5B1)),
          const SizedBox(width: 10),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF5A6472)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}