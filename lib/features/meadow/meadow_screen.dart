import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../game/living_world.dart';
import '../../widgets/juicy_tap.dart';
import '../../widgets/star_counter.dart';
import '../../widgets/vee_avatar.dart';
import '../hub/adventure_hub.dart';

/// Vee's Meadow: a free-play world with no goals and no way to lose.
///
/// Everything in it reacts to a tap. The meadow grows as the child plays
/// adventures (a treasure chest appears, then a magic portal), and catching
/// fireflies earns a bonus star every few catches, up to a few per visit.
class MeadowScreen extends StatefulWidget {
  const MeadowScreen({super.key});

  @override
  State<MeadowScreen> createState() => _MeadowScreenState();
}

class _MeadowScreenState extends State<MeadowScreen> {
  static const int _catchesPerStar = 5;
  static const int _maxBonusStarsPerVisit = 3;

  int _caught = 0;
  int _bonusStars = 0;
  int _veeBounce = 0;
  VeePose _veePose = VeePose.happy;
  String _note = '';

  void _onStarCaught(int total) {
    final controller = GameAppScope.of(context);
    var note = '';
    if (total % _catchesPerStar == 0 && _bonusStars < _maxBonusStarsPerVisit) {
      _bonusStars++;
      controller.addStars(1);
      controller.scheduleSave();
      note = '⭐ A bonus star for you!';
    }
    setState(() {
      _caught = total;
      _veePose = VeePose.celebration;
      _veeBounce++;
      if (note.isNotEmpty) _note = note;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = GameAppScope.of(context);
    // 0–4: grows with the number of unlocked worlds.
    final level = controller.unlockedWorldItems.length;

    return Scaffold(
      backgroundColor: VeeTokens.cream,
      body: LayoutBuilder(
        builder: (context, box) {
          final veeWidth = math.min(box.maxWidth * .2, 190.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: LivingWorld(
                  revealLevel: level,
                  onStarCaught: _onStarCaught,
                ),
              ),
              Positioned(
                left: 10,
                bottom: 4,
                width: veeWidth,
                height: veeWidth * 1.2,
                child: IgnorePointer(
                  child: VeeAvatar(pose: _veePose, bounce: _veeBounce),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 8,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      JuicyTap(
                        semanticLabel: 'Back to the adventure hub',
                        onTap: () => replaceTo(context, const AdventureHub()),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: VeeTokens.white,
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
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: _Chip(
                          text: _note.isNotEmpty
                              ? _note
                              : _caught == 0
                              ? '✨ Tap the fireflies!'
                              : '✨ $_caught caught',
                        ),
                      ),
                      const Spacer(),
                      StarCounter(stars: controller.stars),
                    ],
                  ),
                ),
              ),
              if (level < 4)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 10,
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: _Chip(
                        text: level < 3
                            ? '🌱 Play adventures to make the meadow grow!'
                            : '🌈 One more surprise is waiting to appear…',
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: VeeTokens.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: VeeTokens.shadow,
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: VeeTokens.textOnLight,
      ),
    ),
  );
}
