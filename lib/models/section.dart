class Section {
  Section({
    required this.id,
    required this.name,
    this.adviser = '',
  });

  final String id;
  String name;
  String adviser;

  String get label => name.toUpperCase();
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