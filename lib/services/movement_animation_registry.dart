/// Configuration for one animated Vee movement.
///
/// The movement ID MUST match MovementStep.name.
class MovementAnimationConfig {
  final String id;
  final int frameCount;
  final int fps;
  final bool enabled;

  const MovementAnimationConfig({
    required this.id,
    required this.frameCount,
    required this.fps,
    this.enabled = false,
  });

  String assetPath(int frame) {
    final frameName = frame.toString().padLeft(2, '0');
    return 'assets/vee/movements/${id}_$frameName.svg';
  }
}

/// Single source of truth for all 30 Play movement animations.
///
/// All entries start disabled so the app safely uses static Vee until the
/// illustrator supplies the SVG frames. When a movement's files are ready,
/// change only enabled: false -> true.
class MovementAnimationRegistry {
  static const Map<String, MovementAnimationConfig> animations = {
    'bear_crawl': MovementAnimationConfig(
      id: 'bear_crawl',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'high_jump': MovementAnimationConfig(
      id: 'high_jump',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'jumping_jacks': MovementAnimationConfig(
      id: 'jumping_jacks',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'frog_hops': MovementAnimationConfig(
      id: 'frog_hops',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'crab_walk': MovementAnimationConfig(
      id: 'crab_walk',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'flamingo_balance': MovementAnimationConfig(
      id: 'flamingo_balance',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'ninja_side_steps': MovementAnimationConfig(
      id: 'ninja_side_steps',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'star_jumps': MovementAnimationConfig(
      id: 'star_jumps',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'kangaroo_hops': MovementAnimationConfig(
      id: 'kangaroo_hops',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'penguin_waddle': MovementAnimationConfig(
      id: 'penguin_waddle',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'duck_walk': MovementAnimationConfig(
      id: 'duck_walk',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'inchworm_walk': MovementAnimationConfig(
      id: 'inchworm_walk',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'side_hops': MovementAnimationConfig(
      id: 'side_hops',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'skater_steps': MovementAnimationConfig(
      id: 'skater_steps',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'tippy_toe_sneak': MovementAnimationConfig(
      id: 'tippy_toe_sneak',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'giant_steps': MovementAnimationConfig(
      id: 'giant_steps',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'tiny_steps': MovementAnimationConfig(
      id: 'tiny_steps',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'windmill_arms': MovementAnimationConfig(
      id: 'windmill_arms',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'cross_body_taps': MovementAnimationConfig(
      id: 'cross_body_taps',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'mountain_climbers': MovementAnimationConfig(
      id: 'mountain_climbers',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'bear_side_walk': MovementAnimationConfig(
      id: 'bear_side_walk',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'frog_squat_reach': MovementAnimationConfig(
      id: 'frog_squat_reach',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'star_reach': MovementAnimationConfig(
      id: 'star_reach',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'airplane_balance': MovementAnimationConfig(
      id: 'airplane_balance',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'lateral_lunges': MovementAnimationConfig(
      id: 'lateral_lunges',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'squat_to_reach': MovementAnimationConfig(
      id: 'squat_to_reach',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'hopscotch_hops': MovementAnimationConfig(
      id: 'hopscotch_hops',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'seal_claps': MovementAnimationConfig(
      id: 'seal_claps',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'robot_steps': MovementAnimationConfig(
      id: 'robot_steps',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
    'tree_pose_switch': MovementAnimationConfig(
      id: 'tree_pose_switch',
      frameCount: 8,
      fps: 10,
      enabled: false,
    ),
  };

  static MovementAnimationConfig? get(String movementId) {
    return animations[movementId];
  }
}
