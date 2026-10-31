import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../widgets/entrance.dart';
import '../../widgets/environment_mode_toggle.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/scene_scaffold.dart';
import '../../widgets/scene_ui.dart';
import '../../widgets/star_counter.dart';
import '../../widgets/sticker_book.dart';
import '../../widgets/vee_avatar.dart';
import '../../widgets/vee_button.dart';
import '../companion/adventure_companion_screen.dart';
import '../explore/explore_screen.dart';
import '../meadow/meadow_screen.dart';
import '../movement/movement_mission.dart';
import '../play/play_screen.dart';
import '../spot/spot_screen.dart';

/// The home screen: pick SPOT, EXPLORE or PLAY (or a movement mission).
class AdventureHub extends StatelessWidget {
  const AdventureHub({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameAppScope.of(context);
    final name = controller.profile.name.trim();
    final greeting = name.isEmpty || name == 'Adventurer'
        ? 'What shall we do today?'
        : 'Hi $name! What shall we do?';

    return SceneScaffold(
      showOptionsButton: false,
      actions: <Widget>[
        EnvironmentModeToggle(
          value: controller.profile.environmentMode,
          onChanged: (mode) => controller.setEnvironmentMode(mode),
        ),
        StarCounter(stars: controller.stars),
        RoundIconButton(
          icon: Icons.park_rounded,
          label: 'Vee’s Meadow',
          onTap: () => replaceTo(context, const MeadowScreen()),
        ),
        RoundIconButton(
          icon: Icons.auto_awesome_mosaic_rounded,
          label: 'Sticker book',
          onTap: () => showStickerBook(context, controller),
        ),
        RoundIconButton(
          icon: Icons.family_restroom_rounded,
          label: 'For grown-ups',
          onTap: () => replaceTo(context, const AdventureCompanionScreen()),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, box) => Center(
          // The hub is laid out on a fixed canvas that scales as a whole, so
          // all three missions are always visible without scrolling.
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 920,
              height: 520,
              child: Column(
                children: <Widget>[
                  Entrance(
                    index: 0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        const Positioned(
                          left: 40,
                          top: 0,
                          child: SparkleDashes(size: 44, rotation: -.15),
                        ),
                        Positioned(
                          right: 40,
                          top: 0,
                          child: Transform.scale(
                            scaleX: -1,
                            child: const SparkleDashes(
                              size: 44,
                              rotation: -.15,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 70,
                            vertical: 4,
                          ),
                          child: ScenePlaque(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 6,
                            ),
                            child: Text(
                              greeting,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 44,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                color: VeeTokens.textOnLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: Entrance(
                            index: 1,
                            child: MissionCard(
                              title: 'SPOT',
                              subtitle: 'Find it with your camera',
                              pose: VeePose.spot,
                              color: VeeTokens.peach,
                              phase: 0,
                              onTap: () =>
                                  replaceTo(context, const SpotScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Entrance(
                            index: 2,
                            child: MissionCard(
                              title: 'EXPLORE',
                              subtitle: 'Discover a new world',
                              pose: VeePose.wave,
                              color: VeeTokens.meadow,
                              phase: .33,
                              onTap: () =>
                                  replaceTo(context, const ExploreScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Entrance(
                            index: 3,
                            child: MissionCard(
                              title: 'PLAY',
                              subtitle: 'Follow a story',
                              pose: VeePose.celebration,
                              color: VeeTokens.yellow,
                              phase: .66,
                              onTap: () =>
                                  replaceTo(context, const PlayScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Entrance(
                    index: 4,
                    child: VeeButton(
                      outlined: true,
                      icon: Icons.directions_run_rounded,
                      minWidth: 420,
                      fontSize: 22,
                      onPressed: () =>
                          replaceTo(context, const MovementMission()),
                      child: const Text('Start a movement mission'),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
