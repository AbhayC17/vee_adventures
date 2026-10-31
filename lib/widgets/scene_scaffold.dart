import 'package:flutter/material.dart';

import '../app/brand.dart';
import '../app/design_tokens.dart';
import '../app/game_app_scope.dart';
import 'game_options.dart';
import 'scene_background.dart';
import 'scene_ui.dart';

/// A full-screen illustrated scene with the game's top bar (logo and title on
/// the left, step dots in the middle, menu on the right) and any [child]
/// underneath. Every screen is built on this so the whole game looks alike.
class SceneScaffold extends StatelessWidget {
  final Widget child;

  /// Which backdrop to use. Defaults to the one matching indoor/outdoor mode.
  final SceneKind? scene;
  final bool showTopBar;

  /// Shown in the middle of the top bar as "Label • 2 of 5" with dots.
  final String? stepLabel;
  final int? stepCurrent; // zero-based
  final int? stepTotal;

  final VoidCallback? onBack;
  final List<Widget> actions;
  final VoidCallback? onRestartMission;
  final VoidCallback? onMainMenu;
  final bool showOptionsButton;

  const SceneScaffold({
    super.key,
    required this.child,
    this.scene,
    this.showTopBar = true,
    this.stepLabel,
    this.stepCurrent,
    this.stepTotal,
    this.onBack,
    this.actions = const <Widget>[],
    this.onRestartMission,
    this.onMainMenu,
    this.showOptionsButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = GameAppScope.of(context);
    final kind = scene ?? SceneKind.forMode(controller.profile.environmentMode);
    return Scaffold(
      backgroundColor: VeeTokens.cream,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          SceneBackground(kind: kind),
          SafeArea(
            child: Column(
              children: <Widget>[
                if (showTopBar) _TopBar(owner: this),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final SceneScaffold owner;
  const _TopBar({required this.owner});

  @override
  Widget build(BuildContext context) {
    final hasMenu =
        owner.showOptionsButton &&
        owner.onRestartMission != null &&
        owner.onMainMenu != null;
    final hasStep =
        owner.stepLabel != null &&
        owner.stepCurrent != null &&
        owner.stepTotal != null;

    return LayoutBuilder(
      builder: (context, box) {
        final roomy = box.maxWidth >= 1000;
        return SizedBox(
          height: 82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (owner.onBack != null) ...<Widget>[
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back',
                        onTap: owner.onBack!,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Container(
                      padding: EdgeInsets.fromLTRB(10, 6, roomy ? 18 : 10, 6),
                      decoration: BoxDecoration(
                        color: VeeTokens.cardWhite.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: VeeTokens.shadow,
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const LeafMark(size: 38),
                          if (roomy) ...<Widget>[
                            const SizedBox(width: 10),
                            const Text(
                              AppBrand.name,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: VeeTokens.textOnLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              for (
                                var i = 0;
                                i < owner.actions.length;
                                i++
                              ) ...<Widget>[
                                if (i > 0) const SizedBox(width: 10),
                                owner.actions[i],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (hasMenu) ...<Widget>[
                      const SizedBox(width: 10),
                      GameOptionsButton(
                        onRestart: owner.onRestartMission!,
                        onMainMenu: owner.onMainMenu!,
                      ),
                    ],
                  ],
                ),
                if (hasStep)
                  StepPill(
                    label: owner.stepLabel!,
                    current: owner.stepCurrent!.clamp(0, owner.stepTotal! - 1),
                    total: owner.stepTotal!,
                    showLeaf: false,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
