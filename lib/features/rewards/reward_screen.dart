import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../app/design_tokens.dart';
import '../../models/activity.dart';
import '../../widgets/game_options.dart';
import '../../widgets/primary_button.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController c;

  @override
  void initState() {
    super.initState();

    c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
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

    return Scaffold(
      backgroundColor: VeeTokens.cream,
      body: SafeArea(
        child: Stack(
          children: [
            // Options button
            Positioned(
              top: 10,
              right: 16,
              child: GameOptionsButton(
                onRestart: () => _restartActivity(context),
                onMainMenu: () =>
                    replaceTo(context, const AdventureHub()),
              ),
            ),

            // Main reward content. The reward is a fixed-screen scene;
            // it scales down on compact viewports instead of scrolling.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedBuilder(
                      animation: c,
                      builder: (context, _) {
                        return Transform.scale(
                          scale: .92 + (.08 * c.value),
                          child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Vee + celebration stars
                          SizedBox(
                            height: 250,
                            width: 300,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                for (int i = 0; i < 12; i++)
                                  Positioned(
                                    left: math.cos(i * math.pi / 6) *
                                            120 *
                                            c.value +
                                        120,
                                    top: math.sin(i * math.pi / 6) *
                                            110 *
                                            c.value +
                                        100,
                                    child: Text(
                                      '★',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize:
                                            18 + (i % 3) * 5,
                                        color: VeeTokens.yellow,
                                      ),
                                    ),
                                  ),

                                Image.asset(
                                  'assets/vee/vee_celebration.webp',
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Heading
                          const Text(
                            'DISCOVERY FOUND!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: VeeTokens.teal,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Discovery name
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 600,
                            ),
                            child: Text(
                              widget.discovery,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Stars
                          Text(
                            'Stars collected: ${app.stars}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: VeeTokens.textSecondaryOnLight,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Back to hub button
                          WorldButton(
                            onPressed: () => replaceTo(
                              context,
                              const AdventureHub(),
                            ),
                            color: VeeTokens.teal,
                            child: const Text(
                              'Back to the adventure hub',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}