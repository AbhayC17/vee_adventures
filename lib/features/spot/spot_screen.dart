import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import '../../app/app_controller.dart';
import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../app/design_tokens.dart';
import '../../models/activity.dart';
import '../../models/content_catalog.dart';
import '../../models/environment_mode.dart';
import '../../services/activity_selection/movement_profile.dart';
import '../../services/discovery_engine.dart';
import '../../services/movement/movement_catalog.dart';
import '../../services/spot/discovery_analyzer.dart';
import '../../services/spot/open_discovery_rules.dart';
import '../../widgets/item_icon.dart';
import '../../widgets/juicy_tap.dart';
import '../../widgets/movement_challenge.dart';
import '../../widgets/vee_avatar.dart';
import '../../widgets/scene_background.dart';
import '../../widgets/scene_ui.dart';
import '../../widgets/vee_button.dart';
import '../../widgets/vee_loading.dart';
import '../../widgets/world_shell.dart';
import '../hub/adventure_hub.dart';
import '../rewards/reward_screen.dart';

class SpotClue {
  final String title;
  final String prompt;
  final String property;
  final String value;
  final String? secondProperty;
  final String? secondValue;

  const SpotClue({
    required this.title,
    required this.prompt,
    required this.property,
    required this.value,
    this.secondProperty,
    this.secondValue,
  });
}

class SpotMission {
  final String id;
  final String title;
  final String opening;
  final List<SpotClue> clues;
  final EnvironmentMode mode;
  final List<String> allowedSettings;

  const SpotMission({
    required this.id,
    required this.title,
    required this.opening,
    required this.clues,
    required this.mode,
    required this.allowedSettings,
  });
}

const _missions = <SpotMission>[
  SpotMission(
    id: 'indoor_detective',
    title: 'Vee’s Indoor Mystery Trail',
    opening: 'Something ordinary is hiding a surprising secret. Let’s become discovery detectives!',
    mode: EnvironmentMode.indoor,
    allowedSettings: [
      'kitchen',
      'bedroom',
      'bathroom',
      'hall',
      'dining',
      'library',
      'shop',
    ],
    clues: [
      SpotClue(
        title: 'SHAPE CLUE',
        prompt: 'Find something ROUND indoors.',
        property: 'shapes',
        value: 'round',
      ),
      SpotClue(
        title: 'TEXTURE CLUE',
        prompt: 'Find something SMOOTH.',
        property: 'textures',
        value: 'smooth',
      ),
      SpotClue(
        title: 'SECRET OBJECT',
        prompt: 'Find an everyday OBJECT that could hide a story.',
        property: 'groups',
        value: 'objects',
      ),
    ],
  ),
  SpotMission(
    id: 'kitchen_hunt',
    title: 'The Kitchen Mystery',
    opening: 'Vee heard a tiny clink in the kitchen. Can you find the object that fits the clues?',
    mode: EnvironmentMode.indoor,
    allowedSettings: ['kitchen', 'dining', 'shop'],
    clues: [
      SpotClue(
        title: 'FOOD CLUE',
        prompt: 'Find something that can be FOOD.',
        property: 'groups',
        value: 'food',
      ),
      SpotClue(
        title: 'COLOR CLUE',
        prompt: 'Find something YELLOW.',
        property: 'colors',
        value: 'yellow',
      ),
      SpotClue(
        title: 'SHAPE CLUE',
        prompt: 'Find something ROUND.',
        property: 'shapes',
        value: 'round',
      ),
    ],
  ),
  SpotMission(
    id: 'outdoor_nature_trail',
    title: 'Vee’s Outdoor Mystery Trail',
    opening: 'Something in the outdoor world has left a clue. Use your explorer eyes!',
    mode: EnvironmentMode.outdoor,
    allowedSettings: ['garden', 'park', 'forest', 'beach', 'road'],
    clues: [
      SpotClue(
        title: 'COLOR CLUE',
        prompt: 'Find something GREEN outside.',
        property: 'colors',
        value: 'green',
      ),
      SpotClue(
        title: 'LIVING WORLD',
        prompt: 'Find something from the world of PLANTS.',
        property: 'groups',
        value: 'plants',
      ),
      SpotClue(
        title: 'SHAPE CLUE',
        prompt: 'Find something ROUND outside.',
        property: 'shapes',
        value: 'round',
      ),
    ],
  ),
  SpotMission(
    id: 'garden_detective',
    title: 'The Garden Secret',
    opening: 'Flowers, leaves and tiny visitors are hiding a chain of clues. Look closely!',
    mode: EnvironmentMode.outdoor,
    allowedSettings: ['garden', 'park', 'forest'],
    clues: [
      SpotClue(
        title: 'PLANT CLUE',
        prompt: 'Find a PLANT.',
        property: 'groups',
        value: 'plants',
      ),
      SpotClue(
        title: 'GREEN CLUE',
        prompt: 'Find something GREEN.',
        property: 'colors',
        value: 'green',
      ),
      SpotClue(
        title: 'NATURE CLUE',
        prompt: 'Find another thing from NATURE.',
        property: 'groups',
        value: 'plants',
      ),
    ],
  ),
];

class SpotScreen extends StatefulWidget {
  const SpotScreen({super.key});

  @override
  State<SpotScreen> createState() => _SpotScreenState();
}

class _SpotScreenState extends State<SpotScreen> {
  // Shuffle missions in a bag so every mission for the selected environment is
  // played once before a mission repeats. Separate bags keep indoor/outdoor
  // progression independent. This also avoids the old timestamp-modulo pattern,
  // which could repeatedly choose the same mission.
  static final math.Random _random = math.Random();
  static final Map<EnvironmentMode, List<String>> _missionBags = {};
  static final Map<EnvironmentMode, String> _lastMissionByMode = {};

  static SpotMission _drawMission(
    List<SpotMission> pool,
    EnvironmentMode mode,
  ) {
    final bag = _missionBags.putIfAbsent(mode, () => <String>[]);
    if (bag.isEmpty) {
      bag.addAll(pool.map((mission) => mission.id));
      bag.shuffle(_random);
      final lastId = _lastMissionByMode[mode];
      if (bag.length > 1 && bag.first == lastId) {
        final swapIndex = 1 + _random.nextInt(bag.length - 1);
        final first = bag[0];
        bag[0] = bag[swapIndex];
        bag[swapIndex] = first;
      }
    }
    final id = bag.removeAt(0);
    _lastMissionByMode[mode] = id;
    return pool.firstWhere((mission) => mission.id == id);
  }

  int clueIndex = 0;
  int completed = 0;
  Uint8List? photo;
  IdentifiedCatalogItem? identified;
  bool analyzing = false;
  // When set, the child picks from pictures instead of using a photo. This
  // works without a camera or internet, and sends nothing anywhere.
  List<CatalogItem>? _pickOptions;
  late SpotMission mission;
  String status = '';
  CatalogItem? revealItem;
  DiscoveryPack? revealPack;
  int revealStage = 0;
  String? whatIfChoice;
  // A "discover anything" find (an object outside the game's own catalogue).
  OpenOutcome? _openFind;
  int _openStage = 0;
  MovementStep? _openStep;
  bool _finishStarted = false;
  final String _completionToken =
      'spot-${DateTime.now().microsecondsSinceEpoch}';

  bool _initializedFromProfile = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // GameAppScope is inherited state, so it must be read after initState.
    if (_initializedFromProfile) return;
    final controller = GameAppScope.of(context);
    final mode = controller.profile.environmentMode;
    final pool = _missions.where((m) => m.mode == mode).toList();
    final available = pool.isNotEmpty ? pool : _missions;
    final base = _drawMission(available, mode);
    final profile = movementProfileFor(controller.profile.movementPreference);
    final clueCount = profile == MovementProfile.gentle ? 2 : 3;
    // Randomize clue order as well as mission order, so a trail does not always
    // begin with the same colour/category prompt.
    final shuffledClues = List<SpotClue>.of(base.clues)..shuffle(_random);
    final selected = shuffledClues.take(clueCount).toList();
    if (profile == MovementProfile.energetic && selected.length >= 2) {
      final original = selected[1];
      selected[1] = SpotClue(
        title: '${original.title} + SHAPE',
        prompt:
            '${original.prompt.replaceFirst('.', '')} and make sure it is ROUND.',
        property: original.property,
        value: original.value,
        secondProperty: 'shapes',
        secondValue: 'round',
      );
    }
    mission = SpotMission(
      id: base.id,
      title: base.title,
      opening: base.opening,
      mode: base.mode,
      allowedSettings: base.allowedSettings,
      clues: selected,
    );
    _initializedFromProfile = true;
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        // A smaller picture uploads and is identified noticeably faster.
        maxWidth: 768,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        photo = bytes;
        identified = null;
        status = '';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => status =
              'Vee could not open that discovery. Let’s try another way.',
        );
      }
    }
  }

  String _failureMessage(String failure) =>
      failure.contains('MISSING_GROQ_API_KEY')
      ? 'Vee’s picture helper is not connected yet. Please ask a grown-up to check the game setup.'
      : failure.contains('IMAGE_PAYLOAD_TOO_LARGE')
      ? 'That picture is a little too large. Try taking a new photo closer to the object.'
      : failure.contains('INVALID_MODEL_RESULT') ||
            failure.contains('MODEL_RETURNED_DISALLOWED_ID')
      ? 'Vee could not match that picture. Try another photo with one object in the middle.'
      : failure.contains('GROQ_TIMEOUT') ||
            failure.contains('too long to respond')
      ? 'Vee’s picture helper is taking too long. Please try again in a moment.'
      : 'Vee could not connect to her picture helper. Please try again in a moment.';

  Future<void> _identify() async {
    if (photo == null || analyzing) return;
    setState(() {
      analyzing = true;
      status = 'Vee is looking VERY closely…';
    });
    final c = GameAppScope.of(context);
    final allowed = ContentCatalog.items
        .where((item) => item.settings.any(mission.allowedSettings.contains))
        .map((e) => e.id)
        .toList();

    // A grown-up can allow Vee to name any object, not just the game's own.
    if (c.openDiscoveryEnabled) {
      await _identifyOpen(c, allowed);
      return;
    }

    final result = await c.spotAnalyzer.identify(
      bytes: photo!.toList(),
      allowedCatalogIds: allowed,
    );
    if (!mounted) return;
    if (result == null) {
      final failure = c.spotAnalyzer.lastError ?? '';
      if (failure.contains('MODEL_UNCERTAIN')) {
        // The photo was fine; the object just is not one Vee knows. Say so and
        // offer the objects she does know.
        setState(() {
          analyzing = false;
          status = 'Vee doesn’t know that one yet! Pick one of these, or ask a grown-up to turn on “Discover anything”.';
          _pickOptions = _pickCandidates();
        });
        return;
      }
      setState(() {
        analyzing = false;
        status = _failureMessage(failure);
      });
      return;
    }
    _applyResult(result);
  }

  Future<void> _identifyOpen(AppController c, List<String> allowed) async {
    final profile = movementProfileFor(c.profile.movementPreference);
    final movementIds = MovementCatalog.forProfile(profile)
        .map((m) => m.id)
        .toList();
    final outcome = await c.openDiscoveryService.discover(
      bytes: photo!.toList(),
      allowedCatalogIds: allowed,
      movementIds: movementIds,
      cluePrompt: mission.clues[clueIndex].prompt,
    );
    if (!mounted) return;
    if (outcome == null) {
      setState(() {
        analyzing = false;
        status = _failureMessage(c.openDiscoveryService.lastError ?? '');
      });
      return;
    }
    switch (outcome.kind) {
      case OpenOutcomeKind.person:
        // Nothing is described or kept. The photo is dropped straight away.
        setState(() {
          analyzing = false;
          photo = null;
          identified = null;
          status = 'I only look at things, not people! Can you find an object?';
        });
      case OpenOutcomeKind.blocked:
        setState(() {
          analyzing = false;
          photo = null;
          identified = null;
          status = 'Let’s find something else! Try a different object.';
        });
      case OpenOutcomeKind.unsure:
        final question = OpenDiscoveryRules
            .questions[_random.nextInt(OpenDiscoveryRules.questions.length)];
        setState(() {
          analyzing = false;
          status =
              'Hmm, I can’t quite tell what that is. $question Try a closer photo!';
        });
      case OpenOutcomeKind.catalog:
        _applyResult(
          IdentifiedCatalogItem(
            catalogId: outcome.catalogId!,
            confidence: outcome.confidence,
          ),
        );
      case OpenOutcomeKind.find:
        _applyOpenFind(c, outcome, profile);
    }
  }

  void _applyOpenFind(
    AppController c,
    OpenOutcome find,
    MovementProfile profile,
  ) {
    final name = find.name ?? 'thing';
    final clue = mission.clues[clueIndex];
    if (!find.fitsClue) {
      setState(() {
        analyzing = false;
        status =
            'That’s ${OpenDiscoveryRules.withArticle(name)}! A fun find, but it doesn’t fit this clue. ${clue.prompt}';
      });
      return;
    }
    final options = MovementCatalog.forProfile(profile);
    final movementId =
        find.movementId ?? options[_random.nextInt(options.length)].id;
    c.addDiscovery('mystery-${OpenDiscoveryRules.slug(name)}');
    c.scheduleSave();
    setState(() {
      analyzing = false;
      identified = null;
      _openFind = find;
      _openStage = 0;
      _openStep = MovementCatalog.stepFor(
        movementId,
        profile,
        age: c.profile.age,
      );
      completed++;
      status = '';
    });
  }

  void _nextOpen() {
    final find = _openFind;
    if (find == null) return;
    setState(() {
      if (_openStage == 0) {
        _openStage = find.facts.isEmpty ? 2 : 1;
      } else {
        _openStage = 2;
      }
    });
  }

  /// Checks a result (from a photo or from a picture pick) against the clue.
  void _applyResult(IdentifiedCatalogItem result) {
    final item = ContentCatalog.get(result.catalogId);
    final clue = mission.clues[clueIndex];
    final matches = item != null && _matches(item, clue);
    if (!matches) {
      setState(() {
        analyzing = false;
        identified = result;
        status = item == null
            ? 'That is an interesting discovery, but it does not unlock this clue yet.'
            : '${item.name} is interesting! But Vee thinks the clue is pointing somewhere else. Try another discovery.';
      });
      return;
    }

    setState(() {
      analyzing = false;
      identified = result;
      revealItem = item;
      revealPack = DiscoveryEngine.forItem(item);
      revealStage = 0;
      whatIfChoice = null;
      completed++;
      status = '';
    });
  }

  List<CatalogItem> _pickCandidates() {
    final allowed = ContentCatalog.items
        .where((item) => item.settings.any(mission.allowedSettings.contains))
        .toList();
    final clue = mission.clues[clueIndex];
    final matching = allowed.where((item) => _matches(item, clue)).toList()
      ..shuffle(_random);
    final others = allowed.where((item) => !_matches(item, clue)).toList()
      ..shuffle(_random);
    return <CatalogItem>[...matching.take(2), ...others.take(4)]
      ..shuffle(_random);
  }

  bool _matches(CatalogItem item, SpotClue clue) {
    if (!item.settings.any(mission.allowedSettings.contains)) return false;
    final values = item.properties[clue.property] ?? const <String>[];
    final first =
        values.contains(clue.value) ||
        (clue.value == 'objects' && item.category == 'object');
    if (!first) return false;
    if (clue.secondProperty == null) return true;
    final secondValues =
        item.properties[clue.secondProperty!] ?? const <String>[];
    return secondValues.contains(clue.secondValue) ||
        (clue.secondValue == 'objects' && item.category == 'object');
  }

  Future<void> _nextReveal() async {
    final item = revealItem;
    final pack = revealPack;
    if (item == null || pack == null) return;

    if (revealStage == 0) {
      setState(() => revealStage = 1);
      return;
    }
    if (revealStage == 1) {
      final event = DiscoveryEngine.randomEvent(
        pack.surpriseIds,
        mode: mission.mode,
      );
      setState(() {
        revealStage = 2;
        status = event.message;
      });
      GameAppScope.of(context).addDiscovery('wow-${item.id}-${event.id}');
      return;
    }
    if (revealStage == 2) {
      setState(() => revealStage = 3);
      return;
    }
    await _advanceClue();
  }

  Future<void> _advanceClue() async {
    if (clueIndex < mission.clues.length - 1) {
      setState(() {
        clueIndex++;
        photo = null;
        identified = null;
        revealItem = null;
        revealPack = null;
        revealStage = 0;
        whatIfChoice = null;
        _openFind = null;
        _openStage = 0;
        _openStep = null;
        _pickOptions = null;
        status = 'A NEW CLUE just appeared!';
      });
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_finishStarted) return;
    _finishStarted = true;

    final c = GameAppScope.of(context);
    final item = revealItem;
    final pack = revealPack;
    final open = _openFind;
    final discovery = open != null
        ? 'You discovered ${OpenDiscoveryRules.withArticle(open.name ?? 'something new')}!'
        : item == null || pack == null
        ? 'You solved Vee’s mystery trail.'
        : pack.wowDiscoveries.first;

    try {
      await c.finishActivity(
        activityId: 'spot-${mission.id}',
        completionToken: _completionToken,
        starsEarned: 4,
        discoveryIds: <String>[
          'spot-${mission.id}',
          if (item != null) 'discovery-${item.id}',
        ],
      );
      if (!mounted) return;
      replaceTo(
        context,
        RewardScreen(activity: ActivityType.spot, discovery: discovery),
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save SPOT completion: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _finishStarted = false;
        status = 'Vee could not save that star. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clue = mission.clues[clueIndex];
    final opening = _openFind != null;
    final revealing = opening || (revealItem != null && revealPack != null);
    return WorldShell(
      scene: revealing ? SceneKind.closeup : null,
      stepLabel: 'Spot',
      stepCurrent: clueIndex,
      stepTotal: mission.clues.length,
      left: opening
          ? _openRevealPicture()
          : revealing
          ? _revealPicture()
          : _veeSide(),
      speech: revealing || clueIndex > 0 ? null : mission.opening,
      onRestartMission: () => replaceTo(context, const SpotScreen()),
      onMainMenu: () => replaceTo(context, const AdventureHub()),
      right: opening
          ? _openMoment()
          : revealing
          ? _discoveryMoment()
          : _panel(clue),
    );
  }

  Widget _veeSide() => VeeAvatar(
    pose: analyzing ? VeePose.thinking : VeePose.spot,
    bounce: completed,
  );

  /// The big picture of the thing that was found, with Vee peeking in.
  Widget _revealPicture() {
    final item = revealItem!;
    return LayoutBuilder(
      builder: (context, box) {
        final big = math.min(box.maxWidth * .95, box.maxHeight * .72);
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: const Alignment(0, -.4),
              child: TweenAnimationBuilder<double>(
                key: ValueKey<int>(revealStage),
                tween: Tween<double>(begin: .6, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: ItemIcon(item, size: big),
              ),
            ),
            Align(
              alignment: const Alignment(-.9, 1),
              child: SizedBox(
                height: box.maxHeight * .46,
                child: VeeAvatar(
                  pose: revealStage == 2 ? VeePose.surprised : VeePose.spot,
                  bounce: completed + revealStage,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The child's own photo, framed, with Vee peeking in. It never leaves the
  /// device from here on; it is dropped when the clue moves on.
  Widget _openRevealPicture() {
    final bytes = photo;
    return LayoutBuilder(
      builder: (context, box) {
        final size = math.min(box.maxWidth * .92, box.maxHeight * .7);
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: const Alignment(0, -.4),
              child: TweenAnimationBuilder<double>(
                key: ValueKey<int>(_openStage),
                tween: Tween<double>(begin: .6, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: size,
                  height: size * .8,
                  decoration: BoxDecoration(
                    color: VeeTokens.cardWhite,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: VeeTokens.cardWhite, width: 6),
                    boxShadow: const [
                      BoxShadow(
                        color: VeeTokens.shadow,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: bytes == null
                        ? const Icon(
                            Icons.search_rounded,
                            size: 80,
                            color: VeeTokens.teal,
                          )
                        : Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-.9, 1),
              child: SizedBox(
                height: box.maxHeight * .46,
                child: VeeAvatar(
                  pose: _openStage == 2 ? VeePose.celebration : VeePose.spot,
                  bounce: completed + _openStage,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _openMoment() {
    final find = _openFind!;
    final name = find.name ?? 'thing';
    final facts = find.facts;
    final noun = OpenDiscoveryRules.withArticle(name);

    final Widget tag;
    final String heading;
    String? body;
    final Widget action;
    Widget? footer;

    switch (_openStage) {
      case 0:
        tag = const PillTag.coral('You found it!');
        heading = 'Yes! ${OpenDiscoveryRules.sentenceCase(noun)}!';
        body = facts.isEmpty
            ? 'It fits the clue. Now let’s move like a champion!'
            : 'It fits the clue. Want to learn something about it?';
        action = _button(
          facts.isEmpty ? 'Let’s move!' : 'Tell me more!',
          _nextOpen,
          VeeTokens.teal,
          icon: Icons.arrow_forward_rounded,
        );
      case 1:
        tag = const PillTag.coral('Look closer');
        heading = facts.first;
        body = facts.length > 1 ? facts[1] : null;
        action = _button(
          'Make something happen!',
          _nextOpen,
          VeeTokens.teal,
          icon: Icons.arrow_forward_rounded,
        );
        footer = const SceneCaption('A grown-up can check this fact with you.');
      default:
        tag = const PillTag.coral('Your move!');
        heading = 'Time to move!';
        action = MovementChallenge(
          key: ValueKey<String>('open-move-$clueIndex'),
          step: _openStep!,
          onComplete: () {
            Future<void>.delayed(const Duration(milliseconds: 700), () {
              if (mounted && _openFind != null) _advanceClue();
            });
          },
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey<int>(_openStage),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tag,
          const SizedBox(height: 14),
          Text(
            heading,
            style: const TextStyle(
              fontSize: 44,
              height: 1.04,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(
                fontSize: 26,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: VeeTokens.textOnLight,
              ),
            ),
          ],
          if (footer != null) ...[const SizedBox(height: 10), footer],
          const SizedBox(height: 20),
          action,
        ],
      ),
    );
  }

  /// Up to two real examples of what the clue is asking for.
  List<CatalogItem> _examplesFor(SpotClue clue) => ContentCatalog.items
      .where(
        (item) =>
            item.settings.any(mission.allowedSettings.contains) &&
            _matches(item, clue),
      )
      .take(2)
      .toList();

  Widget _panel(SpotClue clue) {
    final examples = _examplesFor(clue);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PillTag(clueIndex == 0 ? 'Your first clue' : 'Your next clue'),
        const SizedBox(height: 14),
        Text(
          clue.prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 46,
            height: 1.04,
            fontWeight: FontWeight.w900,
            color: VeeTokens.textOnLight,
          ),
        ),
        const SizedBox(height: 14),
        if (photo != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.memory(
              photo!,
              width: 240,
              height: 160,
              fit: BoxFit.cover,
            ),
          )
        else if (examples.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SparkleDashes(size: 36, rotation: -.3),
              const SizedBox(width: 8),
              for (final item in examples) ...[
                ItemIcon(item, size: 92),
                const SizedBox(width: 10),
              ],
              Transform.scale(
                scaleX: -1,
                child: const SparkleDashes(size: 36, rotation: -.3),
              ),
            ],
          ),
        if (photo == null)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Look around you.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: VeeTokens.textOnLight,
              ),
            ),
          ),
        if (identified != null) ...[
          const SizedBox(height: 8),
          Text(
            ContentCatalog.get(identified!.catalogId)?.name ??
                identified!.catalogId,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
          ),
        ],
        if (status.isNotEmpty) ...[
          const SizedBox(height: 10),
          _StatusPill(text: status),
        ],
        if (analyzing)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: BouncingDots(),
          ),
        const SizedBox(height: 16),
        if (_pickOptions != null)
          _pickPanel()
        else if (photo == null)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _button(
                'Take a photo',
                () => _pick(ImageSource.camera),
                VeeTokens.teal,
                icon: Icons.photo_camera_rounded,
              ),
              const SizedBox(height: 12),
              _button(
                'Choose a photo',
                () => _pick(ImageSource.gallery),
                VeeTokens.yellow,
                icon: Icons.image_outlined,
              ),
              TextButton(
                onPressed: () => setState(() {
                  _pickOptions = _pickCandidates();
                  status = '';
                }),
                child: const Text(
                  'No camera? Pick from pictures',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: VeeTokens.teal,
                    decoration: TextDecoration.underline,
                    decorationColor: VeeTokens.teal,
                  ),
                ),
              ),
            ],
          )
        else
          _button(
            analyzing ? 'Vee is looking…' : 'Reveal my discovery',
            analyzing ? null : _identify,
            VeeTokens.teal,
            icon: Icons.auto_awesome_rounded,
          ),
        if (photo != null && !analyzing)
          TextButton(
            onPressed: () => setState(() {
              photo = null;
              identified = null;
              status = '';
            }),
            child: const Text(
              'Try a different photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: VeeTokens.teal,
                decoration: TextDecoration.underline,
                decorationColor: VeeTokens.teal,
              ),
            ),
          ),
        const SizedBox(height: 6),
        const SceneCaption('Stay with your grown-up.'),
      ],
    );
  }

  Widget _pickPanel() {
    final options = _pickOptions ?? const <CatalogItem>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: options
              .map(
                (item) => JuicyTap(
                  onTap: () => _applyResult(
                    IdentifiedCatalogItem(catalogId: item.id, confidence: 1),
                  ),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                    decoration: BoxDecoration(
                      color: VeeTokens.cardWhite,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: VeeTokens.shadow,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ItemIcon(item, size: 56),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: VeeTokens.textOnLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        TextButton(
          onPressed: () => setState(() {
            _pickOptions = null;
            status = '';
          }),
          child: const Text(
            'Use a photo instead',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: VeeTokens.teal,
              decoration: TextDecoration.underline,
              decorationColor: VeeTokens.teal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _discoveryMoment() {
    final item = revealItem!;
    final pack = revealPack!;
    final event = revealStage >= 2
        ? DiscoveryEngine.randomEvent(pack.surpriseIds, mode: mission.mode)
        : null;
    final lastClue = clueIndex == mission.clues.length - 1;

    Widget tag;
    String heading;
    String? body;
    String button;
    IconData buttonIcon = Icons.arrow_forward_rounded;

    switch (revealStage) {
      case 0:
        tag = const PillTag.coral('You found it!');
        heading = 'Yes! A ${item.name}!';
        body = 'It matches the clue. But Vee noticed something unusual…';
        button = 'What did Vee notice?';
        break;
      case 1:
        tag = const PillTag.coral('Look closer');
        heading =
            pack.wowDiscoveries[(clueIndex + completed) %
                pack.wowDiscoveries.length];
        body = null;
        button = 'Make something happen!';
        break;
      case 2:
        tag = const PillTag.coral('Surprise!');
        heading = event!.title;
        body = '${event.message}\n\n${pack.reaction}';
        button = 'One more mystery…';
        break;
      default:
        tag = const PillTag(
          'What if…?',
          color: VeeTokens.yellow,
          showLeaf: false,
        );
        heading = pack.whatIfPrompts.first;
        body = null;
        button = lastClue ? 'Finish the mystery!' : 'Next clue';
        if (whatIfChoice != null) {
          heading = whatIfChoice!;
          body = pack.whatIfAnswer;
        }
    }

    final needsChoice = revealStage == 3 && whatIfChoice == null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey('$revealStage-$whatIfChoice'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              tag,
              const Positioned(
                right: -50,
                top: -26,
                child: SparkleDashes(size: 44, rotation: .2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            heading,
            style: const TextStyle(
              fontSize: 46,
              height: 1.04,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(
                fontSize: 26,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: VeeTokens.textOnLight,
              ),
            ),
          ],
          if (needsChoice) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: pack.whatIfChoices.map(_choiceChip).toList(),
            ),
          ] else ...[
            const SizedBox(height: 22),
            _button(button, _nextReveal, VeeTokens.teal, icon: buttonIcon),
          ],
        ],
      ),
    );
  }

  Widget _choiceChip(String choice) => VeeButton(
    outlined: true,
    minWidth: 120,
    fontSize: 20,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
    onPressed: () => setState(() => whatIfChoice = choice),
    child: Text(choice),
  );

  /// Teal pill for the main action; any other colour becomes the outlined
  /// second-choice pill.
  Widget _button(
    String label,
    VoidCallback? onTap,
    Color color, {
    IconData? icon,
  }) => VeeButton(
    onPressed: onTap,
    outlined: color != VeeTokens.teal,
    icon: icon,
    minWidth: 300,
    child: Text(label),
  );
}

class _StatusPill extends StatelessWidget {
  final String text;
  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: VeeTokens.mint,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: VeeTokens.textOnLight,
      ),
    ),
  );
}
