import 'package:flutter/material.dart';

import '../data/record_manager.dart';
import '../models/section.dart';

/// Minimum / maximum length of a custom section name.
const int kSectionNameMinLength = 2;
const int kSectionNameMaxLength = 60;

/// Create / edit a section.
///
/// The name is a plain text field: the teacher types whatever their class is
/// called. Nothing is limited to a fixed list - `BSCS 3A`, `BSCS 3B`,
/// `BSIT 2A`, `STEM 12-A` or `Section Jupiter` are all accepted.
class SectionFormScreen extends StatefulWidget {
  const SectionFormScreen({super.key, this.section});

  final Section? section;

  @override
  State<SectionFormScreen> createState() => _SectionFormScreenState();
}

class _SectionFormScreenState extends State<SectionFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _adviserController;

  bool get _isEditing => widget.section != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.section?.name ?? '');
    _adviserController =
        TextEditingController(text: widget.section?.adviser ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _adviserController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final RecordManager db = RecordManager.instance;
    final String name = _nameController.text;
    if (_isEditing) {
      db.updateSection(
        widget.section!,
        name: name,
        adviser: _adviserController.text,
      );
    } else {
      db.addSection(
        name: name,
        adviser: _adviserController.text,
      );
    }
    Navigator.of(context).pop(true);
  }

  void _useExample(String example) {
    _nameController
      ..text = example
      ..selection = TextSelection.collapsed(offset: example.length);
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Section' : 'Create Section'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Section details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Type any section name you want - there is no fixed list.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A6472),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey<String>('field-section-name'),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: kSectionNameMaxLength,
                        decoration: const InputDecoration(
                          labelText: 'Section name *',
                          hintText: 'BSCS 3A',
                          helperText:
                              'Any name is accepted, e.g. STEM 12-A or Section Jupiter',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey<String>('field-section-adviser'),
                        controller: _adviserController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Teacher / adviser (optional)',
                          hintText: 'Prof. Juan Dela Cruz',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Suggestions(onSelected: _useExample),
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
                      label: Text(_isEditing ? 'Update' : 'Save Section'),
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

  String? _validateName(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Section name is required';
    }
    if (text.length < kSectionNameMinLength) {
      return 'Enter at least $kSectionNameMinLength characters';
    }
    if (RecordManager.instance.sectionNameExists(
      text,
      ignoreId: widget.section?.id,
    )) {
      return 'Section already exists';
    }
    return null;
  }
}

/// Optional shortcuts that only fill the text field. The name itself is always
/// typed by hand, so this never restricts what can be created.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onSelected});

  final ValueChanged<String> onSelected;

  static const List<String> _examples = <String>[
    'BSCS 3A',
    'BSIT 2A',
    'STEM 12-A',
    'Section Jupiter',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Format examples (optional)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        const Text(
          'Tap one to copy it into the field, or ignore them and type your own.',
          style: TextStyle(fontSize: 12, color: Color(0xFF5A6472)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples.map((String name) {
            return ActionChip(
              label: Text(name),
              onPressed: () => onSelected(name),
            );
          }).toList(),
        ),
      ],
    );
  }
}
