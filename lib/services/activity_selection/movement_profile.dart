enum MovementProfile { gentle, steady, energetic }

MovementProfile movementProfileFor(String preference) {
  switch (preference.trim().toLowerCase()) {
    case 'hop & reach':
    case 'zoom & jump':
    case 'energetic':
      return MovementProfile.energetic;
    case 'march & clap':
    case 'move & groove':
    case 'steady':
      return MovementProfile.steady;
    case 'balance & stretch':
    case 'calm & balance':
    case 'gentle':
    default:
      return MovementProfile.gentle;
  }
}

extension MovementProfileX on MovementProfile {
  String get label => switch (this) {
    MovementProfile.energetic => 'Energetic Explorer',
    MovementProfile.steady => 'Steady Explorer',
    MovementProfile.gentle => 'Gentle Explorer',
  };

  String get description => switch (this) {
    MovementProfile.energetic =>
      'More action, bigger challenges and extra movement.',
    MovementProfile.steady =>
      'A balanced mix of movement, discovery and puzzles.',
    MovementProfile.gentle => 'A calmer pace with smaller movement goals.',
  };

  double get movementMultiplier => switch (this) {
    MovementProfile.energetic => 1.25,
    MovementProfile.steady => 1.0,
    MovementProfile.gentle => 0.70,
  };

  int scaleCount(int base) {
    final scaled = (base * movementMultiplier).round();
    return scaled.clamp(2, 10);
  }

  int get exploreInteractions => switch (this) {
    MovementProfile.energetic => 8,
    MovementProfile.steady => 7,
    MovementProfile.gentle => 5,
  };

  int get exploreDiscoveryGate => switch (this) {
    MovementProfile.energetic => 3,
    MovementProfile.steady => 3,
    MovementProfile.gentle => 2,
  };
}
