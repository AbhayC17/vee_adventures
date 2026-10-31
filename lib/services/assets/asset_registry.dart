class AssetRegistry {
  final List<String> usable = const [
    'vee.happy',
    'vee.encourage',
    'vee.celebration',
    'vee.wave',
    'vee.spot',
    'vee.thinking',
    'vee.surprised',
    'vee.sleepy',
    'scene.meadow',
    'scene.indoor',
    'scene.closeup',
    'door.closed',
    'door.open',
    'items.*',
  ];

  final List<String> procedural = const [
    'magical.door',
    'magical.portal',
    'treasure.chest',
    'stepping.stones',
    'magical.tree',
    'adventure.star',
    'butterfly',
    'magical.egg',
    'magical.flower',
    'discovery.badge',
  ];

  String promptContext() =>
      'Available static assets: ${usable.join(', ')}. Procedural visuals available: ${procedural.join(', ')}. Never request missing image assets; choose only these visuals.';
}
