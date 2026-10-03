import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/record_manager.dart';
import '../models/score.dart';
import '../models/student.dart';

/// Enter or update the score of a student in one category.
class ScoreFormScreen extends StatefulWidget {
  const ScoreFormScreen({super.key, required this.studentId, this.categoryId});

  final String studentId;
  final String? categoryId;

  @override
  State<ScoreFormScreen> createState() => _ScoreFormScreenState();
}

class _ScoreFormScreenState extends State<ScoreFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  String? _categoryId;

  RecordManager get _db => RecordManager.instance;

  Student? get _student => _db.studentById(widget.studentId);

  @override
  void initState() {
    super.initState();
    final Student? student = _student;
    if (student != null) {
      final ScoreEntry? existing = widget.categoryId == null
          ? null
          : student.scoreFor(widget.categoryId!);
      if (existing != null) {
        _categoryId = existing.categoryId;
        _scoreController.text = _trim(existing.score);
        _maxController.text = _trim(existing.maxScore);
      } else {
        _categoryId = widget.categoryId;
      }
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Student? student = _student;
    final Category? category = _db.categoryById(_categoryId ?? '');
    if (student == null || category == null) return;
    student.setScore(
      category.id,
      double.parse(_scoreController.text.trim()),
      double.parse(_maxController.text.trim()),
    );
    // The score was written straight onto the student, so persist it.
    _db.save();
    Navigator.of(context).pop(true);
  }

  String? _validateCategory(String? value) =>
      value == null ? 'Please choose a category' : null;

  String? _validateScore(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Score is required';
    final double? score = double.tryParse(text);
    if (score == null) return 'Score must be a number';
    if (score < 0) return 'Score cannot be negative';
    final double max = double.tryParse(_maxController.text.trim()) ?? 0;
    if (max > 0 && score > max) return 'Score cannot be higher than the total';
    return null;
  }

  String? _validateMax(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Total score is required';
    final double? max = double.tryParse(text);
    if (max == null) return 'Total must be a number';
    if (max <= 0) return 'Total must be greater than 0';
    return null;
  }

  Future<void> _createCategory() async {
    final Category? created = await showDialog<Category>(
      context: context,
      builder: (BuildContext context) => const _AddCategoryDialog(),
    );
    if (created == null || !mounted) return;
    setState(() {
      _categoryId = created.id;
      _maxController.text = _trim(created.maxScore);
    });
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    final Student? student = _student;
    final List<Category> categories = _db.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Score')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              if (student != null)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      student.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${student.studentNumber} • ${_db.sectionNameOf(student.sectionId)}',
                    ),
                    trailing: Text(
                      'Overall ${student.averageLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        key: const ValueKey<String>('field-category'),
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: categories
                            .map(
                              (Category c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text('${c.name} (/${_trim(c.maxScore)})'),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _categoryId = value;
                            final Category? category =
                                _db.categoryById(value ?? '');
                            if (category != null &&
                                _maxController.text.trim().isEmpty) {
                              _maxController.text = _trim(category.maxScore);
                            }
                          });
                          _formKey.currentState?.validate();
                        },
                        validator: _validateCategory,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _createCategory,
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Create new category'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey<String>('field-score'),
                              controller: _scoreController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              onChanged: (String value) =>
                                  _formKey.currentState?.validate(),
                              decoration: const InputDecoration(
                                labelText: 'Score *',
                                hintText: '18',
                                prefixIcon: Icon(Icons.looks_one_outlined),
                              ),
                              validator: _validateScore,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey<String>('field-max'),
                              controller: _maxController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              onChanged: (String value) =>
                                  _formKey.currentState?.validate(),
                              decoration: const InputDecoration(
                                labelText: 'Total *',
                                hintText: '20',
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              validator: _validateMax,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _QuickScores(
                        category: _db.categoryById(_categoryId ?? ''),
                        onPick: (String value) {
                          _scoreController.text = value;
                          _formKey.currentState?.validate();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Save Score'),
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

/// Small form used to add a new score category (Quiz 4, Final Exam, ...).
class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  CategoryKind _kind = CategoryKind.quiz;

  @override
  void dispose() {
    _nameController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final RecordManager db = RecordManager.instance;
    final Category category = db.addCategory(
      name: _nameController.text,
      maxScore: double.parse(_maxController.text.trim()),
      kind: _kind,
    );
    Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New score category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              key: const ValueKey<String>('field-category-name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category name *',
                hintText: 'Quiz 4',
              ),
              validator: (String? value) {
                final String text = (value ?? '').trim();
                if (text.isEmpty) return 'Category name is required';
                if (RecordManager.instance.categoryNameExists(text)) {
                  return 'Category already exists';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey<String>('field-category-max'),
              controller: _maxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total score *',
                hintText: '20',
              ),
              validator: (String? value) {
                final double? max = double.tryParse((value ?? '').trim());
                if (max == null) return 'Enter a number';
                if (max <= 0) return 'Total must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategoryKind>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Type'),
              items: CategoryKind.values
                  .map(
                    (CategoryKind k) => DropdownMenuItem<CategoryKind>(
                      value: k,
                      child: Text(k.label),
                    ),
                  )
                  .toList(),
              onChanged: (CategoryKind? value) =>
                  setState(() => _kind = value ?? CategoryKind.quiz),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _QuickScores extends StatelessWidget {
  const _QuickScores({required this.category, required this.onPick});

  final Category? category;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (category == null) return const SizedBox.shrink();
    final double max = category!.maxScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Quick entry (out of ${_ScoreFormScreenState._trim(max)})',
          style: const TextStyle(fontSize: 12, color: Color(0xFF5A6472)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final double fraction in <double>[0.5, 0.75, 0.9, 1.0])
              ActionChip(
                label: Text(_ScoreFormScreenState._trim(max * fraction)),
                onPressed: () => onPick(
                  _ScoreFormScreenState._trim(max * fraction),
                ),
              ),
          ],
        ),
      ],
    );
  }
}