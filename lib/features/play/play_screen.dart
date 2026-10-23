import 'dart:math';

import 'package:flutter/material.dart';

import '../../widgets/adaptive_text.dart';

import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../app/design_tokens.dart';
import '../../models/activity.dart';
import '../../models/adventure_session.dart';
import '../../models/content_catalog.dart';
import '../../models/environment_mode.dart';
import '../../models/play_episode.dart';
import '../../services/activity_selection/movement_profile.dart';
import '../../services/movement/movement_catalog.dart';
import '../../services/discovery_engine.dart';
import '../../services/play/play_episode_catalog.dart';
import '../../widgets/movement_challenge.dart';
import '../../widgets/movement_vee_animation.dart';
import '../../widgets/world_shell.dart';
import '../hub/adventure_hub.dart';
import '../rewards/reward_screen.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});
  @override State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late PlayEpisode episode;
  late Future<PlayEpisode> _episodeFuture;
  final PlayAdventureSession _session = PlayAdventureSession();

  int get stage => _session.stageIndex;
  String get path => _session.path;
  String get status => _session.status;
  final Random random = Random();
  String? surpriseId;
  final List<String> sequence = [];
  bool _finishStarted = false;
  final String _completionToken =
      'play-${DateTime.now().microsecondsSinceEpoch}';

  final Map<int, MovementStep> _movementSteps = {};
  final MovementBag _movementBag = MovementBag(random: Random());

  MovementProfile get _movementProfile =>
      movementProfileFor(GameAppScope.of(context).profile.movementPreference);

  bool _initializedFromProfile = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // GameAppScope is an inherited widget. Read it here, not in initState.
    if (_initializedFromProfile) return;
    final controller = GameAppScope.of(context);
    final mode = controller.profile.environmentMode;
    _episodeFuture = PlayEpisodeCatalog.pickForMode(mode, random: random);
    _initializedFromProfile = true;
  }

  void _advanceSession(
    PlayStage next, {
    String? path,
    String? status,
  }) {
    final advanced = _session.advanceTo(next, path: path, status: status);
    if (!advanced) {
      debugPrint(
        'Rejected invalid PLAY transition: ${_session.stage} -> $next',
      );
    }
  }

  void _updateSessionStatus(String message) {
    _session.updateStatus(message);
  }

  MovementStep _nextMovement(int round) =>
      _movementBag.nextStep(
        _movementProfile,
        age: GameAppScope.of(context).profile.age,
      );

  MovementStep _movementForRound(int round) => _movementSteps.putIfAbsent(round, () => _nextMovement(round));

  String? _movementForStage() {
    final round = switch (stage) { 2 => 0, 5 => 1, 7 => 2, _ => null };
    return round == null ? null : _movementForRound(round).name;
  }

  Widget _staticVee() => Image.asset(stage >= 8 ? 'assets/vee/vee_celebration.webp' : 'assets/vee/vee_happy_idle.webp',
  fit: BoxFit.contain);

  Widget _vee() {
    final movementId = _movementForStage();
    if (movementId == null) return _staticVee();
    return MovementVeeAnimation(key: ValueKey('vee-$movementId'), movementId: movementId, fallback: _staticVee());
  }

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
          eyebrow:
              '${episode.mode == EnvironmentMode.indoor ? "🏠" : "🌳"} ${episode.mode.name.toUpperCase()} • PLAY • ${stage + 1}/10',
          onRestartMission: () => replaceTo(context, const PlayScreen()),
          onMainMenu: () => replaceTo(context, const AdventureHub()),
          right: _stageContent(),
          splitPlayLayout: true,
        );
      },
    );
  }

  Widget _episodeLoading() => Scaffold(
        backgroundColor: VeeTokens.cream,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              SizedBox(height: 16),
              Text(
                'Vee is preparing your adventure…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.textOnLight,
                ),
              ),
            ],
          ),
        ),
      );

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
                    'Check the episode data file and try again.',
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
                      style: const TextStyle(fontSize: 11, color: VeeTokens.textSecondaryOnLight),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _button(
                    'Try again',
                    () {
                      final mode = GameAppScope.of(context).profile.environmentMode;
                      setState(() {
                        _episodeFuture = PlayEpisodeCatalog.pickForMode(
                          mode,
                          random: random,
                        );
                      });
                    },
                    VeeTokens.yellow,
                  ),
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
    if (stage == 1) return 'Pick a path. Every choice reveals a different part of the mystery!';
    if (stage == 2) return 'Something is waking up! Help Vee with your movement power.';
    if (stage == 3) return 'WAIT… did you see that? The world just reacted to what you did!';
    if (stage == 4) return 'A clue is hiding in the objects around us. Can you put the right thing where it belongs?';
    if (stage == 5) return 'The trail continues. One more movement might unlock the next secret.';
    if (stage == 6) return 'Vee found a mystery clue. Use what you discovered to solve it!';
    if (stage == 7) return 'The final lock needs your movement magic!';
    if (stage == 8) return 'You made it! But every good adventure needs one last surprise…';
    return 'You changed the world. Vee will remember this discovery!';
  }

  Widget _stageContent() {
    switch (stage) {
      case 0: return _intro();
      case 1: return _choice();
      case 2: return _movementStage(0);
      case 3: return _surpriseStage();
      case 4: return _puzzle();
      case 5: return _movementStage(1);
      case 6: return _mystery();
      case 7: return _movementStage(2);
      case 8: return _finaleSurprise();
      default: return _finish();
    }
  }

  Widget _intro() => _card(Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('✨', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 5),
        Text(episode.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: VeeTokens.textOnLight),
          textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('A short adventure where your actions can change what happens next.', textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, color: VeeTokens.textSecondaryOnLight)),
        const SizedBox(height: 17),
        _button('Enter the mystery ✨', () => setState(() => _advanceSession(PlayStage.pathChoice)), VeeTokens.yellow),
      ]));

  Widget _choice() => _card(Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🗺️ Which way should we go?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: VeeTokens.textOnLight),
          textAlign: TextAlign.center),
        const SizedBox(height: 6),
        const Text('There is no bad choice. Your path changes the story.', textAlign: TextAlign.center),
        const SizedBox(height: 15),
        Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: episode.paths.map((p) => GestureDetector(
          onTap: () => setState(() => _advanceSession(PlayStage.firstMovement, path: p, status: 'The $p revealed a hidden clue.')),
          child: Container(width: 155, padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16), decoration: BoxDecoration(color: VeeTokens.white,
          borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: VeeTokens.shadow, blurRadius: 10,
          offset: Offset(0,5))]), child: Text(p, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17,
            fontWeight: FontWeight.w900,
            color: VeeTokens.textOnLight))),
        )).toList()),
        if (path.isNotEmpty) ...[const SizedBox(height: 8), Text('You chose: $path', style: const TextStyle(fontWeight: FontWeight.w800,
          color: VeeTokens.teal))],
      ]));

  Widget _movementStage(int round) {
    final step = _movementForRound(round);
    final titles = ['Wake the hidden trail', 'Cross the magic bridge', 'Power the final gate'];
    final descriptions = [
      'Move like Vee’s helper. Your movement wakes something in the world.',
      'The bridge is changing! Complete the movement to keep the adventure moving.',
      'Three little movement powers are enough to reveal the final secret.',
    ];
    return _card(Column(mainAxisSize: MainAxisSize.min, children: [
      Text('💥 ${titles[round]}', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: VeeTokens.textOnLight),
        textAlign: TextAlign.center),
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
      MovementChallenge(key: ValueKey('play-$round-$path'), step: step, onComplete: () {
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
      }),
      if (status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(status, textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900, color: VeeTokens.teal))),
    ]));
  }

  Widget _surpriseStage() {
    final event = DiscoveryEngine.event(surpriseId ?? episode.surpriseIds.first, mode: episode.mode);
    return _card(Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Text(event.emoji, key: ValueKey(event.id),
        style: const TextStyle(fontSize: 62))),
      const SizedBox(height: 5),
      Text(event.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: VeeTokens.textOnLight),
        textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(event.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
        color: VeeTokens.textSecondaryOnLight)),
      const SizedBox(height: 10),
      Text('💡 ${DiscoveryEngine.forItem(ContentCatalog.get(episode.objectId)!).wowDiscoveries[stage % DiscoveryEngine.forItem(ContentCatalog.get(episode.objectId)!).wowDiscoveries.length]}',
      textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: VeeTokens.textOnLight)),
      const SizedBox(height: 15),
      _button('Follow the mystery →', () => setState(() => _advanceSession(PlayStage.puzzle, status: 'The surprise left a clue behind.')),
        VeeTokens.yellow),
    ]));
  }

  Widget _puzzle() {
    final setting = ContentCatalog.settingsById[episode.setting]!;
    final items = ContentCatalog.forSetting(setting.id).take(_movementProfile == MovementProfile.energetic ? 4 : 3).toList();
    final target = ContentCatalog.get(episode.objectId)!;
    return _card(Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🧩 The clue puzzle', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: VeeTokens.textOnLight)),
      const SizedBox(height: 6),
      Text('One of these discoveries belongs in the glowing space. Look for ${target.name}.', textAlign: TextAlign.center),
      const SizedBox(height: 13),
      Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: items.map((item) => Draggable<String>(
        data: item.id,
        feedback: Material(color: Colors.transparent, child: Text(item.emoji, style: const TextStyle(fontSize: 54))),
        childWhenDragging: Opacity(opacity: .25, child: Text(item.emoji, style: const TextStyle(fontSize: 42))),
        child: Container(width: 78, height: 72, alignment: Alignment.center, decoration: BoxDecoration(color: VeeTokens.white,
        borderRadius: BorderRadius.circular(20)), child: Text(item.emoji, style: const TextStyle(fontSize: 42))),
      )).toList()),
      const SizedBox(height: 13),
      DragTarget<String>(
        onAcceptWithDetails: (details) {
          if (details.data == target.id) {
            final pack = DiscoveryEngine.forItem(target);
            GameAppScope.of(context).addDiscovery('play-puzzle-${target.id}');
            setState(() => _advanceSession(PlayStage.secondMovement, status: pack.wowDiscoveries.first));
          } else {
            setState(() => _updateSessionStatus('Interesting choice! But the clue is pointing somewhere else.'));
          }
        },
        builder: (_, __, ___) => Container(width: 170, height: 68, alignment: Alignment.center, decoration: BoxDecoration(color: VeeTokens.yellow.withOpacity(.55),
        borderRadius: BorderRadius.circular(20)), child: Text('✨ PUT IT HERE', style: const TextStyle(fontWeight: FontWeight.w900,
          color: VeeTokens.textOnLight))),
      ),
      if (status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(status, textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800))),
    ]));
  }

  Widget _mystery() {
    final target = ContentCatalog.get(episode.objectId)!;
    final pack = DiscoveryEngine.forItem(target);
    final clues = pack.mysteryClues.take(_movementProfile == MovementProfile.gentle ? 2 : 3).toList();
    final options = ContentCatalog.forSetting(episode.setting).take(4).toList();
    return _card(Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🕵️ Vee’s mystery clue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: VeeTokens.textOnLight)),
      const SizedBox(height: 7),
      Text(clues.join('\n'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
        color: VeeTokens.textSecondaryOnLight)),
      const SizedBox(height: 12),
      Wrap(alignment: WrapAlignment.center, spacing: 9, runSpacing: 9, children: options.map((item) => GestureDetector(
        onTap: () {
          if (item.id == target.id) {
            setState(() => _advanceSession(PlayStage.finalMovement, status: '🎉 Mystery solved! ${pack.wowDiscoveries[1 % pack.wowDiscoveries.length]}'));
          } else {
            setState(() => _updateSessionStatus('Not quite! Vee found one more tiny clue.'));
          }
        },
        child: Container(width: 112, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: VeeTokens.white,
        borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: VeeTokens.shadow, blurRadius: 8,
        offset: Offset(0,4))]), child: Column(children: [Text(item.emoji, style: const TextStyle(fontSize: 35)), Text(item.name,
        textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: VeeTokens.textOnLight))])),
      )).toList()),
      if (status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(status, textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, color: VeeTokens.teal))),
    ]));
  }

  Widget _finaleSurprise() {
    final id = surpriseId ?? episode.surpriseIds.last;
    final event = DiscoveryEngine.event(id, mode: episode.mode);
    return _card(Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🌟 ONE LAST SECRET', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: VeeTokens.textOnLight)),
      const SizedBox(height: 5),
      Text(event.emoji, style: const TextStyle(fontSize: 65)),
      const SizedBox(height: 5),
      Text(event.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: VeeTokens.textOnLight),
        textAlign: TextAlign.center),
      const SizedBox(height: 7),
      Text(event.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
        color: VeeTokens.textSecondaryOnLight)),
      const SizedBox(height: 14),
      _button('Reveal the ending ✨', () => setState(() => _advanceSession(PlayStage.ending, status: '')), VeeTokens.yellow),
    ]));
  }

  Widget _finish() => _card(Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎁 Adventure unlocked!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: VeeTokens.textOnLight),
          textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('$path changed what Vee discovered today.', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700,
          color: VeeTokens.textSecondaryOnLight)),
        const SizedBox(height: 8),
        const Text('This discovery has been added to Vee’s memory.', textAlign: TextAlign.center),
        const SizedBox(height: 15),
        _button('Collect the adventure star ⭐', _finishGame, VeeTokens.yellow),
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
      ]));

  Future<void> _finishGame() async {
    if (_finishStarted) return;
    _finishStarted = true;

    final c = GameAppScope.of(context);
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
          discovery: 'You unlocked a new secret in ${episode.title}.',
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

  String _prettyMove(String id) => id.split('_').map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');

  Widget _card(Widget child) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 640),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(color: VeeTokens.cream, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: VeeTokens.shadow,
          blurRadius: 16, offset: Offset(0, 8))]),
        child: DefaultTextStyle.merge(textAlign: TextAlign.center, child: child),
      );

  Widget _button(String label, VoidCallback onTap, Color color) => GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 190, maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: VeeTokens.shadow,
            blurRadius: 10, offset: Offset(0,5))]),
          alignment: Alignment.center,
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: VeeTextContrast.foregroundFor(color))),
        ),
      );
}
