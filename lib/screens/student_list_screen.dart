import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../data/record_manager.dart';
import '../models/attendance.dart';
import '../models/section.dart';
import '../models/student.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/student_avatar.dart';

/// Student list of the selected section + teacher-friendly dashboard.
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  RecordManager get _db => RecordManager.instance;

  Section? get _section => _db.sectionById(widget.sectionId);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openStudent(Student student) async {
    await Navigator.of(context)
        .pushNamed(AppRoutes.studentDetail, arguments: student.id);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _editStudent(Student student) async {
    await Navigator.of(context).pushNamed<bool>(
      AppRoutes.studentForm,
      arguments: <String, dynamic>{
        'sectionId': widget.sectionId,
        'studentId': student.id,
      },
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _addStudent() async {
    final bool? added = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.studentForm,
      arguments: <String, dynamic>{'sectionId': widget.sectionId},
    );
    if (!mounted) return;
    setState(() {});
    if (added == true) {
      _showMessage('Student added to ${_section?.name ?? 'section'}.');
    }
  }

  Future<void> _deleteStudent(Student student) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text(
          '${student.fullName} (${student.studentNumber}) will be removed from the class record.',
        ),
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
    setState(() {});
    _showMessage('${student.fullName} deleted.');
  }

  /// One-tap attendance: PRESENT -> ABSENT -> EXCUSED -> PRESENT.
  void _tapAttendance(Student student) {
    _db.cycleAttendance(student, DateTime.now());
    setState(() {});
    _showMessage(
      '${student.fullName} is now ${student.todayStatus.label}',
    );
  }

  Future<void> _editSection() async {
    final Section? section = _section;
    if (section == null) return;
    await Navigator.of(context)
        .pushNamed(AppRoutes.sectionForm, arguments: section);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteSection() async {
    final Section? section = _section;
    if (section == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete section?'),
        content: Text(
          '${section.name} and all of its students will be deleted from the app.',
        ),
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
    _db.deleteSection(section.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Section? section = _section;
    if (section == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Section not found')),
        body: EmptyState(
          icon: Icons.search_off,
          title: 'This section no longer exists',
          message: 'Go back to the home screen and pick another section.',
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Sections'),
          ),
        ),
      );
    }

    final List<Student> students = _db.searchStudents(section.id, _query);
    final SectionStats stats = _db.statsFor(section.id, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(section.name),
            Text(
              section.adviser.isEmpty
                  ? '${stats.total} students'
                  : '${section.adviser} • ${stats.total} students',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Class records',
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.records, arguments: section.id),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'edit') _editSection();
              if (value == 'delete') _deleteSection();
            },
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit section'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete section'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStudent,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Student'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildDashboard(context, stats),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (String value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search name or student ID',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: <Widget>[
                  Text(
                    '${students.length} student${students.length == 1 ? '' : 's'} shown',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Expanded(
                    child: Text(
                      'Tap the status chip to change attendance',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF5A6472),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: students.isEmpty
                  ? EmptyState(
                      icon: Icons.person_search_outlined,
                      title: _query.isEmpty ? 'No students yet' : 'No match found',
                      message: _query.isEmpty
                          ? 'Tap "Add Student" to create the first record of ${section.name}.'
                          : 'Try another name or student ID.',
                      action: _query.isEmpty
                          ? FilledButton.icon(
                              onPressed: _addStudent,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Student'),
                            )
                          : null,
                    )
                  : LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints c) {
                        if (c.maxWidth < 760) {
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                            itemCount: students.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _StudentTile(
                                  student: students[index],
                                  sectionName: section.name,
                                  onTap: () => _openStudent(students[index]),
                                  onCycle: () => _tapAttendance(students[index]),
                                  onEdit: () => _editStudent(students[index]),
                                  onDelete: () => _deleteStudent(students[index]),
                                ),
                              );
                            },
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 460,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 116,
                          ),
                          itemCount: students.length,
                          itemBuilder: (BuildContext context, int index) {
                            return _StudentTile(
                              student: students[index],
                              sectionName: section.name,
                              onTap: () => _openStudent(students[index]),
                              onCycle: () => _tapAttendance(students[index]),
                              onEdit: () => _editStudent(students[index]),
                              onDelete: () => _deleteStudent(students[index]),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, SectionStats stats) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double w = c.maxWidth;
            final int columns = w >= 720 ? 5 : (w >= 420 ? 3 : 2);
            final double itemWidth =
                (w - (columns - 1) * 8) / columns;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionHeader(
                  title: 'Class Dashboard',
                  icon: Icons.insights,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        label: 'Students',
                        value: '${stats.total}',
                        icon: Icons.people,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        label: 'Present',
                        value: '${stats.present}',
                        icon: Icons.check_circle,
                        color: AttendanceStatus.present.color,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        label: 'Absent',
                        value: '${stats.absent}',
                        icon: Icons.cancel,
                        color: AttendanceStatus.absent.color,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        label: 'Excused',
                        value: '${stats.excused}',
                        icon: Icons.event_busy,
                        color: AttendanceStatus.excused.color,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: StatCard(
                        label: 'Class Average',
                        value: stats.averageLabel,
                        icon: Icons.trending_up,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.student,
    required this.sectionName,
    required this.onTap,
    required this.onCycle,
    required this.onEdit,
    required this.onDelete,
  });

  final Student student;
  final String sectionName;
  final VoidCallback onTap;
  final VoidCallback onCycle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey<String>('student-${student.id}'),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              StudentAvatar(student: student, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student.studentNumber} • $sectionName • ${student.age} yrs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF5A6472),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        AttendanceTapButton(
                          status: student.todayStatus,
                          onTap: onCycle,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Avg ${student.averageLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Student actions',
                icon: const Icon(Icons.more_vert),
                onSelected: (String value) {
                  if (value == 'view') onTap();
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (BuildContext context) =>
                    const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility_outlined),
                      title: Text('Quick view'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}