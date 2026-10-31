import 'package:flutter/material.dart';

/// Fades and floats its child in, [index] steps after the screen opens.
/// Give each item on a screen the next index for a gentle one-by-one reveal.
class Entrance extends StatefulWidget {
  final Widget child;
  final int index;

  const Entrance({super.key, required this.child, this.index = 0});

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  static const int _stepMs = 90;
  static const int _runMs = 420;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _runMs + widget.index * _stepMs),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      (widget.index * _stepMs) / (_runMs + widget.index * _stepMs),
      1,
      curve: Curves.easeOutBack,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 26),
            child: Transform.scale(scale: .94 + .06 * v, child: child),
          ),
        );
      },
    );
  }
}
