import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/movement_animation_registry.dart';

/// Plays frame-by-frame SVG artwork for a Vee movement.
///
/// If the configured SVG files are not present yet, [fallback] is shown.
/// This lets the game keep running while artwork is still being created.
class MovementVeeAnimation extends StatefulWidget {
  final String movementId;
  final Widget fallback;
  final bool loop;
  final BoxFit fit;

  const MovementVeeAnimation({
    super.key,
    required this.movementId,
    required this.fallback,
    this.loop = true,
    this.fit = BoxFit.contain,
  });

  @override
  State<MovementVeeAnimation> createState() => _MovementVeeAnimationState();
}

class _MovementVeeAnimationState extends State<MovementVeeAnimation> {
  Timer? _timer;
  int _frame = 1;

  MovementAnimationConfig? get _config =>
      MovementAnimationRegistry.get(widget.movementId);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant MovementVeeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movementId != widget.movementId) {
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    _frame = 1;

    final config = _config;
    if (config == null || !config.enabled || config.frameCount <= 0 || config.fps <= 0) {
      return;
    }

    _timer = Timer.periodic(
      Duration(milliseconds: (1000 / config.fps).round()),
      (_) {
        if (!mounted) return;
        setState(() {
          if (_frame >= config.frameCount) {
            if (widget.loop) {
              _frame = 1;
            } else {
              _timer?.cancel();
            }
          } else {
            _frame++;
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;

    if (config == null || !config.enabled || config.frameCount <= 0) {
      return widget.fallback;
    }

    final assetPath = config.assetPath(_frame);

    return SvgPicture.asset(
      assetPath,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      placeholderBuilder: (_) => widget.fallback,
    );
  }
}
