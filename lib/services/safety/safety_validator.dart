class SafetyValidator {
  static const banned = <String>[
    'road',
    'traffic',
    'cliff',
    'fire',
    'knife',
    'sharp',
    'electrical',
    'socket',
    'chemical',
    'roof',
    'unsafe climb',
    'stranger',
    'fight',
    'weapon',
    'height',
    'falling from',
    'dangerous animal',
    'cage',
    'prison',
  ];

  static const allowedMovements = <String>{
    'jump',
    'hop',
    'reach',
    'clap',
    'march',
    'balance',
    'squat',
    'stand',
    'twist',
  };

  bool validate(Map<String, dynamic> json) {
    final text = json.toString().toLowerCase();
    if (banned.any(text.contains)) return false;

    final movements = json['movementSequence'] as List<dynamic>? ?? const [];
    for (final m in movements) {
      final name =
          (m is Map ? m['name'] : null)?.toString().toLowerCase().trim() ?? '';
      if (name.isNotEmpty && !allowedMovements.contains(name)) return false;

      final countValue = m is Map ? m['count'] : null;
      final count = countValue is num ? countValue.toInt() : 1;
      if (count < 1 || count > 8) return false;
    }

    return true;
  }

  bool validateBlueprint(dynamic blueprint) {
    final text = blueprint.toString().toLowerCase();
    return !text.contains('cage') && !text.contains('prison');
  }

  bool validateChildFacingText(String text) {
    final normalized = text.toLowerCase();
    return !banned.any(normalized.contains) && text.length <= 180;
  }
}
