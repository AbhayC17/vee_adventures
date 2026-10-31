/// The rules that decide what a child may see after photographing something
/// that is NOT in the game's own catalogue ("Discover anything").
///
/// Everything in this file is plain Dart with no network or Flutter code, so it
/// is easy to test. The AI's answer is treated as untrusted input: it is only
/// used if it passes every check below, and anything that fails is simply
/// dropped (the child sees a friendly generic message instead).
library;

enum OpenOutcomeKind {
  /// A person or part of a person is in the picture. Nothing is generated.
  person,

  /// The picture or the answer is not suitable for young children.
  blocked,

  /// The object is one of the game's own catalogue items (curated facts apply).
  catalog,

  /// The AI was not sure what it saw. The child is asked a friendly question.
  unsure,

  /// A new object outside the catalogue, with checked, short, simple facts.
  find,
}

class OpenOutcome {
  final OpenOutcomeKind kind;
  final String? catalogId;
  final double confidence;
  final String? name;
  final List<String> facts;
  final String? movementId;
  final bool fitsClue;

  const OpenOutcome._({
    required this.kind,
    this.catalogId,
    this.confidence = 0,
    this.name,
    this.facts = const <String>[],
    this.movementId,
    this.fitsClue = false,
  });

  const OpenOutcome.person() : this._(kind: OpenOutcomeKind.person);

  const OpenOutcome.blocked() : this._(kind: OpenOutcomeKind.blocked);

  const OpenOutcome.unsure([double confidence = 0])
    : this._(kind: OpenOutcomeKind.unsure, confidence: confidence);

  const OpenOutcome.catalog(String id, double confidence)
    : this._(
        kind: OpenOutcomeKind.catalog,
        catalogId: id,
        confidence: confidence,
      );

  const OpenOutcome.find({
    required String name,
    required List<String> facts,
    required bool fitsClue,
    required double confidence,
    String? movementId,
  }) : this._(
         kind: OpenOutcomeKind.find,
         name: name,
         facts: facts,
         fitsClue: fitsClue,
         confidence: confidence,
         movementId: movementId,
       );

  /// The same find with different facts (for example after extra filtering).
  OpenOutcome withFacts(List<String> newFacts) => OpenOutcome.find(
    name: name ?? '',
    facts: newFacts,
    fitsClue: fitsClue,
    confidence: confidence,
    movementId: movementId,
  );

  /// The same find with its facts removed (used when the facts could not be
  /// checked by the moderation step).
  OpenOutcome withoutFacts() => withFacts(const <String>[]);
}

class OpenDiscoveryRules {
  OpenDiscoveryRules._();

  /// How sure the AI must be that a catalogue item is right.
  static const double catalogConfidence = 0.5;

  /// How sure the AI must be about the name of a new object.
  static const double nameConfidence = 0.6;

  static const int maxNameLength = 24;
  static const int maxNameWords = 3;
  static const int maxFacts = 2;
  static const int minFactLength = 12;
  static const int maxFactLength = 110;
  static const int maxFactWords = 16;

  /// Words that must never appear in a name or a fact.
  static const List<String> blockedWords = <String>[
    // violence and weapons
    'gun', 'guns', 'pistol', 'rifle', 'knife', 'knives', 'sword', 'weapon',
    'weapons', 'bomb', 'bullet', 'bullets', 'shoot', 'shooting', 'kill',
    'killed', 'killing', 'murder', 'dead', 'death', 'die', 'dies', 'died',
    'blood', 'bloody', 'stab', 'fight', 'fighting', 'war', 'explode',
    'explosion',
    // drugs, alcohol, smoking and adult themes
    'drug', 'drugs', 'medicine', 'medicines', 'pill', 'pills', 'syringe',
    'needle', 'alcohol', 'beer', 'wine', 'whiskey', 'vodka', 'cigarette',
    'cigarettes', 'smoking', 'vape', 'cannabis', 'sex', 'sexy', 'naked',
    'nude', 'porn',
    // hate and unkind words
    'hate', 'hated', 'stupid', 'idiot', 'dumb', 'ugly', 'racist',
    // dangerous things
    'poison', 'poisonous', 'toxic', 'deadly', 'dangerous', 'lighter',
    'matches', 'razor', 'blade', 'firework', 'fireworks', 'electrocute',
  ];

  /// Words that mean a person (or part of one) is the subject.
  static const List<String> personWords = <String>[
    'person',
    'people',
    'man',
    'men',
    'woman',
    'women',
    'boy',
    'girl',
    'child',
    'children',
    'kid',
    'kids',
    'baby',
    'human',
    'face',
    'selfie',
    'hand',
    'hands',
    'finger',
    'fingers',
    'foot',
    'feet',
    'body',
    'head',
    'hair',
    'eye',
    'eyes',
    'mouth',
    'skin',
    'portrait',
  ];

  /// Hedging words: a fact containing one is not "certain", so it is dropped.
  static const List<String> hedgeWords = <String>[
    'maybe',
    'probably',
    'perhaps',
    'might',
    'possibly',
    'i think',
    'i guess',
    'not sure',
  ];

  /// Friendly questions shown when the AI is unsure. They are written here, not
  /// by the AI, so they are always safe.
  static const List<String> questions = <String>[
    'What colour do you think it is?',
    'Is it big or small?',
    'Is it soft or hard?',
    'What do you think it is used for?',
    'Where did you find it?',
  ];

  static List<String> _words(String text) =>
      RegExp(r"[a-z']+")
          .allMatches(text.toLowerCase())
          .map((m) => m.group(0)!)
          .toList(growable: false);

  /// True if [text] contains any blocked word as a whole word.
  static bool isBlocked(String text) {
    final words = _words(text).toSet();
    return blockedWords.any(words.contains);
  }

  /// True if [text] mentions a person or part of a person.
  static bool mentionsPerson(String text) {
    final words = _words(text).toSet();
    return personWords.any(words.contains);
  }

  /// A short, plain, lowercase object name, or null if it cannot be used.
  static String? cleanName(Object? raw) {
    if (raw is! String) return null;
    final name = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (name.length < 2 || name.length > maxNameLength) return null;
    if (!RegExp(r"^[a-z][a-z' -]*$").hasMatch(name)) return null;
    if (name.split(' ').length > maxNameWords) return null;
    return name;
  }

  /// Up to [maxFacts] short, simple, checked sentences.
  static List<String> cleanFacts(Object? raw) {
    if (raw is! List) return const <String>[];
    final facts = <String>[];
    for (final item in raw) {
      if (item is! String) continue;
      final fact = item.trim().replaceAll(RegExp(r'\s+'), ' ');
      final lower = fact.toLowerCase();
      if (fact.length < minFactLength || fact.length > maxFactLength) continue;
      if (!fact.endsWith('.') && !fact.endsWith('!')) continue;
      if (RegExp(r'[0-9]').hasMatch(fact)) continue; // no invented numbers
      if (lower.contains('http') ||
          lower.contains('www.') ||
          lower.contains('.com') ||
          fact.contains('@')) {
        continue;
      }
      if (fact.split(' ').length > maxFactWords) continue;
      if (isBlocked(fact)) continue;
      if (hedgeWords.any(lower.contains)) continue;
      if (facts.any((existing) => existing.toLowerCase() == lower)) continue;
      facts.add(fact);
      if (facts.length == maxFacts) break;
    }
    return facts;
  }

  /// The movement ID if it is in the allowed set, otherwise null.
  static String? cleanMovementId(Object? raw, Set<String> allowed) {
    if (raw is! String) return null;
    final id = raw.trim();
    return allowed.contains(id) ? id : null;
  }

  /// "a tennis ball", "an apple".
  static String withArticle(String name) {
    final first = name.isEmpty ? '' : name[0].toLowerCase();
    final article = 'aeiou'.contains(first) ? 'an' : 'a';
    return '$article $name';
  }

  /// "A tennis ball" with a capital letter.
  static String sentenceCase(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

  /// A safe identifier for the discovery journal: "tennis_ball".
  static String slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z]+"), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  static double _confidence(Object? raw) =>
      raw is num ? raw.toDouble().clamp(0.0, 1.0).toDouble() : 0.0;

  /// Decides what to do with the AI's answer. Does not call the network.
  ///
  /// Order matters: people first, then unsuitable pictures, then the game's own
  /// catalogue, and only then a brand-new object.
  static OpenOutcome evaluate(
    Map<String, dynamic> json, {
    required Set<String> allowedCatalogIds,
    required Set<String> movementIds,
  }) {
    if (json['contains_person'] == true) return const OpenOutcome.person();
    if (json['safe_for_children'] == false) return const OpenOutcome.blocked();

    final confidence = _confidence(json['confidence']);
    final catalogRaw = json['catalog_id'];
    final catalogId = catalogRaw is String ? catalogRaw.trim() : '';
    if (allowedCatalogIds.contains(catalogId) &&
        confidence >= catalogConfidence) {
      return OpenOutcome.catalog(catalogId, confidence);
    }

    // From here on the AI's own words may be shown, so be strict: the picture
    // must be explicitly marked suitable.
    if (json['safe_for_children'] != true) return const OpenOutcome.unsure();

    final nameRaw = json['object_name'];
    if (nameRaw is String) {
      if (mentionsPerson(nameRaw)) return const OpenOutcome.person();
      if (isBlocked(nameRaw)) return const OpenOutcome.blocked();
    }
    final name = cleanName(nameRaw);
    if (name == null || confidence < nameConfidence) {
      return OpenOutcome.unsure(confidence);
    }

    return OpenOutcome.find(
      name: name,
      facts: cleanFacts(json['facts']),
      fitsClue: json['fits_clue'] == true,
      confidence: confidence,
      movementId: cleanMovementId(json['movement_id'], movementIds),
    );
  }
}
