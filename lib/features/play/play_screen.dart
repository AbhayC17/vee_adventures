import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../app/design_tokens.dart';
import '../../models/activity.dart';
import '../../models/adventure_session.dart';
import '../../models/content_catalog.dart';
import '../../models/play_episode.dart';
import '../../services/activity_selection/movement_profile.dart';
import '../../services/movement/movement_catalog.dart';
import '../../services/discovery_engine.dart';
import '../../services/play/play_episode_catalog.dart';
import '../../services/play/play_puzzles.dart';
import '../../widgets/juicy_tap.dart';
import '../../widgets/movement_challenge.dart';
import '../../widgets/movement_vee_animation.dart';
import '../../widgets/puzzle_card.dart';
import '../../widgets/vee_avatar.dart';
import '../../widgets/vee_button.dart';
import '../../widgets/vee_loading.dart';
import '../../widgets/world_shell.dart';
import '../hub/adventure_hub.dart';
import '../rewards/reward_screen.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late PlayEpisode episode;
  late Future<PlayEpisode> _episodeFuture;
  final PlayAdventureSession _session = PlayAdventureSession();

  int get stage => _session.stageIndex;
  String get path => _session.path;
  String get status => _session.status;
  final Random random = Random();
  final List<String> sequence = [];
  bool _finishStarted = false;
  final String _completionToken =
      'play-${DateTime.now().microsecondsSinceEpoch}';

  final Map<int, MovementStep> _movementSteps = {};
  final MovementBag _movementBag = MovementBag(random: Random());

  // What happens in this run depends on the path the child chooses, so two
  // runs of the same story are not identical.
  String? _firstSurpriseId;
  String? _finaleSurpriseId;
  PlayPuzzle? _puzzle;
  PlayPuzzle? _mystery;

  // Vee reacts to what the child does.
  VeePose _veePose = VeePose.happy;
  int _veeBounce = 0;

  MovementProfile get _movementProfile =>
      movementProfileFor(GameAppScope.of(context).profile.movementPreference);

  bool _initializedFromProfile = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // GameAppScope is an inherited widget. Read it here, not in initState.
    if (_initializedFromProfile) return;
    final controller = GameAppScope.of(context);
    final mode = controller.profile.environmentMode;
    _episodeFuture = PlayEpisodeCatalog.pickFresh(mode, random: random);
    _initializedFromProfile = true;
  }

  void _advanceSession(PlayStage next, {String? path, String? status}) {
    final advanced = _session.advanceTo(next, path: path, status: status);
    if (!advanced) {
      debugPrint(
        'Rejected invalid PLAY transition: ${_session.stage} -> $next',
      );
      return;
    }
    _veePose = _basePose(next);
  }

  /// Vee's pose for the start of each stage: thinking while the child solves
  /// something, surprised when the world does something, cheering at the end.
  VeePose _basePose(PlayStage stage) => switch (stage) {
    PlayStage.puzzle || PlayStage.mystery => VeePose.thinking,
    PlayStage.firstSurprise || PlayStage.finaleSurprise => VeePose.surprised,
    PlayStage.ending => VeePose.celebration,
    _ => VeePose.happy,
  };

  void _updateSessionStatus(String message) {
    _session.updateStatus(message);
  }

  void _reactVee(VeePose pose) {
    setState(() {
      _veePose = pose;
      _veeBounce++;
    });
  }

  MovementStep _nextMovement(int round) => _movementBag.nextStep(
    _movementProfile,
    age: GameAppScope.of(context).profile.age,
  );

  MovementStep _movementForRound(int round) =>
      _movementSteps.putIfAbsent(round, () => _nextMovement(round));

  String? _movementForStage() {
    final round = switch (stage) {
      2 => 0,
      5 => 1,
      7 => 2,
      _ => null,
    };
    return round == null ? null : _movementForRound(round).name;
  }

  Widget _staticVee() => VeeAvatar(
    pose: stage >= 8 ? VeePose.celebration : _veePose,
    bounce: _veeBounce,
  );

  Widget _vee() {
    final movementId = _movementForStage();
    if (movementId == null) return _staticVee();
    return MovementVeeAnimation(
      key: ValueKey('vee-$movementId'),
      movementId: movementId,
      fallback: _staticVee(),
    );
  }

  // ── per-run content ────────────────────────────────────────────────────

  /// The chosen path decides the first surprise. The finale is always a
  /// different one, picked at random, so there are several endings.
  void _choosePath(String chosen) {
    final ids = episode.surpriseIds;
    final index = max(0, episode.paths.indexOf(chosen));
    final first = index % ids.length;
    final offset = ids.length > 1 ? 1 + random.nextInt(ids.length - 1) : 0;
    _firstSurpriseId = ids[first];
    _finaleSurpriseId = ids[(first + offset) % ids.length];
    setState(() {
      _advanceSession(
        PlayStage.firstMovement,
        path: chosen,
        status: 'The $chosen revealed a hidden clue.',
      );
    });
  }

  CatalogItem get _target => ContentCatalog.get(episode.objectId)!;

  List<CatalogItem> get _pool =>
      PlayPuzzleBuilder.poolForSetting(episode.setting, episode.mode);

  PlayPuzzle _puzzleForRun() => _puzzle ??= PlayPuzzleBuilder.choose(
    pool: _pool,
    mode: episode.mode,
    random: random,
    target: _target,
    age: GameAppScope.of(context).profile.age,
    optionCount: _movementProfile == MovementProfile.energetic ? 4 : 3,
  );

  PlayPuzzle _mysteryForRun() => _mystery ??= PlayPuzzleBuilder.build(
    PlayPuzzleKind.clueGuess,
    pool: _pool,
    mode: episode.mode,
    random: random,
    target: _target,
    clueCount: _movementProfile == MovementProfile.gentle ? 2 : 3,
    optionCount: 4,
  );

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_initializedFromProfile) return const SizedBox.shrink();

    return FutureBuilder<PlayEpisode>(
      future: _episodeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _episodeLoading();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _episodeLoadFailure(snapshot.error);
        }

        episode = snapshot.data!;
        return WorldShell(
          left: _vee(),
          speech: _speech(),
          stepLabel: 'Play',
          stepCurrent: stage,
          stepTotal: 10,
          onRestartMission: () => replaceTo(context, const PlayScreen()),
          onMainMenu: () => replaceTo(context, const AdventureHub()),
          right: _stageArea(),
        );
      },
    );
  }

  Widget _episodeLoading() =>
      const VeeLoading(message: 'Vee is preparing your adventure…');

  Widget _episodeLoadFailure(Object? error) => Scaffold(
    backgroundColor: VeeTokens.cream,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('🧭', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 12),
              const Text(
                'Vee could not load this adventure.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.textOnLight,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VeeTokens.textSecondaryOnLight),
              ),
              if (error != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: VeeTokens.textSecondaryOnLight,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _button('Try again', () {
                final mode = GameAppScope.of(context).profile.environmentMode;
                setState(() {
                  _episodeFuture = PlayEpisodeCatalog.pickFresh(
                    mode,
                    random: random,
                  );
                });
              }, VeeTokens.yellow),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => replaceTo(context, const AdventureHub()),
                child: const Text('Return to adventure hub'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String _speech() {
    if (stage == 0) return episode.hook;
    if (stage == 1) {
      return 'Pick a path. Every choice reveals a different part of the mystery!';
    }
    if (stage == 2) {
      return 'Something is waking up! Help Vee with your movement power.';
    }
    if (stage == 3) {
      return 'WAIT… did you see that? The $path showed us something new!';
    }
    if (stage == 4) return 'Time for a little puzzle. Take your time!';
    if (stage == 5) {
      return 'The trail continues. One more movement might unlock the next secret.';
    }
    if (stage == 6) {
      return 'Vee found a mystery clue. Use what you discovered to solve it!';
    }
    if (stage == 7) return 'The final lock needs your movement magic!';
    if (stage == 8) {
      return 'You made it! But every good adventure needs one last surprise…';
    }
    return 'You changed the world. Vee will remember this discovery!';
  }

  /// The progress dots and the current stage, which fades and slides in
  /// whenever the adventure moves on.
  Widget _stageArea() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: Duration(milliseconds: reduceMotion ? 0 : 320),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey<int>(stage),
            child: _stageContent(),
          ),
        ),
      ],
    );
  }

  Widget _stageContent() {
    switch (stage) {
      case 0:
        return _intro();
      case 1:
        return _choice();
      case 2:
        return _movementStage(0);
      case 3:
        return _surpriseStage();
      case 4:
        return _puzzleStage();
      case 5:
        return _movementStage(1);
      case 6:
        return _mysteryStage();
      case 7:
        return _movementStage(2);
      case 8:
        return _finaleSurprise();
      default:
        return _finish();
    }
  }

  Widget _intro() => _card(
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('✨', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 5),
        Text(
          episode.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: VeeTokens.textOnLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'A short adventure where your actions can change what happens next.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: VeeTokens.textSecondaryOnLight,
          ),
        ),
        const SizedBox(height: 17),
        _button(
          'Enter the mystery ✨',
          () => setState(() => _advanceSession(PlayStage.pathChoice)),
          VeeTokens.yellow,
        ),
      ],
    ),
  );

  Widget _choice() => _card(
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🗺️ Which way should we go?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: VeeTokens.textOnLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'There is no bad choice. Your path changes the story.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: episode.paths
              .map(
                (p) => JuicyTap(
                  onTap: () => _choosePath(p),
                  child: Container(
                    width: 155,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: VeeTokens.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: VeeTokens.shadow,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      p,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: VeeTokens.textOnLight,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _movementStage(int round) {
    final step = _movementForRound(round);
    final titles = [
      'Wake the hidden trail',
      'Cross the magic bridge',
      'Power the final gate',
    ];
    final descriptions = [
      'Move like Vee’s helper. Your movement wakes something in the world.',
      'The bridge is changing! Complete the movement to keep the adventure moving.',
      'Three little movement powers are enough to reveal the final secret.',
    ];
    return _card(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '💥 ${titles[round]}',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(descriptions[round], textAlign: TextAlign.center),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: VeeTokens.mint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Vee says: ${_prettyMove(step.name)} × ${step.count}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: VeeTokens.teal,
              ),
            ),
          ),
          const SizedBox(height: 12),
          MovementChallenge(
            key: ValueKey('play-$round-$path'),
            step: step,
            // Vee hops every time the child counts a movement.
            onCount: (_) => setState(() => _veeBounce++),
            onComplete: () {
              if (!mounted) return;
              setState(() {
                final nextStage = switch (round) {
                  0 => PlayStage.firstSurprise,
                  1 => PlayStage.mystery,
                  _ => PlayStage.finaleSurprise,
                };
                final nextStatus = round == 0
                    ? '✨ The trail woke up!'
                    : round == 1
                    ? '🌉 The bridge changed shape!'
                    : '⭐ The gate is glowing!';
                _advanceSession(nextStage, status: nextStatus);
              });
            },
          ),
          if (status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.teal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _surpriseStage() {
    final event = DiscoveryEngine.event(
      _firstSurpriseId ?? episode.surpriseIds.first,
      mode: episode.mode,
    );
    final wow = DiscoveryEngine.forItem(_target).wowDiscoveries;
    final index = max(0, episode.paths.indexOf(path));
    return _card(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              event.emoji,
              key: ValueKey(event.id),
              style: const TextStyle(fontSize: 62),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            event.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: VeeTokens.textSecondaryOnLight,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '💡 ${wow[(index + stage) % wow.length]}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: VeeTokens.textOnLight,
            ),
          ),
          const SizedBox(height: 15),
          _button(
            'Follow the mystery →',
            () => setState(
              () => _advanceSession(
                PlayStage.puzzle,
                status: 'The surprise left a clue behind.',
              ),
            ),
            VeeTokens.yellow,
          ),
        ],
      ),
    );
  }

  Widget _puzzleStage() {
    final puzzle = _puzzleForRun();
    return _card(
      PuzzleCard(
        key: ValueKey('puzzle-${puzzle.kind.name}'),
        puzzle: puzzle,
        onAttempt: (correct) =>
            _reactVee(correct ? VeePose.celebration : VeePose.encourage),
        onSolved: () {
          if (!mounted) return;
          final pack = DiscoveryEngine.forItem(puzzle.answer);
          GameAppScope.of(context)
              .addDiscovery('play-puzzle-${puzzle.answer.id}');
          setState(
            () => _advanceSession(
              PlayStage.secondMovement,
              status: pack.wowDiscoveries.first,
            ),
          );
        },
      ),
    );
  }

  Widget _mysteryStage() {
    final mystery = _mysteryForRun();
    final pack = DiscoveryEngine.forItem(mystery.answer);
    return _card(
      PuzzleCard(
        key: const ValueKey('mystery'),
        puzzle: mystery,
        onAttempt: (correct) =>
            _reactVee(correct ? VeePose.celebration : VeePose.encourage),
        onSolved: () {
          if (!mounted) return;
          setState(
            () => _advanceSession(
              PlayStage.finalMovement,
              status:
                  '🎉 Mystery solved! ${pack.wowDiscoveries[1 % pack.wowDiscoveries.length]}',
            ),
          );
        },
      ),
    );
  }

  Widget _finaleSurprise() {
    final id = _finaleSurpriseId ?? episode.surpriseIds.last;
    final event = DiscoveryEngine.event(id, mode: episode.mode);
    return _card(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🌟 ONE LAST SECRET',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
          ),
          const SizedBox(height: 5),
          Text(event.emoji, style: const TextStyle(fontSize: 65)),
          const SizedBox(height: 5),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            event.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: VeeTokens.textSecondaryOnLight,
            ),
          ),
          const SizedBox(height: 14),
          _button(
            'Reveal the ending ✨',
            () => setState(() => _advanceSession(PlayStage.ending, status: '')),
            VeeTokens.yellow,
          ),
        ],
      ),
    );
  }

  Widget _finish() {
    final event = DiscoveryEngine.event(
      _finaleSurpriseId ?? episode.surpriseIds.last,
      mode: episode.mode,
    );
    return _card(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🎁 Adventure unlocked!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Because you chose the $path, Vee discovered ${event.title} ${event.emoji}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: VeeTokens.textSecondaryOnLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This discovery has been added to Vee’s memory.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          _button(
            'Collect the adventure star ⭐',
            _finishGame,
            VeeTokens.yellow,
          ),
          if (status.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: VeeTokens.teal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _finishGame() async {
    if (_finishStarted) return;
    _finishStarted = true;

    final c = GameAppScope.of(context);
    final finale = DiscoveryEngine.event(
      _finaleSurpriseId ?? episode.surpriseIds.last,
      mode: episode.mode,
    );
    try {
      final saved = await c.finishActivity(
        activityId: 'play-${episode.id}',
        completionToken: _completionToken,
        starsEarned: 6,
        discoveryIds: <String>['play-${episode.id}'],
      );
      if (!saved) {
        if (!mounted) return;
        setState(() {
          _finishStarted = false;
          _updateSessionStatus('Vee has already saved this adventure.');
        });
        return;
      }
      _session.markFinished();
      if (!mounted) return;
      replaceTo(
        context,
        RewardScreen(
          activity: ActivityType.play,
          discovery: 'You unlocked ${finale.title} in ${episode.title}.',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save PLAY completion: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _finishStarted = false;
        _updateSessionStatus('Vee could not save that star. Please try again.');
      });
    }
  }

  String _prettyMove(String id) => id
      .split('_')
      .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');

  Widget _card(Widget child) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(maxWidth: 640),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      color: VeeTokens.cream,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: VeeTokens.shadow,
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: DefaultTextStyle.merge(textAlign: TextAlign.center, child: child),
  );

  /// Every PLAY button is the main teal pill (the colour argument is kept so
  /// older call sites still read naturally).
  Widget _button(String label, VoidCallback onTap, Color color) => VeeButton(
    onPressed: onTap,
    minWidth: 220,
    maxWidth: 380,
    child: Text(label),
  );
}
