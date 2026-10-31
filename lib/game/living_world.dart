import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'world_adventure_game.dart';

/// Hosts [WorldAdventureGame] inside the normal Flutter widget tree.
///
/// This (together with the game) is the only place Flame is used. Give it a
/// size with `Positioned.fill`, `Expanded` or `SizedBox`.
class LivingWorld extends StatefulWidget {
  /// How much of the world is revealed (0–4). See [WorldAdventureGame].
  final int revealLevel;

  /// Start with a confetti and star celebration.
  final bool celebrateOnStart;

  /// Called with the running tap total after every tap.
  final ValueChanged<int>? onInteraction;

  /// Called with the running total whenever a star is caught.
  final ValueChanged<int>? onStarCaught;

  const LivingWorld({
    super.key,
    this.revealLevel = 0,
    this.celebrateOnStart = false,
    this.onInteraction,
    this.onStarCaught,
  });

  @override
  State<LivingWorld> createState() => _LivingWorldState();
}

class _LivingWorldState extends State<LivingWorld> {
  late final WorldAdventureGame _game;

  @override
  void initState() {
    super.initState();
    _game = WorldAdventureGame(
      revealLevel: widget.revealLevel,
      // Read the widget's callbacks at call time so a rebuilt parent can
      // hand in new ones without restarting the game.
      onInteraction: (taps) => widget.onInteraction?.call(taps),
      onStarCaught: (stars) => widget.onStarCaught?.call(stars),
    );
    if (widget.celebrateOnStart) _game.celebrate();
  }

  @override
  void didUpdateWidget(covariant LivingWorld oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.revealLevel = widget.revealLevel;
  }

  @override
  Widget build(BuildContext context) =>
      GameWidget<WorldAdventureGame>(game: _game);
}
