import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/game_app_scope.dart';
import '../app/design_tokens.dart';
import 'speech_bubble.dart';
import 'adaptive_text.dart';
import 'star_counter.dart';
import 'game_options.dart';

/// Shared world composition used by SPOT, EXPLORE and Movement Missions.
///
/// The supplied world background has a deliberate visual split:
/// - blue companion area on the left
/// - large wooden interaction area in the middle/right
///
/// This shell positions content according to that artwork instead of using a
/// generic 40/60 flex row. That keeps Vee visually inside the blue area and
/// keeps gameplay controls centred over the wooden board.
class WorldShell extends StatelessWidget {
  final Widget left;
  final Widget right;
  final String? speech;
  final String? eyebrow;
  final List<Widget> actions;
  final bool showTopBar;
  final VoidCallback? onRestartMission;
  final VoidCallback? onMainMenu;
  final bool showOptionsButton;
  final bool showBackButton;
  final VoidCallback? onBack;
  /// Approximate tone of the artwork behind the interaction area.
  /// The supplied background uses a dark warm wooden panel, so this defaults
  /// to the game's wood tone and automatically selects readable text.
  final Color interactionBackgroundSample;
  /// Gives PLAY its dedicated 50/50 animation + interaction layout.
  final bool splitPlayLayout;

  const WorldShell({
    super.key,
    required this.left,
    required this.right,
    this.speech,
    this.eyebrow,
    this.actions = const [],
    this.showTopBar = true,
    this.onRestartMission,
    this.onMainMenu,
    this.showOptionsButton = true,
    this.showBackButton = false,
    this.onBack,
    this.interactionBackgroundSample = VeeTokens.wood,
    this.splitPlayLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = GameAppScope.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, viewport) {
          final width = viewport.maxWidth;
          final narrow = width < 820;

          return Stack(
            fit: StackFit.expand,
            children: [
              // The supplied world artwork is the actual game composition.
              Positioned.fill(
                child: RepaintBoundary(
                  child: Image.asset(
                    'assets/vee/game_background.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),

              // Large transparent wooden board layered over the blue background.
              // Keep it behind all interactive widgets so content stays clickable.
              if (!splitPlayLayout)
                Positioned(
                  left: width * (narrow ? .04 : .205),
                  right: width * (narrow ? .04 : .012),
                  top: viewport.maxHeight * (narrow ? .22 : .085),
                  bottom: viewport.maxHeight * (narrow ? .06 : .085),
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/world/wooden_panel.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Wooden panel asset could not load: $error');
                        return const SizedBox.expand();
                      },
                    ),
                  ),
                ),

              if (showBackButton && onBack != null)
                Positioned(
                  left: 16,
                  top: 8,
                  child: SafeArea(
                    bottom: false,
                    child: _BackButton(onPressed: onBack!),
                  ),
                ),

              if (showTopBar)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 8,
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            "VEE'S ADVENTURES",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: VeeTokens.white,
                                  fontSize: narrow ? 15 : 17,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showOptionsButton && onRestartMission != null && onMainMenu != null) ...[
                              GameOptionsButton(
                                onRestart: onRestartMission!,
                                onMainMenu: onMainMenu!,
                              ),
                              const SizedBox(width: 8),
                            ],
                            StarCounter(stars: controller.stars),
                            const SizedBox(width: 8),
                            ...actions,
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              if (splitPlayLayout)
                Positioned.fill(
                  child: SafeArea(
                    top: false,
                    child: LayoutBuilder(
                      builder: (context, playViewport) {
                        final playWidth = playViewport.maxWidth;
                        final playHeight = playViewport.maxHeight;
                        final portrait = playWidth < playHeight;
                        final compact = playWidth < 900 || playHeight < 560;
                        final gap = compact ? 6.0 : 10.0;
                        final outer = compact ? 6.0 : 10.0;
                        final halfWidth = portrait
                            ? playWidth
                            : (playWidth - (outer * 2) - gap) / 2;
                        final halfHeight = portrait
                            ? (playHeight - (outer * 2) - gap) / 2
                            : playHeight;

                        Widget companion() => _PlayHalf(
                              compact: compact,
                              child: _CompanionStage(
                                child: left,
                                speech: speech,
                                eyebrow: eyebrow,
                                maxWidth: math.min(
                                  halfWidth - (compact ? 18 : 28),
                                  620,
                                ).toDouble(),
                                availableHeight: halfHeight,
                              ),
                            );

                        Widget interaction() => _PlayHalf(
                              compact: compact,
                              child: _InteractionStage(
                                child: right,
                                maxWidth: math.min(
                                  halfWidth - (compact ? 18 : 28),
                                  720,
                                ).toDouble(),
                                backgroundSample: interactionBackgroundSample,
                              ),
                            );

                        final content = portrait
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: companion()),
                                  SizedBox(height: gap),
                                  Expanded(child: interaction()),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: companion()),
                                  SizedBox(width: gap),
                                  Expanded(child: interaction()),
                                ],
                              );

                        return Padding(
                          padding: EdgeInsets.fromLTRB(outer, compact ? 60 : 66, outer, outer),
                          child: content,
                        );
                      },
                    ),
                  ),
                )
              else if (narrow)
                Positioned.fill(
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 66, 14, 18),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _CompanionStage(
                              child: left,
                              speech: speech,
                              eyebrow: eyebrow,
                              maxWidth: math.min(width - 30, 430).toDouble(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            flex: 6,
                            child: _InteractionStage(
                              child: right,
                              maxWidth: math.min(width - 28, 680).toDouble(),
                              backgroundSample: interactionBackgroundSample,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // LEFT: deliberately aligned to the blue companion area in
                // the supplied background (roughly the first quarter).
                Positioned(
                  left: 0,
                  top: 62,
                  bottom: 14,
                  width: width * .255,
                  child: _CompanionStage(
                    child: left,
                    speech: speech,
                    eyebrow: eyebrow,
                    maxWidth: math.max(250, width * .235).toDouble(),
                  ),
                ),

                // RIGHT: align the interaction to the actual wooden board,
                // leaving the right blue margin free. This prevents the
                // content from drifting too far right on wide monitors.
                Positioned(
                  left: width * .265,
                  right: width * .045,
                  top: viewport.maxHeight * .145,
                  bottom: viewport.maxHeight * .13,
                  child: _InteractionStage(
                    child: right,
                    maxWidth: math.min(740, width * .70).toDouble(),
                    backgroundSample: interactionBackgroundSample,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: VeeTokens.white.withOpacity(.92),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: VeeTokens.shadow,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: VeeTokens.teal,
            size: 29,
          ),
        ),
      ),
    );
  }
}

class _PlayHalf extends StatelessWidget {
  final Widget child;
  final bool compact;

  const _PlayHalf({required this.child, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VeeTokens.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(compact ? 20 : 28),
        border: Border.all(color: VeeTokens.white.withOpacity(.16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(compact ? 6 : 10),
        child: child,
      ),
    );
  }
}

class _CompanionStage extends StatelessWidget {
  final Widget child;
  final String? speech;
  final String? eyebrow;
  final double maxWidth;
  final double availableHeight;

  const _CompanionStage({
    required this.child,
    required this.speech,
    required this.eyebrow,
    required this.maxWidth,
    this.availableHeight = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final compact = availableHeight.isFinite && availableHeight < 520;
    final bubbleGap = compact ? 6.0 : 12.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Center(child: child),
            ),
            if (speech != null) ...[
              SizedBox(height: bubbleGap),
              Flexible(
                fit: FlexFit.loose,
                child: SpeechBubble(
                  text: speech!,
                  eyebrow: eyebrow,
                  maxWidth: maxWidth,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InteractionStage extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color backgroundSample;

  const _InteractionStage({
    required this.child,
    required this.maxWidth,
    required this.backgroundSample,
  });

  @override
  Widget build(BuildContext context) {
    final readable = VeeTextContrast.readableTheme(
      context,
      background: backgroundSample,
    );

    return Theme(
      data: readable,
      child: DefaultTextStyle.merge(
        textAlign: TextAlign.center,
        style: VeeTextContrast.overBackground(
          context,
          background: backgroundSample,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: LayoutBuilder(
                builder: (context, stage) {
                  // Game pages are fixed-screen experiences. If a panel is
                  // larger than the available viewport, scale the panel down
                  // rather than creating a scrollable page.
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: stage.maxWidth,
                        maxHeight: stage.maxHeight,
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
