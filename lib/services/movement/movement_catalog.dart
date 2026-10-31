import 'dart:math';

import '../../models/activity.dart';
import '../activity_selection/movement_profile.dart';

/// Metadata and age-appropriate instructions for one reusable movement.
///
/// Keep IDs stable: movement animation assets and episode content refer to IDs.
class MovementDefinition {
  final String id;
  final String emoji;
  final String label;
  final String instruction;
  final int baseCount;

  const MovementDefinition({
    required this.id,
    required this.emoji,
    required this.label,
    required this.instruction,
    required this.baseCount,
  });
}

/// One shared catalog for PLAY and future standalone MOVE challenges.
class MovementCatalog {
  MovementCatalog._();

  static const List<MovementDefinition> all = <MovementDefinition>[
    MovementDefinition(
      id: 'bear_crawl',
      emoji: '🐻',
      label: 'Bear Crawl',
      instruction: 'Use your hands and feet on the floor, bottom up like a bear. Take small steps forward.',
      baseCount: 4,
    ),
    MovementDefinition(
      id: 'high_jump',
      emoji: '🚀',
      label: 'High Jump',
      instruction: 'Bend your knees, swing your arms, jump up high if comfortable, and land softly.',
      baseCount: 3,
    ),
    MovementDefinition(
      id: 'jumping_jacks',
      emoji: '⭐',
      label: 'Jumping Jacks',
      instruction: 'Jump or step your feet apart as your arms go up, then return to feet together.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'frog_hops',
      emoji: '🐸',
      label: 'Frog Hops',
      instruction:
          'Bend like a frog, make a small hop or step, and land softly.',
      baseCount: 5,
    ),
    MovementDefinition(
      id: 'crab_walk',
      emoji: '🦀',
      label: 'Crab Walk',
      instruction: 'With hands behind you and feet on the floor, lift your tummy a little and take small crab steps.',
      baseCount: 4,
    ),
    MovementDefinition(
      id: 'flamingo_balance',
      emoji: '🦩',
      label: 'Flamingo Balance',
      instruction: 'Stand on one foot for a moment near a safe support, then switch sides.',
      baseCount: 3,
    ),
    MovementDefinition(
      id: 'ninja_side_steps',
      emoji: '🥷',
      label: 'Ninja Side Steps',
      instruction: 'Take quiet side steps left and right like a sneaky ninja.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'star_jumps',
      emoji: '🌟',
      label: 'Star Jumps',
      instruction: 'Move from a small shape into a wide star shape, then return gently. You may step instead of jumping.',
      baseCount: 5,
    ),
    MovementDefinition(
      id: 'kangaroo_hops',
      emoji: '🦘',
      label: 'Kangaroo Hops',
      instruction: 'Keep your feet close together and make gentle little hops or springy steps.',
      baseCount: 5,
    ),
    MovementDefinition(
      id: 'penguin_waddle',
      emoji: '🐧',
      label: 'Penguin Waddle',
      instruction: 'Keep your feet close, bend your knees a little, and waddle side to side.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'duck_walk',
      emoji: '🦆',
      label: 'Duck Walk',
      instruction:
          'Bend your knees into a small squat and take tiny steps like a duck.',
      baseCount: 4,
    ),
    MovementDefinition(
      id: 'inchworm_walk',
      emoji: '🐛',
      label: 'Inchworm Walk',
      instruction: 'Bend down only as far as comfortable, walk your hands forward, then walk your feet toward your hands.',
      baseCount: 3,
    ),
    MovementDefinition(
      id: 'side_hops',
      emoji: '↔️',
      label: 'Side Hops',
      instruction: 'Make small hops from one side to the other over an imaginary line, or step across it.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'skater_steps',
      emoji: '⛸️',
      label: 'Skater Steps',
      instruction: 'Step or gently hop side to side like a speedy skater.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'tippy_toe_sneak',
      emoji: '🕵️',
      label: 'Tippy-Toe Sneak',
      instruction: 'Walk slowly on your tiptoes like you are sneaking past a sleeping dragon.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'giant_steps',
      emoji: '👣',
      label: 'Giant Steps',
      instruction:
          'Take big, steady steps across a clear space like a friendly giant.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'tiny_steps',
      emoji: '🐜',
      label: 'Tiny Steps',
      instruction:
          'Take lots of very small steps like a tiny ant exploring a path.',
      baseCount: 8,
    ),
    MovementDefinition(
      id: 'windmill_arms',
      emoji: '🌬️',
      label: 'Windmill Arms',
      instruction: 'Stand tall and make big, slow circles with your arms like a windmill.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'cross_body_taps',
      emoji: '❌',
      label: 'Cross-Body Taps',
      instruction: 'Tap your right hand to your left knee, then your left hand to your right knee. Go slowly.',
      baseCount: 8,
    ),
    MovementDefinition(
      id: 'mountain_climbers',
      emoji: '🏔️',
      label: 'Mountain Climbers',
      instruction: 'With hands supported on a stable surface or the floor, bring one knee forward at a time. Go gently.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'bear_side_walk',
      emoji: '🐻',
      label: 'Bear Side Walk',
      instruction: 'Stay low only as far as comfortable and take a few careful sideways steps.',
      baseCount: 4,
    ),
    MovementDefinition(
      id: 'frog_squat_reach',
      emoji: '🐸',
      label: 'Frog Squat Reach',
      instruction: 'Bend down a little like a frog, stand tall, and reach your hands toward the sky.',
      baseCount: 5,
    ),
    MovementDefinition(
      id: 'star_reach',
      emoji: '✨',
      label: 'Star Reach',
      instruction: 'Stretch one hand high and the other low, then switch sides like a twinkling star.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'airplane_balance',
      emoji: '✈️',
      label: 'Airplane Balance',
      instruction: 'Stand on two feet or one foot and stretch your arms sideways like airplane wings. Stay near a safe support.',
      baseCount: 3,
    ),
    MovementDefinition(
      id: 'lateral_lunges',
      emoji: '↔️',
      label: 'Side Lunges',
      instruction: 'Step wide to one side, bend that knee gently, then return and switch sides.',
      baseCount: 5,
    ),
    MovementDefinition(
      id: 'squat_to_reach',
      emoji: '⬆️',
      label: 'Squat and Sky Reach',
      instruction: 'Make a small squat, stand tall, and stretch both hands toward the sky.',
      baseCount: 5,
    ),
    MovementDefinition(
      id: 'hopscotch_hops',
      emoji: '🔢',
      label: 'Hopscotch Hops',
      instruction: 'Hop on one foot, then the other, like following a pretend hopscotch path. Stepping is fine too.',
      baseCount: 6,
    ),
    MovementDefinition(
      id: 'seal_claps',
      emoji: '🦭',
      label: 'Seal Claps',
      instruction: 'Stand tall and clap your hands together in front of you like a cheerful seal.',
      baseCount: 8,
    ),
    MovementDefinition(
      id: 'robot_steps',
      emoji: '🤖',
      label: 'Robot Steps',
      instruction: 'Take stiff, careful steps with robot arms, then turn and go the other way.',
      baseCount: 8,
    ),
    MovementDefinition(
      id: 'tree_pose_switch',
      emoji: '🌳',
      label: 'Tree Pose Switch',
      instruction: 'Balance on two feet or rest one foot lightly against the other leg, then switch sides like a swaying tree.',
      baseCount: 4,
    ),
  ];

  static const Set<String> _gentleIds = <String>{
    'flamingo_balance',
    'penguin_waddle',
    'tippy_toe_sneak',
    'tiny_steps',
    'windmill_arms',
    'cross_body_taps',
    'star_reach',
    'airplane_balance',
    'seal_claps',
    'robot_steps',
    'tree_pose_switch',
  };

  static const Set<String> _steadyExcludedIds = <String>{
    'high_jump',
    'star_jumps',
    'mountain_climbers',
  };

  static final Map<String, MovementDefinition> _byId =
      <String, MovementDefinition>{
        for (final MovementDefinition movement in all) movement.id: movement,
      };

  static MovementDefinition? find(String id) => _byId[id];

  /// Returns a safe fallback definition for older or unknown movement IDs.
  static MovementDefinition resolve(String id) {
    final known = _byId[id];
    if (known != null) return known;
    final readable = id
        .split('_')
        .where((String part) => part.isNotEmpty)
        .map((String part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    return MovementDefinition(
      id: id,
      emoji: '⭐',
      label: readable.isEmpty ? 'Move' : readable,
      instruction: 'Try this move at your own pace in a clear space. Ask a grown-up for help if needed.',
      baseCount: 4,
    );
  }

  static List<MovementDefinition> forProfile(MovementProfile profile) {
    final Iterable<MovementDefinition> filtered = switch (profile) {
      MovementProfile.energetic => all,
      MovementProfile.steady => all.where(
        (MovementDefinition m) => !_steadyExcludedIds.contains(m.id),
      ),
      MovementProfile.gentle => all.where(
        (MovementDefinition m) => _gentleIds.contains(m.id),
      ),
    };
    return List<MovementDefinition>.unmodifiable(filtered);
  }

  static int countFor(
    MovementDefinition definition,
    MovementProfile profile, {
    int age = 4,
  }) {
    // The catalog combines profile preference and age scaling in one place.
    // Clamp age defensively because older saved profiles may contain bad data.
    final safeAge = age.clamp(2, 6).toInt();
    final ageMultiplier = switch (safeAge) {
      2 => 0.75,
      3 => 0.85,
      4 => 1.0,
      5 => 1.05,
      _ => 1.10,
    };
    final requested =
        (definition.baseCount * profile.movementMultiplier * ageMultiplier)
            .round();
    return requested.clamp(2, 10).toInt();
  }

  static MovementStep stepFor(
    String id,
    MovementProfile profile, {
    int age = 4,
  }) {
    final definition = resolve(id);
    return MovementStep(definition.id, countFor(definition, profile, age: age));
  }

  static bool validate() {
    final ids = all.map((MovementDefinition m) => m.id).toList();
    return ids.length == ids.toSet().length &&
        all.every(
          (MovementDefinition m) =>
              m.id.isNotEmpty &&
              m.label.trim().isNotEmpty &&
              m.instruction.trim().isNotEmpty &&
              m.baseCount >= 1,
        );
  }
}

/// Shuffles a profile-specific pool and prevents repeats until that pool has
/// been exhausted. A profile change starts a fresh bag with eligible moves.
class MovementBag {
  MovementBag({Random? random}) : _random = random ?? Random();

  final Random _random;
  MovementProfile? _profile;
  int? _age;
  List<MovementDefinition> _bag = <MovementDefinition>[];
  int _cursor = 0;

  int get remaining => _bag.length - _cursor;

  void reset() {
    _profile = null;
    _age = null;
    _bag = <MovementDefinition>[];
    _cursor = 0;
  }

  MovementStep nextStep(MovementProfile profile, {int age = 4}) {
    final safeAge = age.clamp(2, 6).toInt();
    if (_profile != profile || _age != safeAge || _cursor >= _bag.length) {
      _profile = profile;
      _age = safeAge;
      _bag = List<MovementDefinition>.from(MovementCatalog.forProfile(profile))
        ..shuffle(_random);
      _cursor = 0;
    }

    if (_bag.isEmpty) {
      throw StateError('No movements are registered for $profile.');
    }

    final MovementDefinition selected = _bag[_cursor++];
    return MovementCatalog.stepFor(selected.id, profile, age: safeAge);
  }
}
