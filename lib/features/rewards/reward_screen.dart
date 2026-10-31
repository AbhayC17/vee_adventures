import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../app/design_tokens.dart';
import '../../game/living_world.dart';
import '../../models/activity.dart';
import '../../widgets/game_options.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/vee_avatar.dart';
import '../explore/explore_screen.dart';
import '../hub/adventure_hub.dart';
import '../play/play_screen.dart';
import '../spot/spot_screen.dart';

class RewardScreen extends StatefulWidget {
  final ActivityType activity;
  final String discovery;

  const RewardScreen({
    super.key,
    required this.activity,
    required this.discovery,
  });

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with TickerProviderStateMixin {
  late final AnimationController c;
  late final AnimationController _rays;
  bool _raysStarted = false;

  @override
  void initState() {
    super.initState();

    c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _rays = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_raysStarted && !MediaQuery.disableAnimationsOf(context)) {
      _raysStarted = true;
      _rays.repeat();
    }
  }

  @override
  void dispose() {
    _rays.dispose();
    c.dispose();
    super.dispose();
  }

  void _restartActivity(BuildContext context) {
    switch (widget.activity) {
      case ActivityType.spot:
        replaceTo(context, const SpotScreen());
        break;

      case ActivityType.explore:
        replaceTo(context, const ExploreScreen());
        break;

      case ActivityType.play:
        replaceTo(context, const PlayScreen());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = GameAppScope.of(context);
    // The meadow behind the reward grows as the child unlocks more worlds.
    final level = app.unlockedWorldItems.length;

    return Scaffold(
      backgroundColor: VeeTokens.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Confetti and stars burst out of Vee's living meadow. Children can
          // keep tapping it while they enjoy the moment.
          Positioned.fill(
            child: LivingWorld(celebrateOnStart: true, revealLevel: level),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  right: 16,
                  child: GameOptionsButton(
                    onRestart: () => _restartActivity(context),
                    onMainMenu: () => replaceTo(context, const AdventureHub()),
                  ),
                ),

                // The reward is a fixed-screen scene; it scales down on
                // compact viewports instead of scrolling.
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedBuilder(
                          animation: c,
                          builder: (context, child) => Transform.scale(
                            scale:
                                .88 +
                                (.12 * Curves.easeOutBack.transform(c.value)),
                            child: child,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 640),
                            padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                            decoration: BoxDecoration(
                              color: VeeTokens.cardWhite,
                              borderRadius: BorderRadius.circular(44),
                              boxShadow: const [
                                BoxShadow(
                                  color: VeeTokens.shadow,
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 230,
                                  width: 230,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Slowly turning sunburst behind Vee.
                                      RepaintBoundary(
                                        child: AnimatedBuilder(
                                          animation: _rays,
                                          builder: (context, _) => CustomPaint(
                                            size: const Size.square(230),
                                            painter: _SunburstPainter(
                                              _rays.value * 2 * math.pi,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 190,
                                        width: 190,
                                        child: VeeAvatar(
                                          pose: VeePose.celebration,
                                          bounce: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Discovery found!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: VeeTokens.teal,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.discovery,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall,
                                ),
                                const SizedBox(height: 10),
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 0,
                                    end: app.stars.toDouble(),
                                  ),
                                  duration: Duration(
                                    milliseconds: (500 + app.stars * 25).clamp(
                                      500,
                                      1400,
                                    ),
                                  ),
                                  curve: Curves.easeOut,
                                  builder: (context, value, _) => Text(
                                    'Stars collected: ${value.round()}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: VeeTokens.textSecondaryOnLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                WorldButton(
                                  onPressed: () =>
                                      replaceTo(context, const AdventureHub()),
                                  color: VeeTokens.teal,
                                  child: const Text(
                                    'Back to the adventure hub',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft golden rays that slowly turn, drawn behind Vee on the reward screen.
class _SunburstPainter extends CustomPainter {
  final double angle;

  const _SunburstPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    const rays = 14;
    for (var i = 0; i < rays; i++) {
      final start = angle + i * 2 * math.pi / rays;
      const sweep = math.pi / rays;
      paint.color = VeeTokens.yellow.withValues(alpha: i.isEven ? .38 : .16);
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
