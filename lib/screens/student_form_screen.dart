import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/record_manager.dart';
import '../models/section.dart';
import '../models/student.dart';
import '../utils/picture_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/student_picture.dart';

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
  final TextEditingController _linkController = TextEditingController();

  String? _gender;
  String? _sectionId;

  /// The value stored on the student: an uploaded `data:` image or an
  /// `http(s)` link.
  String _picture = '';
  bool _pickingPicture = false;

  RecordManager get _db => RecordManager.instance;
  Student? get _student =>
      widget.studentId == null ? null : _db.studentById(widget.studentId!);

  bool get _hasPicture => _picture.trim().isNotEmpty;

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
    _picture = student?.pictureUrl ?? '';
    _linkController.text = _isLink(_picture) ? _picture : '';
  }

  static bool _isLink(String value) {
    final String text = value.trim();
    return text.startsWith('http://') || text.startsWith('https://');
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickPicture(ImageSource source) async {
    if (_pickingPicture) return;
    setState(() => _pickingPicture = true);
    final PicturePickResult result = await PictureService.instance.pick(source);
    if (!mounted) return;
    setState(() => _pickingPicture = false);
    if (result.isCancelled) return;
    final String? value = result.value;
    if (value == null) {
      _showMessage(result.error ?? 'That picture could not be used.');
      return;
    }
    setState(() {
      _picture = value;
      // The picture is uploaded now, so the optional link field is cleared.
      _linkController.clear();
    });
    _formKey.currentState?.validate();
  }

  void _removePicture() {
    setState(() {
      _picture = '';
      _linkController.clear();
    });
    _formKey.currentState?.validate();
  }

  void _onLinkChanged(String value) {
    _picture = value.trim();
    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
        pictureUrl: _picture,
      );
    } else {
      student
        ..studentNumber = _numberController.text.trim()
        ..fullName = _nameController.text.trim()
        ..age = int.parse(_ageController.text.trim())
        ..gender = _gender ?? student.gender
        ..sectionId = _sectionId ?? student.sectionId
        ..contact = _contactController.text.trim()
        ..pictureUrl = _picture.trim();
      // The record was edited in place, so ask the store to persist it.
      _db.save();
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
                        onChanged: (String value) => setState(() {}),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(
              title: 'Profile picture',
              icon: Icons.photo_camera_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Preview of the selected picture (object-fit: cover inside a
                // circle, so a photo is never stretched).
                StudentPicture(
                  key: const ValueKey<String>('picture-preview'),
                  pictureUrl: _picture,
                  size: 92,
                  fallback: _PicturePlaceholder(name: _nameController.text),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _pictureDescription(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF5A6472),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          FilledButton.tonalIcon(
                            key: const ValueKey<String>('pick-picture-gallery'),
                            onPressed: _pickingPicture
                                ? null
                                : () => _pickPicture(ImageSource.gallery),
                            icon: _pickingPicture
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_library_outlined),
                            label: const Text('Choose photo'),
                          ),
                          if (PictureService.hasCamera)
                            OutlinedButton.icon(
                              key:
                                  const ValueKey<String>('pick-picture-camera'),
                              onPressed: _pickingPicture
                                  ? null
                                  : () => _pickPicture(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Camera'),
                            ),
                          if (_hasPicture)
                            TextButton.icon(
                              key: const ValueKey<String>('remove-picture'),
                              onPressed: _removePicture,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey<String>('field-picture'),
              controller: _linkController,
              keyboardType: TextInputType.url,
              onChanged: _onLinkChanged,
              decoration: const InputDecoration(
                labelText: 'Picture link (optional)',
                hintText: 'https://...',
                helperText: 'Or upload a photo with "Choose photo" above',
                prefixIcon: Icon(Icons.link),
              ),
              validator: (String? value) {
                final String text = (value ?? '').trim();
                if (text.isEmpty) return null;
                if (!text.startsWith('http://') &&
                    !text.startsWith('https://')) {
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

  String _pictureDescription() {
    if (!_hasPicture) {
      return 'No picture yet. You can upload one or paste a link below.';
    }
    if (PictureService.isUploaded(_picture)) {
      return 'Picture uploaded. It is saved with the student and will still be '
          'there after a refresh.';
    }
    return 'Using the picture from the link below.';
  }
}

/// Shown while no picture is selected. Mirrors the initials badge used in the
/// student list so the form and the record look the same.
class _PicturePlaceholder extends StatelessWidget {
  const _PicturePlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? text = _initials(name);
    return Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: text == null
          ? Icon(Icons.person, size: 46, color: scheme.primary)
          : Text(
              text,
              style: TextStyle(
                color: scheme.primary,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  static String? _initials(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
