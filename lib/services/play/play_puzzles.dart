import 'dart:math';

import '../../models/content_catalog.dart';
import '../../models/environment_mode.dart';
import '../discovery_engine.dart';

/// The kinds of small puzzle a child can meet.
enum PlayPuzzleKind {
  /// Drag (or tap) the named item into the glowing space.
  dragMatch,

  /// Three things belong together; tap the one that does not.
  oddOneOut,

  /// Finish a short pattern of pictures.
  pattern,

  /// Read Vee's clue and tap the object it describes.
  clueGuess,
}

/// One ready-to-show puzzle. [options] always contains [answer] exactly once.
class PlayPuzzle {
  final PlayPuzzleKind kind;
  final String title;
  final String prompt;
  final CatalogItem answer;
  final List<CatalogItem> options;

  /// Pattern puzzles only: the pictures shown before the "?" slot.
  final List<CatalogItem> sequence;

  const PlayPuzzle({
    required this.kind,
    required this.title,
    required this.prompt,
    required this.answer,
    required this.options,
    this.sequence = const <CatalogItem>[],
  });
}

/// Builds puzzles from the curated content catalog.
///
/// Everything here is local and instant. The correct answer is always part of
/// the options, and options are shuffled so the answer is not always in the
/// same place.
class PlayPuzzleBuilder {
  PlayPuzzleBuilder._();

  /// Items for a setting. If the setting is small (for example the beach has
  /// two items) it is topped up with items from other settings of the same
  /// mode so there are always enough choices.
  static List<CatalogItem> poolForSetting(
    String settingId,
    EnvironmentMode mode, {
    int minimum = 4,
  }) {
    final result = <CatalogItem>[...ContentCatalog.forSetting(settingId)];
    if (result.length >= minimum) return result;
    for (final item in modePool(mode)) {
      if (result.every((e) => e.id != item.id)) result.add(item);
      if (result.length >= minimum) break;
    }
    return result;
  }

  /// Every catalog item used by any regular or special setting of [mode].
  static List<CatalogItem> modePool(EnvironmentMode mode) {
    final seen = <String>{};
    final result = <CatalogItem>[];
    for (final setting in ContentCatalog.settings) {
      if (setting.mode != mode) continue;
      for (final item in ContentCatalog.forSetting(setting.id)) {
        if (seen.add(item.id)) result.add(item);
      }
    }
    return result;
  }

  /// Picks a puzzle type that suits the child's age and builds it.
  /// Three-year-olds only get the simplest kinds.
  static PlayPuzzle choose({
    required List<CatalogItem> pool,
    required EnvironmentMode mode,
    required Random random,
    CatalogItem? target,
    int age = 4,
    int optionCount = 3,
  }) {
    final kinds = <PlayPuzzleKind>[
      PlayPuzzleKind.dragMatch,
      PlayPuzzleKind.pattern,
      if (age >= 4) PlayPuzzleKind.oddOneOut,
    ];
    return build(
      kinds[random.nextInt(kinds.length)],
      pool: pool,
      mode: mode,
      random: random,
      target: target,
      age: age,
      optionCount: optionCount,
    );
  }

  static PlayPuzzle build(
    PlayPuzzleKind kind, {
    required List<CatalogItem> pool,
    required EnvironmentMode mode,
    required Random random,
    CatalogItem? target,
    int age = 4,
    int optionCount = 3,
    int clueCount = 3,
  }) {
    if (pool.isEmpty) {
      throw ArgumentError('A puzzle needs at least one catalog item.');
    }
    switch (kind) {
      case PlayPuzzleKind.dragMatch:
        return _dragMatch(pool, random, target, optionCount);
      case PlayPuzzleKind.oddOneOut:
        return _oddOneOut(pool, mode, random) ??
            _dragMatch(pool, random, target, optionCount);
      case PlayPuzzleKind.pattern:
        return _pattern(pool, mode, random, age) ??
            _dragMatch(pool, random, target, optionCount);
      case PlayPuzzleKind.clueGuess:
        return _clueGuess(pool, random, target, optionCount, clueCount);
    }
  }

  // ── builders ────────────────────────────────────────────────────────────

  static CatalogItem _pickTarget(
    List<CatalogItem> pool,
    Random random,
    CatalogItem? target,
  ) => target ?? pool[random.nextInt(pool.length)];

  /// The answer plus distractors, shuffled. The answer is always included,
  /// even when it is not part of [pool].
  static List<CatalogItem> _optionsWith(
    CatalogItem answer,
    List<CatalogItem> pool,
    Random random,
    int count,
  ) {
    final distractors = pool.where((e) => e.id != answer.id).toList()
      ..shuffle(random);
    final options = <CatalogItem>[
      answer,
      ...distractors.take(max(1, count - 1)),
    ]..shuffle(random);
    return options;
  }

  static PlayPuzzle _dragMatch(
    List<CatalogItem> pool,
    Random random,
    CatalogItem? target,
    int optionCount,
  ) {
    final answer = _pickTarget(pool, random, target);
    return PlayPuzzle(
      kind: PlayPuzzleKind.dragMatch,
      title: '🧩 The clue puzzle',
      prompt:
          'One of these belongs in the glowing space. Find the ${answer.name}!',
      answer: answer,
      options: _optionsWith(answer, pool, random, optionCount),
    );
  }

  static PlayPuzzle _clueGuess(
    List<CatalogItem> pool,
    Random random,
    CatalogItem? target,
    int optionCount,
    int clueCount,
  ) {
    final answer = _pickTarget(pool, random, target);
    final clues = List<String>.of(DiscoveryEngine.forItem(answer).mysteryClues)
      ..shuffle(random);
    return PlayPuzzle(
      kind: PlayPuzzleKind.clueGuess,
      title: '🕵️ Vee’s mystery clue',
      prompt: clues.take(max(1, clueCount)).join('\n'),
      answer: answer,
      options: _optionsWith(answer, pool, random, max(optionCount, 4)),
    );
  }

  static PlayPuzzle? _oddOneOut(
    List<CatalogItem> pool,
    EnvironmentMode mode,
    Random random,
  ) {
    List<CatalogItem>? attempt(List<CatalogItem> source) {
      final byCategory = <String, List<CatalogItem>>{};
      for (final item in source) {
        byCategory.putIfAbsent(item.category, () => <CatalogItem>[]).add(item);
      }
      final groups = byCategory.entries
          .where((entry) => entry.value.length >= 3)
          .map((entry) => entry.key)
          .toList();
      if (groups.isEmpty) return null;
      final group = groups[random.nextInt(groups.length)];
      final others = source.where((item) => item.category != group).toList();
      if (others.isEmpty) return null;
      final together = List<CatalogItem>.of(byCategory[group]!)
        ..shuffle(random);
      final odd = others[random.nextInt(others.length)];
      // The odd one is last in the returned list.
      return <CatalogItem>[...together.take(3), odd];
    }

    final picked = attempt(pool) ?? attempt(modePool(mode));
    if (picked == null) return null;
    final odd = picked.last;
    return PlayPuzzle(
      kind: PlayPuzzleKind.oddOneOut,
      title: '🔎 Odd one out',
      prompt: 'Three of these belong together. Tap the one that does not!',
      answer: odd,
      options: List<CatalogItem>.of(picked)..shuffle(random),
    );
  }

  static PlayPuzzle? _pattern(
    List<CatalogItem> pool,
    EnvironmentMode mode,
    Random random,
    int age,
  ) {
    var source = <CatalogItem>[...pool];
    if (source.length < 4) {
      for (final item in modePool(mode)) {
        if (source.every((e) => e.id != item.id)) source.add(item);
      }
    }
    if (source.length < 4) return null;
    source = List<CatalogItem>.of(source)..shuffle(random);
    final a = source[0];
    final b = source[1];
    final c = source[2];
    final extra = source[3];

    if (age <= 4) {
      // A B A B ?  ->  A
      return PlayPuzzle(
        kind: PlayPuzzleKind.pattern,
        title: '🔁 Finish the pattern',
        prompt: 'What comes next?',
        answer: a,
        sequence: <CatalogItem>[a, b, a, b],
        options: <CatalogItem>[a, b, extra]..shuffle(random),
      );
    }
    // A B C A B ?  ->  C
    return PlayPuzzle(
      kind: PlayPuzzleKind.pattern,
      title: '🔁 Finish the pattern',
      prompt: 'What comes next?',
      answer: c,
      sequence: <CatalogItem>[a, b, c, a, b],
      options: <CatalogItem>[a, b, c]..shuffle(random),
    );
  }
}
