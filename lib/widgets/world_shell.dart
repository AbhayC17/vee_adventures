import 'package:flutter/material.dart';

import 'scene_background.dart';
import 'scene_scaffold.dart';
import 'speech_bubble.dart';

/// The shared layout for the activity screens (SPOT, EXPLORE, PLAY, Movement
/// Missions): an illustrated scene, the top bar, Vee on the left and the
/// activity's content on the right.
///
/// Wide content never scrolls; if it is too tall for the screen it is scaled
/// down to fit instead.
class WorldShell extends StatelessWidget {
  /// Usually a [VeeAvatar]. It is given the full height of the left column.
  final Widget left;

  /// The activity content.
  final Widget right;

  /// Something Vee says; shown as a small bubble above Vee.
  final String? speech;

  /// Shown in the step pill when no [stepLabel] is given.
  final String? eyebrow;

  final List<Widget> actions;
  final bool showTopBar;
  final VoidCallback? onRestartMission;
  final VoidCallback? onMainMenu;
  final bool showOptionsButton;
  final bool showBackButton;
  final VoidCallback? onBack;

  /// Step dots in the top bar, for example `stepLabel: 'Spot'`,
  /// `stepCurrent: 0`, `stepTotal: 3`.
  final String? stepLabel;
  final int? stepCurrent;
  final int? stepTotal;

  /// Which backdrop to draw. Defaults to indoor or outdoor by the child's
  /// chosen mode.
  final SceneKind? scene;

  /// Share of the width given to Vee's side (out of 10).
  final int leftFlex;

  /// Kept so older call sites still compile. They no longer change anything.
  final Object? interactionBackgroundSample;
  final bool splitPlayLayout;

  const WorldShell({
    super.key,
    required this.left,
    required this.right,
    this.speech,
    this.eyebrow,
    this.actions = const <Widget>[],
    this.showTopBar = true,
    this.onRestartMission,
    this.onMainMenu,
    this.showOptionsButton = true,
    this.showBackButton = false,
    this.onBack,
    this.stepLabel,
    this.stepCurrent,
    this.stepTotal,
    this.scene,
    this.leftFlex = 4,
    this.interactionBackgroundSample,
    this.splitPlayLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    return SceneScaffold(
      scene: scene,
      showTopBar: showTopBar,
      stepLabel: stepLabel,
      stepCurrent: stepCurrent,
      stepTotal: stepTotal,
      onBack: showBackButton ? onBack : null,
      actions: actions,
      onRestartMission: onRestartMission,
      onMainMenu: onMainMenu,
      showOptionsButton: showOptionsButton,
      child: LayoutBuilder(
        builder: (context, box) {
          final narrow = box.maxWidth < 700;
          final leftShare = narrow ? 3 : leftFlex;
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 24, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: leftShare,
                  child: _VeeSide(speech: speech, child: left),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 10 - leftShare,
                  child: StageFit(child: right),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VeeSide extends StatelessWidget {
  final String? speech;
  final Widget child;
  const _VeeSide({required this.speech, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: <Widget>[
      if (speech != null && speech!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 6, right: 6),
          child: SpeechBubble(text: speech!, maxWidth: 320),
        ),
      Expanded(
        child: Align(alignment: Alignment.bottomCenter, child: child),
      ),
    ],
  );
}

/// Centres [child] in the space it is given and scales it down (never up) if
/// it would not fit, so fixed-screen layouts never scroll.
class StageFit extends StatelessWidget {
  final Widget child;
  const StageFit({super.key, required this.child});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, stage) => Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: stage.maxWidth),
          child: child,
        ),
      ),
    ),
  );
}
