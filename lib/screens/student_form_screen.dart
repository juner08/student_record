import 'package:flutter/material.dart';

import '../data/record_manager.dart';
import '../models/section.dart';
import '../models/student.dart';
import '../widgets/empty_state.dart';

const List<String> kGenders = <String>['Male', 'Female', 'Other'];

/// Add / edit a student. Newly added students always go to the section that
/// is currently selected.
class StudentFormScreen extends StatefulWidget {
  const StudentFormScreen({
    super.key,
    required this.sectionId,
    this.studentId,
  });

  final String sectionId;
  final String? studentId;

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _pictureController = TextEditingController();

  String? _gender;
  String? _sectionId;

  RecordManager get _db => RecordManager.instance;
  Student? get _student =>
      widget.studentId == null ? null : _db.studentById(widget.studentId!);

  @override
  void initState() {
    super.initState();
    final Student? student = _student;
    _sectionId = student?.sectionId ?? widget.sectionId;
    _gender = student?.gender;
    _numberController.text = student?.studentNumber ?? '';
    _nameController.text = student?.fullName ?? '';
    _ageController.text = student?.age.toString() ?? '';
    _contactController.text = student?.contact ?? '';
    _pictureController.text = student?.pictureUrl ?? '';
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _pictureController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Student? student = _student;
    if (student == null) {
      _db.addStudent(
        studentNumber: _numberController.text,
        fullName: _nameController.text,
        age: int.parse(_ageController.text.trim()),
        gender: _gender ?? kGenders.first,
        sectionId: _sectionId ?? widget.sectionId,
        contact: _contactController.text,
        pictureUrl: _pictureController.text,
      );
    } else {
      student
        ..studentNumber = _numberController.text.trim()
        ..fullName = _nameController.text.trim()
        ..age = int.parse(_ageController.text.trim())
        ..gender = _gender ?? student.gender
        ..sectionId = _sectionId ?? student.sectionId
        ..contact = _contactController.text.trim()
        ..pictureUrl = _pictureController.text.trim();
    }
    Navigator.of(context).pop(true);
  }

  String? _validateNumber(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Student ID is required';
    if (text.length < 4) return 'Student ID looks too short';
    if (_db.studentNumberExists(
      _sectionId ?? widget.sectionId,
      text,
      ignoreId: _student?.id,
    )) {
      return 'This student ID already exists in the section';
    }
    return null;
  }

  String? _validateName(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Full name is required';
    if (text.length < 3) return 'Please enter the complete name';
    return null;
  }

  String? _validateAge(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Age is required';
    final int? age = int.tryParse(text);
    if (age == null) return 'Age must be a number';
    if (age < 5 || age > 80) return 'Enter an age between 5 and 80';
    return null;
  }

  String? _validateGender(String? value) =>
      value == null ? 'Please choose a gender' : null;

  String? _validateSection(String? value) =>
      value == null ? 'Please choose a section' : null;

  String? _validateContact(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (text.contains('@') && !text.contains('.')) {
      return 'Enter a valid email address';
    }
    if (text.replaceAll(RegExp(r'[0-9+\-\s]'), '').isNotEmpty) {
      return 'Use a phone number or an email address only';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = _student != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit Student' : 'Add Student'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              _buildPictureCard(context),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SectionHeader(
                        title: 'Basic information',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey<String>('field-number'),
                        controller: _numberController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Student ID *',
                          hintText: '2021-01234',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: _validateNumber,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey<String>('field-name'),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full name *',
                          hintText: 'Juan Dela Cruz',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey<String>('field-age'),
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Age *',
                          hintText: '20',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        validator: _validateAge,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        key: const ValueKey<String>('field-gender'),
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender *',
                          prefixIcon: Icon(Icons.wc),
                        ),
                        items: kGenders
                            .map(
                              (String g) => DropdownMenuItem<String>(
                                value: g,
                                child: Text(g),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) =>
                            setState(() => _gender = value),
                        validator: _validateGender,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        key: const ValueKey<String>('field-section'),
                        initialValue: _sectionId,
                        decoration: const InputDecoration(
                          labelText: 'Section *',
                          prefixIcon: Icon(Icons.groups_outlined),
                          helperText:
                              'Students are added to the selected section',
                        ),
                        items: _db.sections
                            .map(
                              (Section s) => DropdownMenuItem<String>(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          setState(() => _sectionId = value);
                          _formKey.currentState?.validate();
                        },
                        validator: _validateSection,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey<String>('field-contact'),
                        controller: _contactController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Contact number or email',
                          hintText: '0917 555 0142',
                          prefixIcon: Icon(Icons.call_outlined),
                        ),
                        validator: _validateContact,
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
                      label: Text(editing ? 'Update' : 'Save Student'),
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

  Widget _buildPictureCard(BuildContext context) {
    final String url = _pictureController.text.trim();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Stack(
              alignment: Alignment.bottomRight,
              children: <Widget>[
                Container(
                  width: 92,
                  height: 92,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: url.isEmpty
                      ? Icon(Icons.person, size: 48, color: scheme.primary)
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stack,
                          ) =>
                              Icon(Icons.broken_image, size: 44, color: scheme.primary),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera,
                      size: 16, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey<String>('field-picture'),
              controller: _pictureController,
              keyboardType: TextInputType.url,
              onChanged: (String value) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Picture link (optional)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
              validator: (String? value) {
                final String text = (value ?? '').trim();
                if (text.isNotEmpty && !text.startsWith('http')) {
                  return 'Picture link must start with http';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}