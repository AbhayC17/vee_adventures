import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../services/explore/explore_board.dart';
import 'haptics.dart';
import 'item_icon.dart';
import 'juicy_tap.dart';

/// The look of the thing something is hiding behind.
enum HideStyle { bush, rock, log, basket, box, cushion }

/// One hiding spot on the EXPLORE board.
///
/// Closed, it wiggles a little to invite a tap. When tapped it shakes, then the
/// cover shrinks away and what was hiding pops out with a burst of sparkles.
class HidingSpotView extends StatefulWidget {
  final HideSpot spot;
  final bool opened;

  /// True when an item is found for the first time (shows a "NEW!" tag).
  final bool isNew;
  final HideStyle style;
  final Animation<double> idle;
  final VoidCallback onTap;

  const HidingSpotView({
    super.key,
    required this.spot,
    required this.opened,
    required this.isNew,
    required this.style,
    required this.idle,
    required this.onTap,
  });

  static const double width = 132;
  static const double height = 120;

  @override
  State<HidingSpotView> createState() => _HidingSpotViewState();
}

class _HidingSpotViewState extends State<HidingSpotView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    if (widget.opened || MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant HidingSpotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.opened && widget.opened) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _reveal.value = 1;
      } else {
        _reveal.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  bool get _golden => widget.spot.kind == SpotKind.golden;

  String get _label {
    final spot = widget.spot;
    if (!widget.opened) return 'Hiding spot ${spot.index + 1}. Tap to look.';
    return spot.item?.name ?? spot.critter?.name ?? 'Opened';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !widget.opened,
      label: _label,
      child: ExcludeSemantics(
        child: JuicyTap(
          onTap: widget.opened
              ? null
              : () {
                  Haptics.light();
                  widget.onTap();
                },
          pressedScale: .94,
          child: SizedBox(
            width: HidingSpotView.width,
            height: HidingSpotView.height,
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[widget.idle, _reveal]),
              builder: (context, _) => _buildCell(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell() {
    final t = _reveal.value;
    // 0 → .35 the cover shakes; .35 → 1 it shrinks away and the prize pops out.
    final shake = t < .35 && t > 0
        ? math.sin(t / .35 * math.pi * 5) * .13 * (1 - t / .35)
        : 0.0;
    final away = ((t - .35) / .65).clamp(0.0, 1.0);
    final pop = Curves.easeOutBack.transform(away);
    final wiggle = widget.opened
        ? 0.0
        : math.sin(
                (widget.idle.value + widget.spot.index * .17) * math.pi * 2,
              ) *
              .035;
    final pulse = .5 + .5 * math.sin(widget.idle.value * math.pi * 2);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        // What was hiding (only once it is out).
        if (t > .3)
          Opacity(
            opacity: away.clamp(0.0, 1.0),
            child: Transform.scale(scale: .4 + .6 * pop, child: _prize()),
          ),
        // The cover.
        if (away < 1)
          Opacity(
            opacity: 1 - away,
            child: Transform.rotate(
              angle: widget.opened ? shake : wiggle,
              child: Transform.scale(
                scale: 1 - .6 * away,
                alignment: Alignment.bottomCenter,
                child: CustomPaint(
                  size: const Size(HidingSpotView.width, HidingSpotView.height),
                  painter: _SpotPainter(widget.style, golden: _golden),
                ),
              ),
            ),
          ),
        // A shy sparkle on the golden spot to make it special.
        if (_golden && !widget.opened)
          Positioned(
            top: 4,
            right: 14,
            child: Transform.scale(
              scale: .8 + .35 * pulse,
              child: const Icon(
                Icons.star_rounded,
                size: 26,
                color: VeeTokens.yellow,
              ),
            ),
          ),
        // Burst of little stars.
        if (t > .35 && t < 1) ..._burst(away),
        // "NEW!" tag.
        if (widget.opened && widget.isNew && t > .6)
          const Positioned(top: -2, right: -2, child: _NewTag()),
      ],
    );
  }

  Widget _prize() {
    final spot = widget.spot;
    final isItem = spot.item != null;
    final border = _golden
        ? VeeTokens.yellow
        : isItem
        ? VeeTokens.teal
        : VeeTokens.mint;
    return Container(
      width: HidingSpotView.width - 6,
      height: HidingSpotView.height - 6,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: BoxDecoration(
        color: VeeTokens.cardWhite,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: border, width: _golden ? 5 : 3.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _golden
                ? VeeTokens.yellow.withValues(alpha: .6)
                : VeeTokens.shadow,
            blurRadius: _golden ? 18 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (isItem)
            ItemIcon(spot.item!, size: 62)
          else
            Text(spot.critter!.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 2),
          Text(
            isItem ? spot.item!.name : spot.critter!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _burst(double progress) {
    final distance = 30 + 46 * Curves.easeOut.transform(progress);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    return <Widget>[
      for (var k = 0; k < 6; k++)
        Transform.translate(
          offset: Offset(
            math.cos(k * math.pi / 3) * distance,
            math.sin(k * math.pi / 3) * distance * .8,
          ),
          child: Opacity(
            opacity: opacity,
            child: Icon(
              Icons.star_rounded,
              size: 16 + 4.0 * (k % 2),
              color: k.isEven ? VeeTokens.yellow : VeeTokens.orange,
            ),
          ),
        ),
    ];
  }
}

class _NewTag extends StatelessWidget {
  const _NewTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: VeeTokens.coral,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: VeeTokens.shadow, blurRadius: 6, offset: Offset(0, 3)),
      ],
    ),
    child: const Text(
      'NEW!',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: VeeTokens.textOnDark,
      ),
    ),
  );
}

/// Draws the cover (bush, rock, log, basket, box or cushion).
class _SpotPainter extends CustomPainter {
  final HideStyle style;
  final bool golden;

  const _SpotPainter(this.style, {required this.golden});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..style = PaintingStyle.fill;

    if (golden) {
      p.color = VeeTokens.yellow.withValues(alpha: .38);
      canvas.drawCircle(Offset(w / 2, h * .55), h * .52, p);
    }
    // Soft shadow on the ground.
    p.color = VeeTokens.shadow;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * .9),
        width: w * .78,
        height: 14,
      ),
      p,
    );

    switch (style) {
      case HideStyle.bush:
        p.color = const Color(0xFF2F8F5E);
        canvas.drawCircle(Offset(w * .5, h * .58), 38, p);
        p.color = const Color(0xFF3E9A62);
        canvas.drawCircle(Offset(w * .28, h * .7), 27, p);
        canvas.drawCircle(Offset(w * .73, h * .7), 29, p);
        p.color = const Color(0xFF5BA14F);
        canvas.drawCircle(Offset(w * .5, h * .42), 27, p);
        p.color = const Color(0xFF86C068);
        canvas.drawCircle(Offset(w * .42, h * .36), 6, p);
        canvas.drawCircle(Offset(w * .64, h * .5), 5, p);
      case HideStyle.rock:
        p.color = const Color(0xFFA9B1AD);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .12, h * .34, w * .76, h * .56),
            const Radius.circular(34),
          ),
          p,
        );
        p.color = const Color(0xFFC3CAC6);
        canvas.drawOval(Rect.fromLTWH(w * .22, h * .38, w * .32, h * .22), p);
        p.color = const Color(0xFF8E9692);
        canvas.drawOval(Rect.fromLTWH(w * .52, h * .66, w * .3, h * .14), p);
      case HideStyle.log:
        p.color = const Color(0xFF8B5A3A);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .1, h * .4, w * .8, h * .46),
            const Radius.circular(24),
          ),
          p,
        );
        p.color = const Color(0xFFB07B52);
        canvas.drawOval(Rect.fromLTWH(w * .1, h * .4, w * .26, h * .46), p);
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF8B5A3A);
        canvas.drawOval(Rect.fromLTWH(w * .15, h * .5, w * .15, h * .26), p);
        p.style = PaintingStyle.fill;
      case HideStyle.basket:
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFA9743A);
        canvas.drawArc(
          Rect.fromLTWH(w * .25, h * .1, w * .5, h * .6),
          math.pi,
          math.pi,
          false,
          p,
        );
        p
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFC98F4F);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .15, h * .38, w * .7, h * .5),
            const Radius.circular(16),
          ),
          p,
        );
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFA9743A);
        for (var i = 1; i < 4; i++) {
          final y = h * (.38 + i * .125);
          canvas.drawLine(Offset(w * .17, y), Offset(w * .83, y), p);
        }
        p.style = PaintingStyle.fill;
      case HideStyle.box:
        p.color = const Color(0xFFD9A25F);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .17, h * .38, w * .66, h * .5),
            const Radius.circular(10),
          ),
          p,
        );
        p.color = const Color(0xFFE5B875);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .13, h * .3, w * .74, h * .16),
            const Radius.circular(8),
          ),
          p,
        );
        p.color = const Color(0xFFF3DFA8);
        canvas.drawRect(Rect.fromLTWH(w * .45, h * .3, w * .1, h * .58), p);
      case HideStyle.cushion:
        p.color = VeeTokens.coral;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .12, h * .36, w * .76, h * .52),
            const Radius.circular(30),
          ),
          p,
        );
        p.color = const Color(0xFFF08A70);
        canvas.drawOval(Rect.fromLTWH(w * .2, h * .4, w * .36, h * .2), p);
        p.color = const Color(0xFFB93F27);
        canvas.drawCircle(Offset(w * .5, h * .62), 6, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.golden != golden;
}
