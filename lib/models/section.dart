class Section {
  Section({
    required this.id,
    required this.name,
    this.adviser = '',
  });

  final String id;
  String name;
  String adviser;

  /// The name exactly as the user typed it.
  String get label => name;
}

const List<String> kPrograms = <String>[
  'BSCS',
  'BSIT',
  'BSIS',
  'BSED',
  'BSBA',
  'BSM',
];

const List<String> kYearLevels = <String>[
  '1st Year',
  '2nd Year',
  '3rd Year',
  '4th Year',
];