import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../app/design_tokens.dart';
import '../../models/activity.dart';
import '../../models/content_catalog.dart';
import '../../models/environment_mode.dart';
import '../../services/ai/surprise_selector.dart';
import '../../services/discovery_engine.dart';
import '../../services/activity_selection/movement_profile.dart';
import '../../widgets/world_shell.dart';
import '../../widgets/game_options.dart';
import '../rewards/reward_screen.dart';
import '../hub/adventure_hub.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  ExploreSetting? setting;
  bool showingSpecialEvents = false;
  final Set<String> discovered = {};
  final Set<String> reacted = {};
  int phase = 0;
  int chainStep = 0;
  int interactionCount = 0;
  bool challengeComplete = false;
  bool hiddenAreaOpen = false;
  String? selectedItem;
  String status = '';
  String? surprise;
  final Random random = Random();
  bool _finishStarted = false;
  final String _completionToken =
      'explore-${DateTime.now().microsecondsSinceEpoch}';

  MovementProfile get _movementProfile =>
      movementProfileFor(GameAppScope.of(context).profile.movementPreference);

  int get _targetInteractions => _movementProfile.exploreInteractions;
  int get _discoveryGate => _movementProfile.exploreDiscoveryGate;

  EnvironmentMode get _mode => GameAppScope.of(context).profile.environmentMode;

  @override
  Widget build(BuildContext context) {
    if (setting == null) return _settings();
    return WorldShell(
      left: Image.asset('assets/vee/vee_happy_idle.webp', fit: BoxFit.contain),
      speech: _speech(),
      eyebrow: 'EXPLORE • ${interactionCount}/$_targetInteractions',
      onRestartMission: () => replaceTo(context, const ExploreScreen()),
      onMainMenu: () => replaceTo(context, const AdventureHub()),
      right: _world(),
    );
  }

  Widget _settings() {
    final worlds = showingSpecialEvents
        ? ContentCatalog.specialEventsForMode(_mode)
        : ContentCatalog.settingsForMode(_mode);

    return Scaffold(
      backgroundColor: VeeTokens.cream,
      body: SafeArea(
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 920,
              height: 690,
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GameOptionsButton(
                      onRestart: () => replaceTo(context, const ExploreScreen()),
                      onMainMenu: () => replaceTo(context, const AdventureHub()),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 18),
                      Text(
                        showingSpecialEvents
                            ? '${_mode.emoji} Special Events'
                            : '${_mode.emoji} Where do you want to explore?',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: VeeTokens.textOnLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        showingSpecialEvents
                            ? (_mode == EnvironmentMode.indoor
                                ? 'Step into a special indoor world.'
                                : 'Step into a special outdoor world.')
                            : (_mode == EnvironmentMode.indoor
                                ? 'Choose a room or everyday indoor world.'
                                : 'Choose an outdoor place and discover what is around you.'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: VeeTokens.textSecondaryOnLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 12,
                          children: worlds.map((s) {
                            return GestureDetector(
                              onTap: () => _selectSetting(s),
                              child: Container(
                                width: 200,
                                height: showingSpecialEvents ? 126 : 132,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: VeeTokens.white,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: VeeTokens.shadow,
                                      blurRadius: 14,
                                      offset: Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(s.emoji, style: const TextStyle(fontSize: 36)),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: VeeTokens.textOnLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: VeeTokens.textSecondaryOnLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!showingSpecialEvents)
                        GestureDetector(
                          onTap: () => setState(() => showingSpecialEvents = true),
                          child: Container(
                            width: 500,
                            height: 70,
                            decoration: BoxDecoration(
                              color: VeeTokens.yellow,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: const [
                                BoxShadow(
                                  color: VeeTokens.shadow,
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 28)),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'SPECIAL EVENTS',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: VeeTokens.textOnLight,
                                      ),
                                    ),
                                    Text(
                                      _mode == EnvironmentMode.indoor
                                          ? 'Birthdays, holiday stays & cozy celebrations'
                                          : 'Indian festivals, journeys & travel worlds',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: VeeTokens.textSecondaryOnLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: () => setState(() => showingSpecialEvents = false),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back to regular worlds'),
                          style: TextButton.styleFrom(
                            foregroundColor: VeeTokens.teal,
                            textStyle: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectSetting(ExploreSetting selected) {
    setState(() {
      setting = selected;
      showingSpecialEvents = false;
      interactionCount = 0;
      chainStep = 0;
      discovered.clear();
      reacted.clear();
      challengeComplete = false;
      hiddenAreaOpen = false;
      status = '';
      surprise = null;
    });
  }

  String _speech() {
    if (hiddenAreaOpen) return 'You changed the world enough to reveal a secret place!';
    if (challengeComplete) return 'The setting reacted to your choices. What else can we discover?';
    if (chainStep > 0) return 'Follow the clue your last discovery created…';
    return 'You choose what to touch. I wonder what will happen!';
  }

  Widget _world() {
    final allItems = ContentCatalog.forSetting(setting!.id);
    final itemLimit = switch (_movementProfile) {
      MovementProfile.gentle => 4,
      MovementProfile.steady => 6,
      MovementProfile.energetic => 8,
    };
    final items = allItems.take(itemLimit).toList();
    return Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Text('${setting!.emoji} ${setting!.name}', style: Theme.of(context).textTheme.headlineMedium)),
          TextButton(
            onPressed: () => setState(() {
              setting = null;
              discovered.clear();
              reacted.clear();
              challengeComplete = false;
              hiddenAreaOpen = false;
              chainStep = 0;
              interactionCount = 0;
              status = '';
              surprise = null;
            }),
            child: const Text('Choose another place'),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Touch something. Every discovery can lead somewhere new.', style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: items.map(_itemCard).toList()),
        const SizedBox(height: 18),
        if (discovered.length >= _discoveryGate && !challengeComplete) _dragChallenge(),
        if (challengeComplete && !hiddenAreaOpen) _hiddenReveal(),
        if (surprise != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('✨ ${surprise!.replaceAll('_', ' ')}',
          style: const TextStyle(fontWeight: FontWeight.w900, color: VeeTokens.teal))),
        if (hiddenAreaOpen) _secretArea(),
        if (status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(status, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: VeeTokens.textOnLight))),
        const SizedBox(height: 16),
        if (interactionCount >= _targetInteractions && hiddenAreaOpen) _finishButton(),
    ]);
  }

  Widget _itemCard(CatalogItem item) {
    final isDiscovered = discovered.contains(item.id);
    final active = selectedItem == item.id;
    return GestureDetector(
      onTap: () => _discover(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 145, height: 112,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: active ? VeeTokens.yellow : VeeTokens.white, borderRadius: BorderRadius.circular(26),
        border: Border.all(color: isDiscovered ? VeeTokens.teal : Colors.transparent, width: 2), boxShadow: const [BoxShadow(color: VeeTokens.shadow,
          blurRadius: 10, offset: Offset(0, 5))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(item.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 4),
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, color: VeeTokens.textOnLight)),
          if (isDiscovered) const Text('discovered ✦', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: VeeTokens.teal)),
        ]),
      ),
    );
  }

  void _discover(CatalogItem item) {
    final c = GameAppScope.of(context);
    final wasNew = discovered.add(item.id);
    interactionCount++;
    selectedItem = item.id;
    final pack = DiscoveryEngine.forItem(item);
    final wow = pack.wowDiscoveries[(interactionCount - 1) % pack.wowDiscoveries.length];
    final reaction = item.interactions.isEmpty ? 'glow' : item.interactions[random.nextInt(item.interactions.length)];
    reacted.add(item.id);
    chainStep++;
    if (wasNew) c.addDiscovery('item-${item.id}');
    setState(() {
      status = '${item.emoji} ${item.name}\n\n$wow';
      if (chainStep == 2) status = '$status\n\n✨ Something connected to your last discovery…';
    });
    if (chainStep >= 2 && reaction == 'follow') {
      final event = DiscoveryEngine.randomEvent(pack.surpriseIds, mode: _mode);
      setState(() => status = '$status\n\n${event.emoji} ${event.message}');
      c.addDiscovery('explore-surprise-${item.id}-${event.id}');
    }
    if (interactionCount >= 6 && !challengeComplete) {
      // The challenge becomes available after enough free exploration.
    }
    c.save();
  }

  Widget _dragChallenge() {
    final allItems = ContentCatalog.forSetting(setting!.id);
    final filtered = allItems.where((e) => e.category == 'plant' || e.category == 'food').toList();
    final items = (filtered.isNotEmpty ? filtered : allItems).take(3).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final target = items.first;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: VeeTokens.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: VeeTokens.shadow,
        blurRadius: 12, offset: Offset(0, 6))]),
      child: Column(children: [
        const Text('✨ Something needs your help!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
          color: VeeTokens.textOnLight)),
        const SizedBox(height: 6),
        Text('Drag the right discovery to ${target.name}.', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700,
          color: VeeTokens.textSecondaryOnLight)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ...items.map((item) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Draggable<String>(
            data: item.id,
            feedback: Material(color: Colors.transparent, child: Text(item.emoji, style: const TextStyle(fontSize: 52))),
            childWhenDragging: Opacity(opacity: .25, child: Text(item.emoji, style: const TextStyle(fontSize: 42))),
            child: Text(item.emoji, style: const TextStyle(fontSize: 42)),
          ))),
          const SizedBox(width: 18),
          DragTarget<String>(
            onAcceptWithDetails: (details) {
              if (details.data == target.id) {
                setState(() { challengeComplete = true; status = 'Perfect! The world changed because you helped.'; });
                _chooseSurprise();
              } else {
                setState(() => status = 'That one belongs somewhere else. Try another discovery.');
              }
            },
            builder: (_, __, ___) => Container(
              width: 92,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: VeeTokens.leaf.withOpacity(.25),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                '${target.emoji}\n${target.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.textOnLight,
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _chooseSurprise() async {
    final c = GameAppScope.of(context);
    final items = ContentCatalog.forSetting(setting?.id ?? '');
    final source = items.isEmpty ? ContentCatalog.items.first : items.first;
    final pack = DiscoveryEngine.forItem(source);
    final allowed = pack.surpriseIds.map((id) {
      final event = DiscoveryEngine.event(id, mode: _mode);
      return SurpriseChoice(event.id, '${event.emoji} ${event.message}');
    }).toList(growable: false);
    final choice = await c.surpriseSelector.choose(
      allowed: allowed,
      context: setting?.name ?? 'explore',
    );
    if (!mounted) return;
    final event = DiscoveryEngine.event(choice.id, mode: _mode);
    setState(() {
      surprise = choice.id;
      status = '${event.emoji} ${event.message} Tap the glowing discovery to continue.';
    });
  }

  Widget _hiddenReveal() => GestureDetector(
    onTap: () => setState(() { hiddenAreaOpen = true; status = 'A hidden area opened! There is one more little world to discover.'; }),
    child: Container(margin: const EdgeInsets.only(top: 14), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: VeeTokens.yellow,
    borderRadius: BorderRadius.circular(28)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('🌿',
    style: TextStyle(fontSize: 34)), SizedBox(width: 10), Text('Something is moving behind here…', style: TextStyle(fontWeight: FontWeight.w900,
      color: VeeTokens.textOnLight))])),
  );

  Widget _secretArea() {
    final item = ContentCatalog.forSetting(setting!.id).last;
    return Container(margin: const EdgeInsets.only(top: 14), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: VeeTokens.cream,
      borderRadius: BorderRadius.circular(28)), child: Column(children: [
      Text(setting!.hiddenAreas.first, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VeeTokens.teal)),
      const SizedBox(height: 6),
      Text('✨ Secret discovery', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      Text('${item.emoji} ${item.name} was waiting here!', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      Text(DiscoveryEngine.forItem(item).wowDiscoveries.last, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
    ]));
  }

  Widget _finishButton() => GestureDetector(onTap: _finish, child: Container(margin: const EdgeInsets.only(top: 16),
  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16), decoration: BoxDecoration(color: VeeTokens.yellow,
  borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: VeeTokens.shadow, blurRadius: 12,
  offset: Offset(0, 6))]), child: const Text('✨ Finish this discovery', style: TextStyle(fontWeight: FontWeight.w900,
  color: VeeTokens.textOnLight))));

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
        starsEarned: 4,
        discoveryIds: <String>['explore-${selectedSetting.id}'],
      );
      if (!mounted) return;
      replaceTo(
        context,
        RewardScreen(
          activity: ActivityType.explore,
          discovery: 'You explored ${selectedSetting.name} and changed the world.',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save EXPLORE completion: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _finishStarted = false;
        status = 'Vee could not save that star. Please try again.';
      });
    }
  }

}
