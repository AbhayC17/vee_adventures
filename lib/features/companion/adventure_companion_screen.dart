import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/design_tokens.dart';
import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../widgets/primary_button.dart';
import '../explore/explore_screen.dart';
import '../hub/adventure_hub.dart';
import '../movement/movement_mission.dart';
import '../play/play_screen.dart';
import '../spot/spot_screen.dart';

class AdventureCompanionScreen extends StatefulWidget {
  const AdventureCompanionScreen({super.key});

  @override
  State<AdventureCompanionScreen> createState() =>
      _AdventureCompanionScreenState();
}

class _AdventureCompanionScreenState extends State<AdventureCompanionScreen> {
  int _tab = 0;
  bool _parentUnlocked = false;
  bool _storyLoading = false;
  String? _storyTitle;
  String? _storyText;
  String? _storyMovement;
  String? _storyFact;
  final TextEditingController _answerController = TextEditingController();
  // A fresh sum each visit, so the grown-up check cannot be memorised.
  late final int _leftNumber;
  late final int _rightNumber;
  String? _parentError;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _leftNumber = 6 + random.nextInt(4);
    _rightNumber = 4 + random.nextInt(5);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _makeStory(AppController c) async {
    if (_storyLoading) return;
    setState(() => _storyLoading = true);
    final discoveries = c.discoveries;
    final seed = discoveries.isNotEmpty ? discoveries.last : 'a tiny garden';
    final fallback = <String, String>{
      'title': 'Vee and the Little Wonder',
      'story':
          'Vee found $seed on the adventure path. A tiny sparkle appeared. “Let’s look closely, move gently, and see what we can learn!”',
      'movement': 'reach',
      'fact': 'Every small discovery can lead to a new question.',
    };
    try {
      final result = await c.aiProvider.generateJson(
        systemPrompt: 'You create safe, short stories for preschool children aged 2–6. Return JSON only with keys title, story, movement, fact. Use only movement values: reach, clap, march, squat, twist, balance, jump. No danger, medical advice, personal data, links, or requests for a child to leave adult supervision. Story max 450 characters, title max 60, fact max 140. Keep it warm and playful.',
        userPrompt:
            'Write one tiny interactive adventure starring Vee the friendly tiger. Recent discovery: $seed. Environment: ${c.profile.environmentMode.name}. Return one story and one simple movement.',
      );
      if (result != null) {
        final movement = (result['movement'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        const allowed = {
          'reach',
          'clap',
          'march',
          'squat',
          'twist',
          'balance',
          'jump',
        };
        final title = (result['title'] ?? '').toString().trim();
        final story = (result['story'] ?? '').toString().trim();
        final fact = (result['fact'] ?? '').toString().trim();
        if (title.isNotEmpty &&
            story.isNotEmpty &&
            title.length <= 60 &&
            story.length <= 450 &&
            allowed.contains(movement)) {
          fallback['title'] = title;
          fallback['story'] = story;
          fallback['movement'] = movement;
          if (fact.isNotEmpty && fact.length <= 140) fallback['fact'] = fact;
        }
      }
    } catch (_) {
      // Curated offline story below is always available if the network or AI fails.
    }
    if (!mounted) return;
    setState(() {
      _storyTitle = fallback['title'];
      _storyText = fallback['story'];
      _storyMovement = fallback['movement'];
      _storyFact = fallback['fact'];
      _storyLoading = false;
    });
    c.addDiscovery('story-${DateTime.now().millisecondsSinceEpoch}');
  }

  void _unlockParent() {
    final answer = int.tryParse(_answerController.text.trim());
    if (answer == _leftNumber + _rightNumber) {
      setState(() {
        _parentUnlocked = true;
        _parentError = null;
      });
    } else {
      setState(
        () => _parentError =
            'That answer did not match. Try again with your grown-up.',
      );
    }
  }

  String _prettyId(String id) {
    final cleaned = id
        .replaceFirst(RegExp(r'^(spot-|explore-|play-|item-|wow-|story-)'), '')
        .replaceAll(RegExp(r'[-_]\d+'), '')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .trim();
    if (cleaned.isEmpty) return 'A little mystery';
    return cleaned
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final c = GameAppScope.of(context);
    return Scaffold(
      backgroundColor: VeeTokens.cream,
      appBar: AppBar(
        backgroundColor: VeeTokens.cream,
        foregroundColor: VeeTokens.ink,
        title: const Text(
          'Vee’s Adventure World',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          tooltip: 'Back to hub',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => replaceTo(context, const AdventureHub()),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  _tabButton(0, Icons.map_rounded, 'My World'),
                  const SizedBox(width: 8),
                  _tabButton(1, Icons.auto_stories_rounded, 'Journal'),
                  const SizedBox(width: 8),
                  _tabButton(2, Icons.family_restroom_rounded, 'Grown-ups'),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (_tab) {
                  0 => _worldTab(c),
                  1 => _journalTab(c),
                  _ => _parentTab(c),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final selected = _tab == index;
    return Expanded(
      child: Material(
        color: selected ? VeeTokens.teal : VeeTokens.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _tab = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : VeeTokens.ink,
                  size: 23,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : VeeTokens.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _worldTab(AppController c) {
    final worlds = [
      (
        'starter_garden',
        '🌱',
        'Starter Garden',
        'Every adventure begins with a tiny wonder.',
      ),
      (
        'butterfly_meadow',
        '🦋',
        'Butterfly Meadow',
        'A meadow full of colours and curious creatures.',
      ),
      (
        'curiosity_cave',
        '💎',
        'Curiosity Cave',
        'A cosy place for clues and little puzzles.',
      ),
      (
        'rainbow_river',
        '🌈',
        'Rainbow River',
        'Follow the colours to your next surprise.',
      ),
    ];
    final missions = [
      (
        'SPOT',
        'Find something and identify it',
        Icons.camera_alt_rounded,
        VeeTokens.peach,
        const SpotScreen(),
      ),
      (
        'EXPLORE',
        'Explore a place and collect clues',
        Icons.explore_rounded,
        VeeTokens.leaf,
        const ExploreScreen(),
      ),
      (
        'PLAY',
        'Follow a story and solve a puzzle',
        Icons.auto_awesome_rounded,
        VeeTokens.sky,
        const PlayScreen(),
      ),
      (
        'MOVE',
        'Try a friendly movement challenge',
        Icons.directions_run_rounded,
        VeeTokens.yellow,
        const MovementMission(),
      ),
    ];
    return ListView(
      key: const ValueKey('world'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _heroCard(c),
        const SizedBox(height: 16),
        const Text(
          'Your growing world',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: VeeTokens.ink,
          ),
        ),
        const SizedBox(height: 10),
        for (final world in worlds)
          _worldCard(
            world.$1,
            world.$2,
            world.$3,
            world.$4,
            c.unlockedWorldItems.contains(world.$1),
          ),
        const SizedBox(height: 18),
        const Text(
          'Choose your next adventure',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: VeeTokens.ink,
          ),
        ),
        const SizedBox(height: 10),
        for (final mission in missions)
          Card(
            color: VeeTokens.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: mission.$4,
                child: Icon(mission.$3, color: VeeTokens.ink),
              ),
              title: Text(
                mission.$1,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.ink,
                ),
              ),
              subtitle: Text(
                mission.$2,
                style: TextStyle(color: VeeTokens.inkSoft),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => goTo(context, mission.$5),
            ),
          ),
        const SizedBox(height: 18),
        Card(
          color: const Color(0xFFE6F3E8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📖  A tiny story with Vee',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: VeeTokens.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'A fresh story uses your latest discovery when available. Curated story still works offline.',
                  style: TextStyle(color: VeeTokens.inkSoft),
                ),
                const SizedBox(height: 12),
                WorldButton(
                  color: VeeTokens.teal,
                  onPressed: _storyLoading ? null : () => _makeStory(c),
                  child: Text(
                    _storyLoading ? 'Vee is thinking…' : 'Make a little story',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (_storyTitle != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _storyTitle!,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: VeeTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _storyText!,
                    style: const TextStyle(color: VeeTokens.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '✨ ${_storyFact ?? ''}',
                    style: const TextStyle(
                      color: VeeTokens.inkSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Vee’s movement idea: ${_storyMovement ?? 'reach'}',
                    style: const TextStyle(
                      color: VeeTokens.teal,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  WorldButton(
                    color: VeeTokens.yellow,
                    onPressed: () => goTo(context, const MovementMission()),
                    child: const Text(
                      'Start a movement mission',
                      style: TextStyle(color: VeeTokens.ink),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroCard(AppController c) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD36E), Color(0xFFFFF0C2)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Image.asset(
            'assets/vee/vee_happy_idle.webp',
            width: 88,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${c.profile.name.trim().isEmpty ? 'Explorer' : c.profile.name}!',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: VeeTokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Every little try grows your world.',
                  style: TextStyle(
                    color: VeeTokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _statPill('⭐ ${c.stars}', 'stars'),
                    _statPill('🧭 ${c.totalCompletions}', 'adventures'),
                    _statPill('🔎 ${c.discoveries.length}', 'discoveries'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String text, String key) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: VeeTokens.white.withValues(alpha: .85),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(color: VeeTokens.ink, fontWeight: FontWeight.w900),
    ),
  );

  Widget _worldCard(
    String id,
    String emoji,
    String title,
    String subtitle,
    bool unlocked,
  ) {
    return Card(
      elevation: 0,
      color: unlocked ? VeeTokens.white : const Color(0xFFE9E1CE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: unlocked ? VeeTokens.mint : const Color(0xFFD5CCB9),
          child: Text(
            unlocked ? emoji : '🔒',
            style: const TextStyle(fontSize: 22),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: VeeTokens.ink,
          ),
        ),
        subtitle: Text(
          unlocked
              ? subtitle
              : 'Unlock by completing adventures or finding discoveries.',
          style: TextStyle(color: VeeTokens.inkSoft),
        ),
        trailing: Text(
          unlocked ? 'OPEN' : 'LOCKED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: unlocked ? VeeTokens.teal : VeeTokens.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _journalTab(AppController c) {
    final recentEvents = c.activityEvents.reversed.take(12).toList();
    final questItems = [
      (
        '🌿',
        'Nature detective',
        'Find a leaf, tree or flower.',
        c.discoveries.any(
          (id) =>
              id.contains('leaf') ||
              id.contains('tree') ||
              id.contains('flower'),
        ),
      ),
      (
        '🐾',
        'Adventure mover',
        'Complete three movement or adventure activities.',
        c.totalCompletions >= 3,
      ),
      (
        '✨',
        'Curious collector',
        'Discover five different things.',
        c.discoveries.length >= 5,
      ),
    ];
    return ListView(
      key: const ValueKey('journal'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const Text(
          'Discovery journal',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: VeeTokens.ink,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'A little book of things you have tried, found and learned.',
          style: TextStyle(color: VeeTokens.inkSoft),
        ),
        const SizedBox(height: 14),
        if (c.discoveries.isEmpty)
          _emptyCard(
            '🔎',
            'Your journal is waiting',
            'Try SPOT or EXPLORE to add your first discovery.',
          )
        else
          ...c.discoveries.reversed
              .take(40)
              .map(
                (id) => Card(
                  elevation: 0,
                  color: VeeTokens.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: VeeTokens.mint,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: VeeTokens.teal,
                      ),
                    ),
                    title: Text(
                      _prettyId(id),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: VeeTokens.ink,
                      ),
                    ),
                    subtitle: Text(
                      id.startsWith('story-')
                          ? 'Story adventure'
                          : 'Discovery saved to your world',
                      style: TextStyle(color: VeeTokens.inkSoft),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 18),
        const Text(
          'Quest badges',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: VeeTokens.ink,
          ),
        ),
        const SizedBox(height: 8),
        for (final quest in questItems)
          Card(
            elevation: 0,
            color: quest.$4 ? const Color(0xFFE3F4E6) : VeeTokens.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: Text(quest.$1, style: const TextStyle(fontSize: 28)),
              title: Text(
                quest.$2,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.ink,
                ),
              ),
              subtitle: Text(
                quest.$3,
                style: TextStyle(color: VeeTokens.inkSoft),
              ),
              trailing: Icon(
                quest.$4
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
                color: quest.$4 ? VeeTokens.teal : VeeTokens.inkSoft,
              ),
            ),
          ),
        const SizedBox(height: 18),
        const Text(
          'Recent adventure trail',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: VeeTokens.ink,
          ),
        ),
        const SizedBox(height: 8),
        if (recentEvents.isEmpty)
          _emptyCard(
            '🪵',
            'Your trail starts here',
            'Completed activities and new discoveries will appear here.',
          )
        else
          ...recentEvents.map((event) {
            final type = (event['type'] ?? 'adventure').toString();
            final label = _prettyId((event['label'] ?? 'Adventure').toString());
            final at = DateTime.tryParse((event['at'] ?? '').toString())
                ?.toLocal();
            final date = at == null ? '' : '${at.day}/${at.month}';
            return ListTile(
              leading: Icon(
                type == 'discovery_found'
                    ? Icons.search_rounded
                    : Icons.check_circle_outline_rounded,
                color: VeeTokens.teal,
              ),
              title: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: VeeTokens.ink,
                ),
              ),
              subtitle: Text(
                type == 'discovery_found'
                    ? 'Discovery found'
                    : 'Adventure completed',
                style: TextStyle(color: VeeTokens.inkSoft),
              ),
              trailing: Text(date, style: TextStyle(color: VeeTokens.inkSoft)),
            );
          }),
      ],
    );
  }

  Future<void> _toggleOpenDiscovery(AppController c, bool value) async {
    if (value) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Turn on “Discover anything”?'),
          content: const Text(
            'When a child takes a photo in SPOT, the photo is sent securely to an AI '
            'service so Vee can name the object and share a short, simple fact. '
            'Pictures with people are refused, photos are not stored, and every fact '
            'is checked before a child sees it. You can turn this off at any time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Turn on'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await c.setOpenDiscovery(value);
    if (mounted) setState(() {});
  }

  Widget _openDiscoveryCard(AppController c) {
    return Card(
      color: VeeTokens.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SwitchListTile(
        value: c.openDiscoveryEnabled,
        onChanged: (value) => _toggleOpenDiscovery(c, value),
        secondary: const Icon(
          Icons.travel_explore_rounded,
          color: VeeTokens.teal,
          size: 32,
        ),
        title: const Text(
          'Discover anything in SPOT',
          style: TextStyle(fontWeight: FontWeight.w900, color: VeeTokens.ink),
        ),
        subtitle: const Text(
          'Off: Vee only knows the game’s own objects. '
          'On: Vee can name almost any object in a photo and share a simple fact. '
          'Photos are sent to an AI service, never stored, and people are never described.',
          style: TextStyle(color: VeeTokens.inkSoft),
        ),
      ),
    );
  }

  Widget _parentTab(AppController c) {
    if (!_parentUnlocked) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: VeeTokens.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔐', style: TextStyle(fontSize: 54)),
                    const Text(
                      'Grown-up corner',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: VeeTokens.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask a grown-up to answer this check: $_leftNumber + $_rightNumber = ?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: VeeTokens.inkSoft),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _answerController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Answer',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _unlockParent(),
                    ),
                    if (_parentError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _parentError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 14),
                    WorldButton(
                      color: VeeTokens.teal,
                      onPressed: _unlockParent,
                      child: const Text(
                        'Open parent dashboard',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This simple gate discourages accidental child access; it is not account authentication.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: VeeTokens.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekEvents = c.activityEvents.where((event) {
      final at = DateTime.tryParse((event['at'] ?? '').toString());
      return at != null && at.isAfter(weekAgo);
    }).toList();
    final weeklyDiscoveries = weekEvents
        .where((e) => e['type'] == 'discovery_found')
        .length;
    final weeklyCompletions = weekEvents
        .where((e) => e['type'] == 'activity_completed')
        .length;
    final activities = <String, int>{};
    for (final id in c.completedActivities) {
      final category = id.split('-').first.toUpperCase();
      activities[category] = (activities[category] ?? 0) + 1;
    }
    return ListView(
      key: const ValueKey('parent'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Family activity report',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.ink,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _parentUnlocked = false),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Lock'),
            ),
          ],
        ),
        const Text(
          'A summary of recorded play, not a developmental or medical assessment.',
          style: TextStyle(color: VeeTokens.inkSoft),
        ),
        const SizedBox(height: 14),
        _openDiscoveryCard(c),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _metricCard('⭐', '${c.stars}', 'Total stars')),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard('🎮', '${c.totalCompletions}', 'Activities'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard(
                '🔎',
                '${c.discoveries.length}',
                'Discoveries',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Last 7 days',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: VeeTokens.ink,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: VeeTokens.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _reportRow(
                  Icons.check_circle_rounded,
                  'Activities completed',
                  '$weeklyCompletions',
                ),
                const Divider(),
                _reportRow(
                  Icons.search_rounded,
                  'New discovery events',
                  '$weeklyDiscoveries',
                ),
                const Divider(),
                _reportRow(
                  Icons.star_rounded,
                  'Current progression level',
                  '${c.progression}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Activity mix',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: VeeTokens.ink,
          ),
        ),
        const SizedBox(height: 8),
        if (activities.isEmpty)
          _emptyCard(
            '🌱',
            'No activity yet',
            'The first completed adventure will appear here.',
          )
        else
          ...activities.entries.map(
            (entry) => _reportRow(
              Icons.play_circle_outline_rounded,
              entry.key,
              '${entry.value}',
            ),
          ),
        const SizedBox(height: 18),
        Card(
          color: const Color(0xFFFFE8D9),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy and reset',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: VeeTokens.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Progress is stored locally in this browser/device. This build does not sync across devices. Reset permanently clears local stars, discoveries and activity history.',
                  style: TextStyle(color: VeeTokens.inkSoft),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Reset all adventure progress'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8E3A25),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Reset all progress?'),
                        content: const Text(
                          'This clears stars, discoveries, completed activities and the journal on this device.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      await c.resetAdventureProgress();
                      if (mounted) setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String emoji, String value, String label) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(
      color: VeeTokens.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 25)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: VeeTokens.ink,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: VeeTokens.inkSoft,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _reportRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, color: VeeTokens.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: VeeTokens.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: VeeTokens.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Widget _emptyCard(String emoji, String title, String message) => Container(
    decoration: BoxDecoration(
      color: VeeTokens.white,
      borderRadius: BorderRadius.circular(22),
    ),
    padding: const EdgeInsets.all(22),
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 42)),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: VeeTokens.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: VeeTokens.inkSoft),
        ),
      ],
    ),
  );
}
