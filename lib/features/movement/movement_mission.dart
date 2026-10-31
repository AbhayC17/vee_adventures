import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../app/design_tokens.dart';
import '../../models/activity.dart';
import '../../services/activity_selection/movement_profile.dart';
import '../../widgets/vee_avatar.dart';
import '../../widgets/world_shell.dart';
import '../../widgets/primary_button.dart';
import '../spot/spot_screen.dart';
import '../explore/explore_screen.dart';
import '../play/play_screen.dart';
import '../hub/adventure_hub.dart';

/// The launcher chooses a mode locally. It never asks AI to write the
/// child-facing mission text.
class MovementMission extends StatefulWidget {
  const MovementMission({super.key});
  @override
  State<MovementMission> createState() => _MovementMissionState();
}

class _MovementMissionState extends State<MovementMission> {
  ActivityType? type;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final c = GameAppScope.of(context);
    final selected = c.chooseActivity();
    unawaited(c.save());
    setState(() {
      type = selected;
      ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ready || type == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final selected = type!;
    final label = switch (selected) {
      ActivityType.spot => 'SPOT',
      ActivityType.explore => 'EXPLORE',
      ActivityType.play => 'PLAY',
    };
    final c = GameAppScope.of(context);
    final profile = movementProfileFor(c.profile.movementPreference);
    final subtitle = switch (selected) {
      ActivityType.spot =>
        'Look closely in the real world and follow a trail of clues.',
      ActivityType.explore =>
        'Choose a place and discover what happens inside it.',
      ActivityType.play =>
        'Enter a mini-adventure where your choices change the story.',
    };
    return WorldShell(
      left: VeeAvatar(
        pose: selected == ActivityType.spot ? VeePose.spot : VeePose.encourage,
      ),
      speech: 'Vee picked a world for you. Your choices are still yours once you enter.',
      stepLabel: 'Move',
      stepCurrent: 0,
      stepTotal: 1,
      onRestartMission: () => _go(selected),
      onMainMenu: () => replaceTo(context, const AdventureHub()),
      right: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: VeeTokens.mint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Your move: ${c.profile.movementPreference}  •  ${profile.label}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.teal,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              profile.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: VeeTokens.textSecondaryOnLight,
              ),
            ),
            const SizedBox(height: 24),
            WorldButton(
              onPressed: () => _go(selected),
              color: VeeTokens.yellow,
              child: const Text('Enter the world'),
            ),
          ],
        ),
      ),
    );
  }

  void _go(ActivityType selected) {
    switch (selected) {
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
}
