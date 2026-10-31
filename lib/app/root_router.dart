import 'dart:async';

import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'game_app_scope.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/hub/adventure_hub.dart';
import '../widgets/vee_avatar.dart';
import '../widgets/vee_button.dart';
import '../widgets/vee_loading.dart';

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});
  @override
  Widget build(BuildContext context) {
    final c = GameAppScope.of(context);
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        if (!c.ready) {
          return const VeeLoading();
        }
        if (c.startupError != null) {
          return Scaffold(
            backgroundColor: VeeTokens.cream,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 130,
                        height: 150,
                        child: VeeAvatar(pose: VeePose.sleepy),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Vee needs another try',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(c.startupError!, textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      VeeButton(
                        onPressed: () => unawaited(c.retryInitialization()),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        if (c.profile.onboardingComplete) return const AdventureHub();
        // First launch goes straight to the grown-up card.
        return const OnboardingScreen();
      },
    );
  }
}
