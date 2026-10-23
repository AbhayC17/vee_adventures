import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../widgets/adaptive_text.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../app/design_tokens.dart';
import '../../models/activity.dart';
import '../../models/content_catalog.dart';
import '../../models/environment_mode.dart';
import '../../services/activity_selection/movement_profile.dart';
import '../../services/discovery_engine.dart';
import '../../services/spot/discovery_analyzer.dart';
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
    allowedSettings: ['kitchen', 'bedroom', 'bathroom', 'hall', 'dining', 'library', 'shop'],
    clues: [
      SpotClue(title: 'SHAPE CLUE', prompt: 'Find something ROUND indoors.', property: 'shapes', value: 'round'),
      SpotClue(title: 'TEXTURE CLUE', prompt: 'Find something SMOOTH.', property: 'textures', value: 'smooth'),
      SpotClue(title: 'SECRET OBJECT', prompt: 'Find an everyday OBJECT that could hide a story.', property: 'groups', value: 'objects'),
    ],
  ),
  SpotMission(
    id: 'kitchen_hunt',
    title: 'The Kitchen Mystery',
    opening: 'Vee heard a tiny clink in the kitchen. Can you find the object that fits the clues?',
    mode: EnvironmentMode.indoor,
    allowedSettings: ['kitchen', 'dining', 'shop'],
    clues: [
      SpotClue(title: 'FOOD CLUE', prompt: 'Find something that can be FOOD.', property: 'groups', value: 'food'),
      SpotClue(title: 'COLOR CLUE', prompt: 'Find something YELLOW.', property: 'colors', value: 'yellow'),
      SpotClue(title: 'SHAPE CLUE', prompt: 'Find something ROUND.', property: 'shapes', value: 'round'),
    ],
  ),
  SpotMission(
    id: 'outdoor_nature_trail',
    title: 'Vee’s Outdoor Mystery Trail',
    opening: 'Something in the outdoor world has left a clue. Use your explorer eyes!',
    mode: EnvironmentMode.outdoor,
    allowedSettings: ['garden', 'park', 'forest', 'beach', 'road'],
    clues: [
      SpotClue(title: 'COLOR CLUE', prompt: 'Find something GREEN outside.', property: 'colors', value: 'green'),
      SpotClue(title: 'LIVING WORLD', prompt: 'Find something from the world of PLANTS.', property: 'groups', value: 'plants'),
      SpotClue(title: 'SHAPE CLUE', prompt: 'Find something ROUND outside.', property: 'shapes', value: 'round'),
    ],
  ),
  SpotMission(
    id: 'garden_detective',
    title: 'The Garden Secret',
    opening: 'Flowers, leaves and tiny visitors are hiding a chain of clues. Look closely!',
    mode: EnvironmentMode.outdoor,
    allowedSettings: ['garden', 'park', 'forest'],
    clues: [
      SpotClue(title: 'PLANT CLUE', prompt: 'Find a PLANT.', property: 'groups', value: 'plants'),
      SpotClue(title: 'GREEN CLUE', prompt: 'Find something GREEN.', property: 'colors', value: 'green'),
      SpotClue(title: 'NATURE CLUE', prompt: 'Find another thing from NATURE.', property: 'groups', value: 'plants'),
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

  static SpotMission _drawMission(List<SpotMission> pool, EnvironmentMode mode) {
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
  late SpotMission mission;
  String status = '';
  CatalogItem? revealItem;
  DiscoveryPack? revealPack;
  int revealStage = 0;
  String? whatIfChoice;
  bool _finishStarted = false;
  final String _completionToken =
      'spot-${DateTime.now().microsecondsSinceEpoch}';

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
        prompt: '${original.prompt.replaceFirst('.', '')} and make sure it is ROUND.',
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
        maxWidth: 1024,
        imageQuality: 75,
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
        setState(() => status = 'Vee could not open that discovery. Let’s try another way.');
      }
    }
  }

  Future<void> _identify() async {
    if (photo == null || analyzing) return;
    setState(() {
      analyzing = true;
      status = 'Vee is looking VERY closely… 🔎';
    });
    final c = GameAppScope.of(context);
    final allowed = ContentCatalog.items
        .where((item) => item.settings.any(mission.allowedSettings.contains))
        .map((e) => e.id)
        .toList();
    final result = await c.spotAnalyzer.identify(
      bytes: photo!.toList(),
      allowedCatalogIds: allowed,
    );
    if (!mounted) return;
    if (result == null) {
      final failure = c.spotAnalyzer.lastError ?? '';
      final message = failure.contains('MODEL_UNCERTAIN')
          ? 'Hmm… Vee needs a clearer look. Try a closer photo!'
          : failure.contains('MISSING_GROQ_API_KEY')
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
      setState(() {
        analyzing = false;
        status = message;
      });
      return;
    }
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
      revealPack = DiscoveryEngine.forItem(item!);
      revealStage = 0;
      whatIfChoice = null;
      completed++;
      status = '';
    });
  }

  bool _matches(CatalogItem item, SpotClue clue) {
    if (!item.settings.any(mission.allowedSettings.contains)) return false;
    final values = item.properties[clue.property] ?? const <String>[];
    final first = values.contains(clue.value) ||
        (clue.value == 'objects' && item.category == 'object');
    if (!first) return false;
    if (clue.secondProperty == null) return true;
    final secondValues = item.properties[clue.secondProperty!] ?? const <String>[];
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
      final event = DiscoveryEngine.randomEvent(pack.surpriseIds, mode: mission.mode);
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
        status = 'A NEW CLUE just appeared! ✨';
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
    final discovery = item == null || pack == null
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
    return WorldShell(
      left: Image.asset('assets/vee/vee_encourage.webp', fit: BoxFit.contain),
      speech: revealItem == null
          ? (clueIndex == 0 ? mission.opening : 'The next clue is ready. Keep those detective eyes switched on!')
          : 'You found ${revealItem!.name}! But that is only the beginning…',
      eyebrow: '${mission.mode.emoji} SPOT • ${completed}/${mission.clues.length}',
      onRestartMission: () => replaceTo(context, const SpotScreen()),
      onMainMenu: () => replaceTo(context, const AdventureHub()),
      right: _panel(clue),
    );
  }

  Widget _panel(SpotClue clue) {
    if (revealItem != null && revealPack != null) return _discoveryMoment();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(mission.title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(clue.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: VeeTokens.teal, letterSpacing: 1.4)),
        const SizedBox(height: 8),
        Text(clue.prompt, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        if (photo != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.memory(photo!, width: 220, height: 145, fit: BoxFit.cover),
          ),
        if (identified != null) ...[
          const SizedBox(height: 8),
          Text(
            ContentCatalog.get(identified!.catalogId)?.name ?? identified!.catalogId,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
        ],
        if (status.isNotEmpty) ...[
          const SizedBox(height: 10),
          _StatusPill(text: status),
        ],
        const SizedBox(height: 14),
        if (photo == null)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _button('📷 Find with Camera', () => _pick(ImageSource.camera), VeeTokens.teal),
              _button('🖼️ Choose a Photo', () => _pick(ImageSource.gallery), VeeTokens.yellow),
            ],
          )
        else
          _button(analyzing ? '🔎 Vee is looking…' : '✨ Reveal my discovery', _identify, VeeTokens.yellow),
        if (photo != null && !analyzing)
          TextButton(
            onPressed: () => setState(() {
              photo = null;
              identified = null;
              status = '';
            }),
            child: const Text('Try a different discovery'),
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

    String title;
    String body;
    String emoji;
    String button;

    switch (revealStage) {
      case 0:
        title = '🎉 YOU FOUND IT!';
        body = '${item.emoji} ${item.name} matches the clue. But Vee noticed something unusual…';
        emoji = item.emoji;
        button = 'What did Vee notice?';
        break;
      case 1:
        title = '🔎 LOOK CLOSER';
        body = pack.wowDiscoveries[(clueIndex + completed) % pack.wowDiscoveries.length];
        emoji = '👀';
        button = 'Make something happen!';
        break;
      case 2:
        title = event!.title;
        body = '${event.message}\n\n${pack.reaction}';
        emoji = event.emoji;
        button = 'One more mystery…';
        break;
      default:
        title = '🤔 WHAT DO YOU THINK?';
        body = pack.whatIfPrompts.first;
        emoji = '💭';
        button = 'Reveal the answer';
    }

    if (revealStage == 3 && whatIfChoice != null) {
      body = '$whatIfChoice\n\n${pack.whatIfAnswer}';
      button = clueIndex == mission.clues.length - 1 ? 'Finish the mystery!' : 'Find the next clue!';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('$revealStage-$whatIfChoice'),
        constraints: const BoxConstraints(maxWidth: 610),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: VeeTokens.cream,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: VeeTokens.shadow, blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 350),
              child: Text(emoji, style: const TextStyle(fontSize: 54)),
            ),
            const SizedBox(height: 7),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight)),
            const SizedBox(height: 9),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.3, fontWeight: FontWeight.w700,
              color: VeeTokens.textSecondaryOnLight)),
            if (revealStage == 3 && whatIfChoice == null) ...[
              const SizedBox(height: 13),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: pack.whatIfChoices.map((choice) => _choiceChip(choice)).toList(),
              ),
            ],
            const SizedBox(height: 15),
            if (revealStage != 3 || whatIfChoice != null)
              _button(button, _nextReveal, VeeTokens.yellow),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip(String choice) => GestureDetector(
        onTap: () => setState(() => whatIfChoice = choice),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(color: VeeTokens.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: VeeTokens.teal.withOpacity(.25),
            width: 2)),
          child: Text(choice, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800,
            color: VeeTokens.textOnLight)),
        ),
      );

  Widget _button(String label, VoidCallback onTap, Color color) => GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 190, maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: VeeTokens.shadow,
            blurRadius: 10, offset: Offset(0, 5))]),
          alignment: Alignment.center,
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: VeeTextContrast.foregroundFor(color))),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  final String text;
  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: VeeTokens.white.withOpacity(.88), borderRadius: BorderRadius.circular(18)),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: VeeTokens.textOnLight)),
      );
}
