import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../models/activity.dart';
import '../../models/content_catalog.dart';
import '../../models/environment_mode.dart';
import '../../services/activity_selection/movement_profile.dart';
import '../../services/ai/surprise_selector.dart';
import '../../services/discovery_engine.dart';
import '../../services/explore/explore_board.dart';
import '../../services/play/play_puzzles.dart';
import '../../widgets/haptics.dart';
import '../../widgets/hiding_spot.dart';
import '../../widgets/item_icon.dart';
import '../../widgets/juicy_tap.dart';
import '../../widgets/puzzle_card.dart';
import '../../widgets/scene_scaffold.dart';
import '../../widgets/scene_ui.dart';
import '../../widgets/vee_avatar.dart';
import '../../widgets/vee_button.dart';
import '../../widgets/world_shell.dart';
import '../hub/adventure_hub.dart';
import '../rewards/reward_screen.dart';

/// EXPLORE is a hide-and-seek adventure.
///
/// Pick a world, then peek behind hiding spots. Each one holds an item (with a
/// fun fact and a sticker), a friendly critter, or, rarely, a golden find.
/// Finding things fills the sparkle meter, and a full meter brings a surprise.
/// Worlds can be "mastered" by finding everything in them, and every round
/// favours things the child has not collected yet, so there is always one more
/// thing to find. Nothing is ever lost or timed, and rounds end naturally.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

enum _Phase { seek, sparkle, roundDone, puzzle, surprise, tease, secret }

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  static const int _sparkleGoal = 5;

  final Random random = Random();
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool _idleStarted = false;

  ExploreSetting? setting;
  bool showingSpecialEvents = false;

  ExploreBoard? board;
  Set<String> _recentItems = <String>{};
  final Set<int> _newSpots = <int>{};
  int _newThisRound = 0;
  _Phase phase = _Phase.seek;
  int round = 1;
  int sparkles = 0;
  int interactionCount = 0;
  int bonusStars = 0;
  bool challengeComplete = false;
  bool hiddenAreaOpen = false;
  bool worldMastered = false;
  String speechText = '';
  CatalogItem? _lastItem;
  SurpriseEvent? _sparkleEvent;
  String? surprise;
  PlayPuzzle? _challenge;
  VeePose _veePose = VeePose.happy;
  int _veeBounce = 0;
  bool _finishStarted = false;
  final String _completionToken =
      'explore-${DateTime.now().microsecondsSinceEpoch}';

  MovementProfile get _movementProfile =>
      movementProfileFor(GameAppScope.of(context).profile.movementPreference);

  int get _targetInteractions => _movementProfile.exploreInteractions;
  int get _discoveryGate => _movementProfile.exploreDiscoveryGate;
  EnvironmentMode get _mode => GameAppScope.of(context).profile.environmentMode;

  /// Hiding spots per round: a calmer pace gets fewer.
  int get _spotCount => switch (_movementProfile) {
    MovementProfile.gentle => 4,
    MovementProfile.steady => 6,
    MovementProfile.energetic => 8,
  };

  bool get _canFinish =>
      hiddenAreaOpen && interactionCount >= _targetInteractions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_idleStarted) return;
    _idleStarted = true;
    if (!MediaQuery.disableAnimationsOf(context)) _idle.repeat();
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (setting == null) return _settings();
    return WorldShell(
      left: VeeAvatar(pose: _veePose, bounce: _veeBounce),
      speech: speechText.isEmpty ? null : speechText,
      stepLabel: 'Explore',
      stepCurrent: interactionCount.clamp(0, _targetInteractions - 1),
      stepTotal: _targetInteractions,
      onRestartMission: () => replaceTo(context, const ExploreScreen()),
      onMainMenu: () => replaceTo(context, const AdventureHub()),
      right: _panel(),
    );
  }

  // ── choosing a world ─────────────────────────────────────────────────────

  Widget _settings() {
    final c = GameAppScope.of(context);
    final collected = c.collectedItemIds;
    final worlds = showingSpecialEvents
        ? ContentCatalog.specialEventsForMode(_mode)
        : ContentCatalog.settingsForMode(_mode);
    final mastered = worlds
        .where((w) => WorldProgress.of(w, collected).mastered)
        .length;

    return SceneScaffold(
      onBack: () => replaceTo(context, const AdventureHub()),
      onRestartMission: () => replaceTo(context, const ExploreScreen()),
      onMainMenu: () => replaceTo(context, const AdventureHub()),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 920,
            height: 560,
            child: Column(
              children: [
                ScenePlaque(
                  child: Text(
                    showingSpecialEvents
                        ? 'Special events'
                        : 'Where do you want to explore?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: VeeTokens.textOnLight,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SceneCaption(
                  mastered > 0
                      ? 'Worlds mastered: $mastered of ${worlds.length}. Find everything to earn a star!'
                      : 'Find everything in a world to master it.',
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final w in worlds)
                        _worldCard(w, WorldProgress.of(w, collected)),
                      _surpriseMeCard(worlds),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                VeeButton(
                  outlined: true,
                  icon: showingSpecialEvents
                      ? Icons.arrow_back_rounded
                      : Icons.celebration_rounded,
                  fontSize: 19,
                  minWidth: 300,
                  onPressed: () => setState(
                    () => showingSpecialEvents = !showingSpecialEvents,
                  ),
                  child: Text(
                    showingSpecialEvents
                        ? 'Back to regular worlds'
                        : 'Special events',
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _worldCard(ExploreSetting s, WorldProgress progress) {
    return JuicyTap(
      semanticLabel: '${s.name}. Found ${progress.found} of ${progress.total}.',
      onTap: () => _selectSetting(s),
      child: Container(
        width: 205,
        height: 168,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: VeeTokens.cardWhite,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: progress.mastered ? VeeTokens.yellow : Colors.transparent,
            width: 4,
          ),
          boxShadow: const [
            BoxShadow(
              color: VeeTokens.shadow,
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        // Fixed-size card: if text is larger than expected (a bigger font, a
        // long name) the contents shrink a little instead of overflowing.
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 173,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 34)),
                      if (progress.mastered) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: VeeTokens.orange,
                          size: 30,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: VeeTokens.textOnLight,
                    ),
                  ),
                  Text(
                    s.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: VeeTokens.textSecondaryOnLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 10,
                      backgroundColor: VeeTokens.creamDeep,
                      color: progress.mastered
                          ? VeeTokens.yellow
                          : VeeTokens.teal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    progress.mastered
                        ? 'Mastered!'
                        : '${progress.found} of ${progress.total} found',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: VeeTokens.textOnLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A mystery card that jumps into a random world.
  Widget _surpriseMeCard(List<ExploreSetting> worlds) {
    return JuicyTap(
      semanticLabel: 'Surprise me with a random world',
      onTap: () {
        if (worlds.isEmpty) return;
        _selectSetting(worlds[random.nextInt(worlds.length)]);
      },
      child: Container(
        width: 205,
        height: 168,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VeeTokens.teal,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: VeeTokens.shadow,
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 48, color: VeeTokens.yellow),
            SizedBox(height: 6),
            Text(
              'Surprise me!',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: VeeTokens.textOnDark,
              ),
            ),
            Text(
              'A mystery world',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: VeeTokens.textOnDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectSetting(ExploreSetting selected) {
    setState(() {
      setting = selected;
      showingSpecialEvents = false;
      round = 1;
      sparkles = 0;
      interactionCount = 0;
      bonusStars = 0;
      challengeComplete = false;
      hiddenAreaOpen = false;
      worldMastered = false;
      surprise = null;
      _sparkleEvent = null;
      _challenge = null;
      _lastItem = null;
      _recentItems = <String>{};
      _veePose = VeePose.happy;
      _newBoard();
      speechText = 'Tap a hiding spot to peek! What could be inside?';
    });
  }

  void _leaveWorld() {
    setState(() {
      setting = null;
      board = null;
      speechText = '';
      _veePose = VeePose.happy;
    });
  }

  void _newBoard() {
    final c = GameAppScope.of(context);
    final fresh = ExploreBoard.generate(
      setting: setting!,
      collected: c.collectedItemIds,
      random: random,
      spotCount: _spotCount,
      recent: _recentItems,
    );
    board = fresh;
    _recentItems = fresh.itemIds;
    _newSpots.clear();
    _newThisRound = 0;
    phase = _Phase.seek;
  }

  void _nextRound() {
    setState(() {
      round++;
      _newBoard();
      _veePose = VeePose.happy;
      _veeBounce++;
      speechText = 'Round $round! Peek behind the hiding spots.';
    });
  }

  // ── the game panel ───────────────────────────────────────────────────────

  Widget _panel() {
    final c = GameAppScope.of(context);
    final stickers = c.collectedItemIds.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: VeeTokens.cardWhite.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(
            color: VeeTokens.shadow,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${setting!.emoji} ${setting!.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: VeeTokens.textOnLight,
                  ),
                ),
              ),
              TextButton(
                onPressed: _leaveWorld,
                child: const Text(
                  'Choose another place',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: VeeTokens.teal,
                    decoration: TextDecoration.underline,
                    decorationColor: VeeTokens.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _SparkleMeter(count: sparkles, goal: _sparkleGoal),
              const Spacer(),
              _StickerChip(have: stickers, total: ContentCatalog.items.length),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: KeyedSubtree(
              key: ValueKey<String>('$phase-$round'),
              child: _phaseBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _phaseBody() => switch (phase) {
    _Phase.seek => _board(),
    _Phase.sparkle => _sparkleCard(),
    _Phase.roundDone => _roundDoneCard(),
    _Phase.puzzle => _puzzleCard(),
    _Phase.surprise => _surpriseCard(),
    _Phase.tease => _teaseCard(),
    _Phase.secret => _secretCard(),
  };

  // ── seeking ──────────────────────────────────────────────────────────────

  HideStyle _styleFor(int index) {
    const outdoor = [HideStyle.bush, HideStyle.rock, HideStyle.log];
    const indoor = [HideStyle.basket, HideStyle.box, HideStyle.cushion];
    final list = _mode == EnvironmentMode.indoor ? indoor : outdoor;
    return list[(index * 7 + round) % list.length];
  }

  Widget _board() {
    final b = board!;
    final columns = b.spots.length == 6 ? 3 : 4;
    final width = columns * HidingSpotView.width + (columns - 1) * 12 + 4.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Round $round  •  Found ${b.openedItemCount} of ${b.itemSpotCount}',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: VeeTokens.textSecondaryOnLight,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: width,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final spot in b.spots)
                HidingSpotView(
                  key: ValueKey<String>('spot-$round-${spot.index}'),
                  spot: spot,
                  opened: b.isOpen(spot.index),
                  isNew: _newSpots.contains(spot.index),
                  style: _styleFor(spot.index),
                  idle: _idle,
                  onTap: () => _open(spot.index),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _open(int index) {
    final b = board;
    if (b == null || phase != _Phase.seek) return;
    final spot = b.open(index);
    if (spot == null) return;
    final c = GameAppScope.of(context);

    if (spot.kind == SpotKind.critter) {
      setState(() {
        speechText = spot.critter!.line;
        _veePose = VeePose.happy;
        _veeBounce++;
      });
      return;
    }

    final item = spot.item!;
    final golden = spot.kind == SpotKind.golden;
    final isNew = !c.collectedItemIds.contains(item.id);
    c.addDiscovery('item-${item.id}');
    _recordFind(item);

    final pack = DiscoveryEngine.forItem(item);
    final wow = pack
        .wowDiscoveries[(interactionCount - 1) % pack.wowDiscoveries.length];
    var message = golden
        ? 'A GOLDEN find! ${item.name}! $wow'
        : isNew
        ? 'A new sticker: ${item.name}! $wow'
        : '${item.name}! $wow';

    // Finding everything in a world earns a one-time badge and a bonus star.
    final progress = WorldProgress.of(setting!, c.collectedItemIds);
    final badge = 'world-${setting!.id}';
    if (progress.mastered && !c.discoveries.contains(badge)) {
      worldMastered = true;
      c.addDiscovery(badge);
      message = 'You found EVERYTHING in ${setting!.name}! You mastered it!';
    }

    c.scheduleSave();
    Haptics.medium();
    setState(() {
      if (isNew) {
        _newSpots.add(index);
        _newThisRound++;
      }
      if (golden) bonusStars = min(2, bonusStars + 1);
      sparkles = min(_sparkleGoal, sparkles + (golden ? 2 : 1));
      speechText = message;
      _veePose = golden ? VeePose.surprised : VeePose.celebration;
      _veeBounce++;
    });

    if (sparkles >= _sparkleGoal) {
      _later(_startSparkle);
    } else if (b.roundComplete) {
      _later(_endRound);
    }
  }

  void _recordFind(CatalogItem item) {
    interactionCount++;
    _lastItem = item;
  }

  /// Waits a moment so the child can enjoy the reveal before the screen changes.
  void _later(VoidCallback action) {
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) action();
    });
  }

  void _startSparkle() {
    if (phase != _Phase.seek) return;
    final item = _lastItem ?? ContentCatalog.items.first;
    setState(() {
      _sparkleEvent = DiscoveryEngine.randomEvent(
        DiscoveryEngine.forItem(item).surpriseIds,
        mode: _mode,
      );
      phase = _Phase.sparkle;
      _veePose = VeePose.surprised;
      _veeBounce++;
      speechText = 'The sparkle meter is full!';
    });
  }

  void _endRound() {
    if (phase != _Phase.seek || !(board?.roundComplete ?? false)) return;
    setState(() {
      if (!challengeComplete && interactionCount >= _discoveryGate) {
        phase = _Phase.puzzle;
        _veePose = VeePose.thinking;
        speechText = 'Something needs your help!';
      } else {
        phase = _Phase.roundDone;
        _veePose = VeePose.celebration;
        speechText = 'Round $round complete!';
      }
    });
  }

  // ── cards that replace the board ─────────────────────────────────────────

  Widget _sparkleCard() {
    final event = _sparkleEvent!;
    return _card(
      children: [
        Text(event.emoji, style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 4),
        const PillTag.coral('Sparkle surprise!'),
        const SizedBox(height: 10),
        Text(event.title, textAlign: TextAlign.center, style: _headingStyle),
        const SizedBox(height: 6),
        Text(event.message, textAlign: TextAlign.center, style: _bodyStyle),
        const SizedBox(height: 16),
        VeeButton(
          icon: Icons.celebration_rounded,
          onPressed: () {
            final c = GameAppScope.of(context);
            final item = _lastItem;
            if (item != null) {
              c.addDiscovery('explore-surprise-${item.id}-${event.id}');
              c.scheduleSave();
            }
            setState(() {
              sparkles = 0;
              _sparkleEvent = null;
              phase = _Phase.seek;
              _veePose = VeePose.happy;
            });
            if (board?.roundComplete ?? false) _later(_endRound);
          },
          child: const Text('Yay!'),
        ),
      ],
    );
  }

  Widget _roundDoneCard() {
    final tired = round >= 4;
    return _card(
      children: [
        const PillTag.coral('Round complete!'),
        const SizedBox(height: 10),
        Text(
          worldMastered
              ? 'You mastered ${setting!.name}!'
              : _newThisRound > 0
              ? 'You found $_newThisRound new sticker${_newThisRound == 1 ? '' : 's'}!'
              : 'Great exploring!',
          textAlign: TextAlign.center,
          style: _headingStyle,
        ),
        const SizedBox(height: 6),
        Text(
          tired
              ? 'You have explored a lot. A stretch or a sip of water might feel nice!'
              : 'There is always more hiding. Ready for another round?',
          textAlign: TextAlign.center,
          style: _bodyStyle,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            VeeButton(
              outlined: _canFinish && tired,
              icon: Icons.arrow_forward_rounded,
              onPressed: _nextRound,
              child: const Text('Next round'),
            ),
            if (_canFinish)
              VeeButton(
                outlined: !tired,
                icon: Icons.star_rounded,
                onPressed: _finish,
                child: const Text('Finish and collect stars'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _puzzleCard() {
    final puzzle = _challenge ??= PlayPuzzleBuilder.choose(
      pool: PlayPuzzleBuilder.poolForSetting(setting!.id, _mode),
      mode: _mode,
      random: random,
      age: GameAppScope.of(context).profile.age,
    );
    return _card(
      children: [
        const PillTag.coral('Something needs your help!'),
        const SizedBox(height: 10),
        PuzzleCard(
          key: ValueKey('explore-${puzzle.kind.name}'),
          puzzle: puzzle,
          onAttempt: (correct) => setState(() {
            _veePose = correct ? VeePose.celebration : VeePose.encourage;
            _veeBounce++;
          }),
          onSolved: () {
            if (!mounted) return;
            setState(() {
              challengeComplete = true;
              speechText = 'Perfect! The world changed because you helped.';
            });
            _chooseSurprise();
          },
        ),
      ],
    );
  }

  Future<void> _chooseSurprise() async {
    final c = GameAppScope.of(context);
    final items = ContentCatalog.forSetting(setting?.id ?? '');
    final source = items.isEmpty ? ContentCatalog.items.first : items.first;
    final pack = DiscoveryEngine.forItem(source);
    final allowed = pack.surpriseIds
        .map((id) {
          final event = DiscoveryEngine.event(id, mode: _mode);
          return SurpriseChoice(event.id, '${event.emoji} ${event.message}');
        })
        .toList(growable: false);
    final choice = await c.surpriseSelector.choose(
      allowed: allowed,
      context: setting?.name ?? 'explore',
    );
    if (!mounted) return;
    setState(() {
      _veePose = VeePose.surprised;
      _veeBounce++;
      surprise = choice.id;
      phase = _Phase.surprise;
    });
  }

  Widget _surpriseCard() {
    final event = DiscoveryEngine.event(surprise!, mode: _mode);
    return _card(
      children: [
        Text(event.emoji, style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 4),
        const PillTag.coral('A surprise!'),
        const SizedBox(height: 10),
        Text(event.title, textAlign: TextAlign.center, style: _headingStyle),
        const SizedBox(height: 6),
        Text(event.message, textAlign: TextAlign.center, style: _bodyStyle),
        const SizedBox(height: 16),
        VeeButton(
          icon: Icons.arrow_forward_rounded,
          onPressed: () => setState(() {
            phase = hiddenAreaOpen ? _Phase.roundDone : _Phase.tease;
            speechText = 'Wait… something is moving over there!';
          }),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  String get _hiddenLabel => (setting?.hiddenAreas.isNotEmpty ?? false)
      ? setting!.hiddenAreas.first
      : 'A secret place';

  Widget _teaseCard() {
    return JuicyTap(
      semanticLabel: 'Something is moving. Tap to look.',
      onTap: () {
        final c = GameAppScope.of(context);
        final item = _secretItem();
        c.addDiscovery('item-${item.id}');
        c.scheduleSave();
        Haptics.medium();
        setState(() {
          hiddenAreaOpen = true;
          phase = _Phase.secret;
          _veePose = VeePose.surprised;
          _veeBounce++;
          speechText =
              'A hidden place opened! There is one more thing to find.';
        });
      },
      child: _card(
        color: VeeTokens.yellow,
        children: [
          const Icon(Icons.spa_rounded, size: 54, color: VeeTokens.textOnLight),
          const SizedBox(height: 6),
          const Text(
            'Something is moving behind here…',
            textAlign: TextAlign.center,
            style: _headingStyle,
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap to look!',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: VeeTokens.textOnLight,
            ),
          ),
        ],
      ),
    );
  }

  CatalogItem _secretItem() {
    final items = ContentCatalog.forSetting(setting!.id);
    return items.isEmpty ? ContentCatalog.items.first : items.last;
  }

  Widget _secretCard() {
    final item = _secretItem();
    final c = GameAppScope.of(context);
    return _card(
      children: [
        Text(
          _hiddenLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: VeeTokens.teal,
          ),
        ),
        const SizedBox(height: 4),
        const PillTag.coral('Secret discovery!'),
        const SizedBox(height: 8),
        ItemIcon(item, size: 84),
        Text(
          '${item.name} was waiting here!',
          textAlign: TextAlign.center,
          style: _headingStyle,
        ),
        const SizedBox(height: 6),
        Text(
          DiscoveryEngine.forItem(item).wowDiscoveries.last,
          textAlign: TextAlign.center,
          style: _bodyStyle,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            VeeButton(
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                c.scheduleSave();
                _nextRound();
              },
              child: const Text('Keep exploring'),
            ),
            if (_canFinish)
              VeeButton(
                outlined: true,
                icon: Icons.star_rounded,
                onPressed: _finish,
                child: const Text('Finish and collect stars'),
              ),
          ],
        ),
      ],
    );
  }

  static const TextStyle _headingStyle = TextStyle(
    fontSize: 30,
    height: 1.08,
    fontWeight: FontWeight.w900,
    color: VeeTokens.textOnLight,
  );

  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: VeeTokens.textSecondaryOnLight,
  );

  Widget _card({required List<Widget> children, Color? color}) => Container(
    width: 520,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
    decoration: BoxDecoration(
      color: color ?? VeeTokens.mint.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );

  // ── finishing ────────────────────────────────────────────────────────────

  Future<void> _finish() async {
    if (_finishStarted) return;
    _finishStarted = true;

    final selectedSetting = setting;
    if (selectedSetting == null) {
      _finishStarted = false;
      return;
    }

    final c = GameAppScope.of(context);
    try {
      await c.finishActivity(
        activityId: 'explore-${selectedSetting.id}',
        completionToken: _completionToken,
        starsEarned: 4 + bonusStars + (worldMastered ? 1 : 0),
        discoveryIds: <String>[
          'explore-${selectedSetting.id}',
          if (worldMastered) 'world-${selectedSetting.id}',
        ],
      );
      if (!mounted) return;
      replaceTo(
        context,
        RewardScreen(
          activity: ActivityType.explore,
          discovery: worldMastered
              ? 'You found everything in ${selectedSetting.name}!'
              : 'You explored ${selectedSetting.name} and changed the world.',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save EXPLORE completion: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _finishStarted = false;
        speechText = 'Vee could not save that star. Please try again.';
      });
    }
  }
}

/// Five little sparkles that fill up as items are found.
class _SparkleMeter extends StatelessWidget {
  final int count;
  final int goal;

  const _SparkleMeter({required this.count, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sparkle meter: $count of $goal',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sparkles',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: VeeTokens.textOnLight,
              ),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < goal; i++)
              AnimatedScale(
                scale: i < count ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 30,
                  color: i < count ? VeeTokens.yellow : VeeTokens.creamDeep,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StickerChip extends StatelessWidget {
  final int have;
  final int total;

  const _StickerChip({required this.have, required this.total});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Stickers collected: $have of $total',
    child: ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: VeeTokens.mint,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_mosaic_rounded,
              size: 20,
              color: VeeTokens.teal,
            ),
            const SizedBox(width: 6),
            Text(
              'Stickers $have/$total',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: VeeTokens.textOnLight,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
