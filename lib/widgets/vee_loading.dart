import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'vee_avatar.dart';

/// A friendly waiting screen: Vee waves above three bouncing dots.
class VeeLoading extends StatelessWidget {
  final String message;

  const VeeLoading({super.key, this.message = 'Vee is getting ready…'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeeTokens.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 150,
              height: 180,
              child: VeeAvatar(pose: VeePose.wave),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: VeeTokens.textOnLight,
              ),
            ),
            const SizedBox(height: 14),
            const BouncingDots(),
          ],
        ),
      ),
    );
  }
}

/// Three dots that hop one after another.
class BouncingDots extends StatefulWidget {
  const BouncingDots({super.key});

  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(
                    0,
                    -9 *
                        math.max(
                          0.0,
                          math.sin((_c.value - i * .14) * math.pi * 2),
                        ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: VeeTokens.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
