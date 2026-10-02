import 'package:flutter/material.dart';

import '../data/record_manager.dart';
import '../models/section.dart';

/// Create / edit a section. Required fields are validated with simple messages.
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
    if (_isEditing) {
      final Section section = widget.section!;
      section
        ..name = _nameController.text.trim().toUpperCase()
        ..adviser = _adviserController.text.trim();
      Navigator.of(context).pop(true);
    } else {
      db.addSection(
        name: _nameController.text,
        adviser: _adviserController.text,
      );
      Navigator.of(context).pop(true);
    }
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
                        'Example: BSCS 3A, BSIT 3B, BSIS 2C',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A6472),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Section name *',
                          hintText: 'BSCS 3A',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (String? value) {
                          final String text = (value ?? '').trim();
                          if (text.isEmpty) {
                            return 'Section name is required';
                          }
                          if (text.length < 4) {
                            return 'Enter at least 4 characters (BSCS 3A)';
                          }
                          if (RecordManager.instance.sectionNameExists(
                            text,
                            ignoreId: widget.section?.id,
                          )) {
                            return 'Section already exists';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
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
              _QuickPick(
                controller: _nameController,
                formKey: _formKey,
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
}

/// Tap-to-fill helper so students do not have to type the section format.
class _QuickPick extends StatelessWidget {
  const _QuickPick({required this.controller, required this.formKey});

  final TextEditingController controller;
  final GlobalKey<FormState> formKey;

  static const List<String> _samples = <String>[
    'BSCS 3A',
    'BSCS 3B',
    'BSIT 3A',
    'BSIS 2C',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Quick pick',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _samples.map((String name) {
            return ActionChip(
              label: Text(name),
              onPressed: () {
                controller.text = name;
                formKey.currentState?.validate();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}