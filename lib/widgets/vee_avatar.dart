import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/assets/optional_assets.dart';

/// Vee's poses. The first three ship with the game. The rest are optional
/// artwork (see docs/ASSET_PROMPTS.md); until a pose's file is added, Vee
/// shows the closest pose that exists, so nothing ever looks broken.
enum VeePose {
  happy,
  encourage,
  celebration,
  wave,
  thinking,
  surprised,
  sleepy,

  /// Crouching with a magnifying glass (SPOT).
  spot,
}

/// Shows Vee and lets her react to what the child does.
///
/// * Vee gently "breathes" while idle (turned off by the system's
///   reduce-motion setting).
/// * Change [pose] to cross-fade to another pose.
/// * Change [bounce] (for example add 1 to a counter) to make her hop.
class VeeAvatar extends StatefulWidget {
  final VeePose pose;
  final int bounce;

  /// Turn off the idle breathing (for example for a tiny avatar).
  final bool idle;

  const VeeAvatar({
    super.key,
    this.pose = VeePose.happy,
    this.bounce = 0,
    this.idle = true,
  });

  static const String _happy = 'assets/vee/vee_happy_idle.webp';
  static const String _encourage = 'assets/vee/vee_encourage.webp';
  static const String _celebration = 'assets/vee/vee_celebration.webp';

  /// The file for [pose], or the closest shipped pose if its own file has not
  /// been added yet.
  static String assetFor(VeePose pose) {
    String own(String name, String fallback) {
      final path = 'assets/vee/$name.webp';
      return OptionalAssets.has(path) ? path : fallback;
    }

    return switch (pose) {
      VeePose.happy => _happy,
      VeePose.encourage => _encourage,
      VeePose.celebration => _celebration,
      VeePose.wave => own('vee_wave', _happy),
      VeePose.thinking => own('vee_thinking', _encourage),
      VeePose.surprised => own('vee_surprised', _celebration),
      VeePose.sleepy => own('vee_sleepy', _happy),
      VeePose.spot => own('vee_spot', _encourage),
    };
  }

  @override
  State<VeeAvatar> createState() => _VeeAvatarState();
}

class _VeeAvatarState extends State<VeeAvatar> with TickerProviderStateMixin {
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  bool _breathing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wantBreath = widget.idle && !MediaQuery.disableAnimationsOf(context);
    if (wantBreath && !_breathing) {
      _breathing = true;
      _breath.repeat(reverse: true);
    } else if (!wantBreath && _breathing) {
      _breathing = false;
      _breath.stop();
    }
  }

  @override
  void didUpdateWidget(covariant VeeAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bounce != widget.bounce) {
      _hop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = VeeAvatar.assetFor(widget.pose);
    final picture = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Image.asset(
        asset,
        key: ValueKey<String>(asset),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return picture;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_hop, _breath]),
        child: picture,
        builder: (context, child) {
          // A 0 -> 1 -> 0 arc, so Vee jumps up and lands where she started.
          final arc = math.sin(_hop.value * math.pi);
          final breath = Curves.easeInOut.transform(_breath.value);
          return Transform.translate(
            offset: Offset(0, -22 * arc - 3 * breath),
            child: Transform.scale(
              scale: 1 + 0.05 * arc + 0.012 * breath,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
