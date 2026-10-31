import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

/// Shows the star total. When stars are added the number counts up and the
/// whole badge gives a little pulse.
class StarCounter extends StatefulWidget {
  final int stars;

  const StarCounter({super.key, required this.stars});

  @override
  State<StarCounter> createState() => _StarCounterState();
}

class _StarCounterState extends State<StarCounter> {
  bool _pulse = false;

  @override
  void didUpdateWidget(covariant StarCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stars > oldWidget.stars) {
      setState(() => _pulse = true);
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted) setState(() => _pulse = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '${widget.stars} stars',
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: _pulse ? 1.18 : 1.0,
          duration: Duration(milliseconds: reduceMotion ? 0 : 220),
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: VeeTokens.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: VeeTokens.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  '★',
                  style: TextStyle(fontSize: 20, color: VeeTokens.yellow),
                ),
                const SizedBox(width: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: widget.stars.toDouble()),
                  duration: Duration(milliseconds: reduceMotion ? 0 : 600),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => Text(
                    '${value.round()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: VeeTokens.textOnLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
