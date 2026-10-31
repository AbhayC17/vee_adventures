import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../models/environment_mode.dart';
import '../services/assets/optional_assets.dart';

/// The illustrated backdrops. Each one keeps its middle area plain cream so
/// headlines and buttons always sit on a calm surface.
enum SceneKind {
  /// Outdoor: hills, trees, a winding path.
  meadow('assets/scenes/bg_meadow.webp'),

  /// Indoor: a cosy room with a window and a rug.
  indoor('assets/scenes/bg_indoor.webp'),

  /// A soft green blob with leaves, for "look closer" moments.
  closeup('assets/scenes/bg_closeup.webp');

  final String assetPath;
  const SceneKind(this.assetPath);

  static SceneKind forMode(EnvironmentMode mode) =>
      mode == EnvironmentMode.indoor ? SceneKind.indoor : SceneKind.meadow;
}

/// Fills its space with a scene. If the generated artwork file has been added
/// (see docs/ASSET_PROMPTS.md) it is used; until then the same scene is drawn
/// in code, so the game always looks finished.
class SceneBackground extends StatelessWidget {
  final SceneKind kind;
  const SceneBackground({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final Widget scene;
    if (OptionalAssets.has(kind.assetPath)) {
      scene = Image.asset(
        kind.assetPath,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => _painted(),
      );
    } else {
      scene = _painted();
    }
    return RepaintBoundary(child: SizedBox.expand(child: scene));
  }

  Widget _painted() => CustomPaint(
    painter: switch (kind) {
      SceneKind.meadow => const _MeadowPainter(),
      SceneKind.indoor => const _IndoorPainter(),
      SceneKind.closeup => const _CloseupPainter(),
    },
    isComplex: true,
    willChange: false,
  );
}

// ── shared drawing helpers ─────────────────────────────────────────────────

void _cloud(Canvas c, Offset at, double unit) {
  final p = Paint()..color = const Color(0xFFDDEBF0);
  c.drawOval(
    Rect.fromCenter(center: at, width: unit * 4.2, height: unit * 1.5),
    p,
  );
  c.drawCircle(at + Offset(-unit * .8, -unit * .5), unit * .9, p);
  c.drawCircle(at + Offset(unit * .5, -unit * .7), unit * 1.1, p);
}

void _tree(Canvas c, double x, double groundY, double h, {bool flip = false}) {
  final trunk = Paint()..color = const Color(0xFF8B5A3A);
  final dark = Paint()..color = const Color(0xFF4F9A55);
  final mid = Paint()..color = const Color(0xFF6DAE5B);
  final light = Paint()..color = const Color(0xFF86C068);
  final s = flip ? -1.0 : 1.0;
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x - h * .05, groundY - h * .55, h * .1, h * .6),
      Radius.circular(h * .03),
    ),
    trunk,
  );
  c.drawCircle(Offset(x - s * h * .12, groundY - h * .62), h * .26, dark);
  c.drawCircle(Offset(x + s * h * .16, groundY - h * .58), h * .22, mid);
  c.drawCircle(Offset(x + s * h * .02, groundY - h * .82), h * .24, light);
}

void _bush(Canvas c, Offset at, double r, Color color) {
  final p = Paint()..color = color;
  c.drawCircle(at, r, p);
  c.drawCircle(at + Offset(r * .9, r * .2), r * .8, p);
  c.drawCircle(at + Offset(-r * .9, r * .25), r * .75, p);
}

void _flower(Canvas c, Offset at, double r, Color petals) {
  final p = Paint()..color = petals;
  for (var i = 0; i < 5; i++) {
    final a = i * math.pi * 2 / 5;
    c.drawCircle(at + Offset(math.cos(a), math.sin(a)) * r, r * .8, p);
  }
  c.drawCircle(at, r * .7, Paint()..color = VeeTokens.yellow);
}

// ── meadow ────────────────────────────────────────────────────────────────

class _MeadowPainter extends CustomPainter {
  const _MeadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = VeeTokens.cream);

    // Sun and clouds.
    canvas.drawCircle(
      Offset(w * .83, h * .13),
      h * .065,
      Paint()..color = const Color(0xFFFFD97A),
    );
    _cloud(canvas, Offset(w * .27, h * .17), h * .045);
    _cloud(canvas, Offset(w * .92, h * .22), h * .04);

    // Far and middle hills.
    final far = Paint()..color = const Color(0xFFB4D8AC);
    canvas.drawOval(Rect.fromLTWH(-w * .12, h * .50, w * .6, h * .5), far);
    canvas.drawOval(Rect.fromLTWH(w * .6, h * .52, w * .6, h * .5), far);
    canvas.drawOval(
      Rect.fromLTWH(w * .22, h * .62, w * .62, h * .5),
      Paint()..color = const Color(0xFFA2CF99),
    );

    // Trees at the edges.
    _tree(canvas, w * .045, h * .62, h * .62);
    _tree(canvas, w * .965, h * .66, h * .5, flip: true);

    // Ground and a winding path.
    canvas.drawOval(
      Rect.fromLTWH(-w * .1, h * .8, w * 1.2, h * .4),
      Paint()..color = const Color(0xFFBFE08A),
    );
    final path = Path()
      ..moveTo(w * .52, h)
      ..cubicTo(w * .6, h * .9, w * .78, h * .92, w * .84, h * .78)
      ..cubicTo(w * .88, h * .7, w * .96, h * .68, w, h * .66)
      ..lineTo(w, h * .74)
      ..cubicTo(w * .93, h * .76, w * .92, h * .84, w * .9, h * .9)
      ..cubicTo(w * .88, h * .97, w * .8, h, w * .76, h)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF4DFA8));

    // Foreground bushes and flowers in the corners.
    _bush(canvas, Offset(w * .03, h * .95), h * .13, const Color(0xFF1F7A56));
    _bush(canvas, Offset(w * .17, h * 1.02), h * .1, const Color(0xFF2F8F5E));
    _bush(canvas, Offset(w * .97, h * .98), h * .15, const Color(0xFF1F7A56));
    _bush(canvas, Offset(w * .86, h * 1.04), h * .1, const Color(0xFF3E9A62));
    _flower(canvas, Offset(w * .05, h * .84), h * .022, Colors.white);
    _flower(canvas, Offset(w * .095, h * .9), h * .018, Colors.white);
    _flower(canvas, Offset(w * .94, h * .78), h * .022, VeeTokens.coral);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── indoor ────────────────────────────────────────────────────────────────

class _IndoorPainter extends CustomPainter {
  const _IndoorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = VeeTokens.cream);

    // Wall stripe near the floor and the floor itself.
    canvas.drawRect(
      Rect.fromLTWH(0, h * .72, w, h * .06),
      Paint()..color = const Color(0xFFF3E4BF),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * .78, w, h * .22),
      Paint()..color = const Color(0xFFE6C896),
    );
    final plank = Paint()
      ..color = const Color(0xFFD9B77F)
      ..strokeWidth = 3;
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(
        Offset(0, h * (.78 + i * .037)),
        Offset(w, h * (.78 + i * .037)),
        plank,
      );
    }

    // Window with sky, sun and curtains.
    final window = Rect.fromLTWH(w * .06, h * .16, w * .17, h * .36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(window.inflate(10), const Radius.circular(18)),
      Paint()..color = VeeTokens.teal,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(10)),
      Paint()..color = const Color(0xFFCDE8F2),
    );
    canvas.drawCircle(
      window.topRight + Offset(-window.width * .28, window.height * .28),
      window.width * .12,
      Paint()..color = const Color(0xFFFFD97A),
    );
    final frame = Paint()
      ..color = VeeTokens.teal
      ..strokeWidth = 8;
    canvas.drawLine(window.topCenter, window.bottomCenter, frame);
    canvas.drawLine(window.centerLeft, window.centerRight, frame);
    final curtain = Paint()..color = VeeTokens.coral.withValues(alpha: .85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .035, h * .13, w * .035, h * .42),
        const Radius.circular(14),
      ),
      curtain,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .225, h * .13, w * .035, h * .42),
        const Radius.circular(14),
      ),
      curtain,
    );

    // Shelf with books on the right.
    final shelfY = h * .36;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .78, shelfY, w * .19, h * .025),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF9B6B43),
    );
    final bookColors = <Color>[
      VeeTokens.teal,
      VeeTokens.yellow,
      VeeTokens.coral,
      VeeTokens.meadow,
      VeeTokens.sky,
    ];
    for (var i = 0; i < bookColors.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * (.795 + i * .03),
            shelfY - h * (.08 + (i % 2) * .02),
            w * .024,
            h * (.08 + (i % 2) * .02),
          ),
          const Radius.circular(4),
        ),
        Paint()..color = bookColors[i],
      );
    }

    // Rug.
    canvas.drawOval(
      Rect.fromLTWH(w * .26, h * .88, w * .5, h * .14),
      Paint()..color = VeeTokens.coral.withValues(alpha: .35),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * .31, h * .905, w * .4, h * .095),
      Paint()..color = VeeTokens.yellow.withValues(alpha: .55),
    );

    // Pot plant bottom right.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .9, h * .8, w * .06, h * .13),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFFC96F4A),
    );
    final leaf = Paint()..color = const Color(0xFF2F8F5E);
    for (final dx in <double>[-.04, -.01, .02, .05]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * (.93 + dx), h * .72),
          width: w * .035,
          height: h * .18,
        ),
        leaf,
      );
    }

    // Soft bushes bottom left for warmth.
    _bush(canvas, Offset(w * .03, h * 1.0), h * .11, const Color(0xFF2F8F5E));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── close-up ──────────────────────────────────────────────────────────────

class _CloseupPainter extends CustomPainter {
  const _CloseupPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = VeeTokens.cream);

    // The big soft blob the close-up picture sits on.
    canvas.drawOval(
      Rect.fromLTWH(-w * .02, h * .08, w * .56, h * .86),
      Paint()..color = const Color(0xFFE1EEDA),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * .2, h * .24, w * .26, h * .56),
      Paint()..color = const Color(0xFFD5E8CF),
    );

    // Leaves in the corners.
    void leaf(Offset base, double len, double angle, Color color) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * .55, -len * .32, len, 0)
        ..quadraticBezierTo(len * .55, len * .32, 0, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      canvas.restore();
    }

    leaf(Offset(0, h * .3), h * .3, -.5, const Color(0xFF3E8F5B));
    leaf(Offset(0, h * .36), h * .26, .25, const Color(0xFF1F7A56));
    leaf(Offset(0, h * .98), h * .3, -1.0, const Color(0xFF1F7A56));
    leaf(Offset(w * .08, h * 1.02), h * .24, -1.4, const Color(0xFF3E8F5B));
    leaf(Offset(w, h * .58), h * .28, 3.5, const Color(0xFF3E8F5B));
    leaf(Offset(w, h * .5), h * .22, 3.0, const Color(0xFF86C068));

    // A little hill and path in the bottom right.
    canvas.drawOval(
      Rect.fromLTWH(w * .66, h * .78, w * .5, h * .5),
      Paint()..color = const Color(0xFFBFE08A),
    );
    final path = Path()
      ..moveTo(w * .86, h)
      ..cubicTo(w * .84, h * .9, w * .93, h * .88, w * .96, h * .82)
      ..lineTo(w, h * .8)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF4DFA8));
    _bush(canvas, Offset(w * .72, h * 1.0), h * .08, const Color(0xFF3E9A62));
    _flower(canvas, Offset(w * .95, h * .9), h * .028, VeeTokens.coral);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
