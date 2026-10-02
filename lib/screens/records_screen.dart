import 'package:flutter/material.dart';

import '../data/record_manager.dart';
import '../models/score.dart';
import '../models/section.dart';
import '../models/student.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';
import '../widgets/student_avatar.dart';

/// Printable-style class records of a section: every student with the
/// average score per category, attendance and overall average.
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context) {
    final RecordManager db = RecordManager.instance;
    final Section? section = db.sectionById(sectionId);
    final List<Student> students = db.studentsOf(sectionId);
    final SectionStats stats = db.statsFor(sectionId, DateTime.now());
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Class Records'),
            Text(
              section?.name ?? 'Section',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Print / share summary',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      '${section?.name ?? 'Section'} summary: '
                      '${stats.total} students, ${stats.present} present, '
                      '${stats.absent} absent, ${stats.excused} excused, '
                      'class average ${stats.averageLabel}',
                    ),
                  ),
                );
            },
          ),
        ],
      ),
      body: students.isEmpty
          ? const EmptyState(
              icon: Icons.table_rows_outlined,
              title: 'No records yet',
              message: 'Add students to this section first.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SectionHeader(
                          title: section?.name ?? 'Section',
                          icon: Icons.summarize_outlined,
                          trailing: Chip(
                            label: Text('Average ${stats.averageLabel}'),
                            backgroundColor: scheme.primary
                                .withValues(alpha: 0.10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _pill('Students', '${stats.total}', scheme.primary),
                            _pill('Present', '${stats.present}',
                                const Color(0xFF1B8E4B)),
                            _pill('Absent', '${stats.absent}',
                                const Color(0xFFC62828)),
                            _pill('Excused', '${stats.excused}',
                                const Color(0xFFB26A00)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionHeader(
                          title: 'Per student record',
                          icon: Icons.record_voice_over_outlined,
                        ),
                        const SizedBox(height: 6),
                        ..._records(db, students),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _records(RecordManager db, List<Student> students) {
    final List<Widget> widgets = <Widget>[];
    final List<Student> ranked = List<Student>.from(students)
      ..sort((Student a, Student b) =>
          b.overallAverage.compareTo(a.overallAverage));

    for (int i = 0; i < ranked.length; i++) {
      widgets.add(_RecordRow(
        rank: i + 1,
        student: ranked[i],
        categories: db.categories,
      ));
      if (i != ranked.length - 1) widgets.add(const Divider(height: 18));
    }
    return widgets;
  }

  Widget _pill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.rank,
    required this.student,
    required this.categories,
  });

  final int rank;
  final Student student;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> averages = student.categoryAverages;
    final List<Category> scored =
        categories.where((Category c) => averages.containsKey(c.id)).toList();
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StudentAvatar(student: student, radius: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      student.studentNumber,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF5A6472),
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(status: student.todayStatus, compact: true),
              const SizedBox(width: 8),
              Text(
                student.averageLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          if (scored.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: scored
                    .map(
                      (Category c) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${c.name} ${averages[c.id]!.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475467),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}