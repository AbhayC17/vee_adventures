import 'package:flutter/material.dart';

import '../../app/game_app_scope.dart';
import '../../app/navigation.dart';
import '../../app/app_controller.dart';
import '../../app/design_tokens.dart';
import '../../models/activity.dart';
import '../../models/content_catalog.dart';
import '../../models/environment_mode.dart';
import '../../widgets/environment_mode_toggle.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/star_counter.dart';
import '../companion/adventure_companion_screen.dart';
import '../explore/explore_screen.dart';
import '../movement/movement_mission.dart';
import '../play/play_screen.dart';
import '../spot/spot_screen.dart';

class _DiscoveryItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  const _DiscoveryItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

class _DiscoveryTile extends StatelessWidget {
  final _DiscoveryItem item;

  const _DiscoveryTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: VeeTokens.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: VeeTokens.shadow,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Discovery icon
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: item.color.withOpacity(.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 36,
              color: item.color,
            ),
          ),

          const SizedBox(height: 10),

          // Child-facing discovery name
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: VeeTokens.textOnLight,
              fontWeight: FontWeight.w700,
              height: 1.08,
            ),
          ),
        ],
      ),
    );
  }
}

class AdventureHub extends StatefulWidget {
  const AdventureHub({super.key});

  @override
  State<AdventureHub> createState() => _AdventureHubState();
}

class _AdventureHubState extends State<AdventureHub> {

  // ─────────────────────────────────────────────
  // DISCOVERY SHELF
  // ─────────────────────────────────────────────

  void _showDiscoveries(
    BuildContext context,
    AppController controller,
  ) {
    final items = _discoveryItems(controller);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final dialogWidth = screenWidth < 600
        ? screenWidth - 28
        : screenWidth.clamp(0, 920).toDouble();

    final dialogHeight = screenHeight < 700
        ? screenHeight - 70
        : (screenHeight * .78).clamp(500.0, 700.0);

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(.32),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 24,
          ),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                24,
                22,
                24,
                24,
              ),
              decoration: BoxDecoration(
                color: VeeTokens.cream,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: VeeTokens.shadow,
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─────────────────────────────
                  // HEADER
                  // ─────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Discovery Shelf',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: VeeTokens.textOnLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: VeeTokens.mint,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '${items.length} found',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: VeeTokens.teal,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ─────────────────────────────
                  // EMPTY STATE
                  // ─────────────────────────────
                  if (items.isEmpty)
                    Expanded(
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 360,
                          ),
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: VeeTokens.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: VeeTokens.yellow.withOpacity(.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 42,
                                  color: VeeTokens.yellow,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Your first discovery is waiting!',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: VeeTokens.textOnLight,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Play an adventure and something special will appear here.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: VeeTokens.textSecondaryOnLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )

                  // ─────────────────────────────
                  // DISCOVERY GRID
                  // ─────────────────────────────
                  else
                    Expanded(
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            ...items.take(9).map(
                              (item) => SizedBox(
                                width: items.length > 6 ? 170 : 190,
                                height: 145,
                                child: _DiscoveryTile(item: item),
                              ),
                            ),
                            if (items.length > 9)
                              Container(
                                width: 170,
                                height: 145,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: VeeTokens.mint,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  '+${items.length - 9} more discoveries',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: VeeTokens.teal,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // DISCOVERY DATA
  // ─────────────────────────────────────────────

  List<_DiscoveryItem> _discoveryItems(AppController controller) {
    final seen = <String>{};
    final result = <_DiscoveryItem>[];
    for (final raw in controller.discoveries.reversed) {
      final id = _normalizeDiscoveryId(raw);
      if (!seen.add(id)) continue;
      if (id.startsWith('item-')) {
        final item = ContentCatalog.get(id.substring(5));
        if (item == null) continue;
        result.add(_DiscoveryItem(id: id, title: item.name, icon: Icons.auto_awesome_rounded, color: VeeTokens.teal));
      } else if (id.startsWith('spot-')) {
        result.add(_DiscoveryItem(id: id, title: 'SPOT • ${_pretty(id.substring(5))}', icon: Icons.search_rounded, color: VeeTokens.sky));
      } else if (id.startsWith('explore-')) {
        result.add(_DiscoveryItem(id: id, title: 'EXPLORE • ${_pretty(id.substring(8))}', icon: Icons.explore_rounded,
        color: VeeTokens.leaf));
      } else if (id.startsWith('play-')) {
        result.add(_DiscoveryItem(id: id, title: 'PLAY • ${_pretty(id.substring(5))}', icon: Icons.auto_awesome_rounded,
        color: VeeTokens.yellow));
      }
      if (result.length >= 24) break;
    }
    return result;
  }

  String _pretty(String value) => value.replaceAll('_', ' ').replaceAll('-', ' ');

  String _normalizeDiscoveryId(String raw) {
    final value = raw.trim();

    // Repairs old values like:
    // spot-spot-20
    // explore-explore-28
    // play-play-08
    final legacy = RegExp(
      r'^(spot|explore|play)-(spot|explore|play)-(.+)$',
    ).firstMatch(value);

    if (legacy != null && legacy.group(1) == legacy.group(2)) {
      return '${legacy.group(1)}-${legacy.group(3)}';
    }

    return value;
  }

  String _cleanTitle(String title) {
    final value = title.trim();

    if (value.isEmpty) {
      return 'Little Discovery';
    }

    return value;
  }

  // ─────────────────────────────────────────────
  // DISCOVERY ICONS
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────────
  // DISCOVERY COLORS
  // ─────────────────────────────────────────────

  Color _colorForType(
    ActivityType type,
  ) {
    switch (type) {
      case ActivityType.spot:
        return VeeTokens.sky;

      case ActivityType.explore:
        return VeeTokens.leaf;

      case ActivityType.play:
        return VeeTokens.yellow;
    }
  }

  // ─────────────────────────────────────────────
  // HUB
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final controller = GameAppScope.of(context);

    return Scaffold(
      backgroundColor: VeeTokens.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // The hub is designed on a fixed canvas and scales as a whole.
            // This guarantees that the complete menu is visible without a
            // page scrollbar on small or large screens.
            return Center(
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 920,
                  height: 690,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 100,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Vee’s Adventures',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: VeeTokens.textOnLight,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    controller.profile.environmentMode == EnvironmentMode.indoor
                                      ? 'Today’s adventures are indoors.'
                                      : 'Today’s adventures are outdoors.',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: VeeTokens.textSecondaryOnLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            EnvironmentModeToggle(
                              value: controller.profile.environmentMode,
                              onChanged: (mode) async {
                                await controller.setEnvironmentMode(mode);
                                if (mounted) setState(() {});
                              },
                            ),
                            const SizedBox(width: 10),
                            StarCounter(stars: controller.stars),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Discovery shelf',
                              onPressed: () => _showDiscoveries(context, controller),
                              icon: const Icon(
                                Icons.auto_awesome_mosaic_rounded,
                                color: VeeTokens.teal,
                                size: 28,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Parent dashboard and journal',
                              onPressed: () => replaceTo(context, const AdventureCompanionScreen()),
                              icon: const Icon(
                                Icons.family_restroom_rounded,
                                color: VeeTokens.teal,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: MissionCard(
                                title: 'SPOT',
                                subtitle: controller.profile.environmentMode == EnvironmentMode.indoor
                                    ? 'Find clues around indoor places.'
                                    : 'Find clues in the world outside.',
                                asset: 'assets/vee/vee_encourage.webp',
                                color: const Color(0xFFFFB49B),
                                icon: '⌕',
                                onTap: () => replaceTo(context, const SpotScreen()),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: MissionCard(
                                title: 'EXPLORE',
                                subtitle: controller.profile.environmentMode == EnvironmentMode.indoor
                                    ? 'Explore rooms and everyday worlds.'
                                    : 'Explore nature and open-air worlds.',
                                asset: 'assets/vee/vee_happy_idle.webp',
                                color: const Color(0xFFAEDB7A),
                                icon: '✿',
                                onTap: () => replaceTo(context, const ExploreScreen()),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: MissionCard(
                                title: 'PLAY',
                                subtitle: controller.profile.environmentMode == EnvironmentMode.indoor
                                    ? 'Solve cozy indoor mini-adventures.'
                                    : 'Solve outdoor mini-adventures.',
                                asset: 'assets/vee/vee_encourage.webp',
                                color: const Color(0xFFA6C6F3),
                                icon: '★',
                                onTap: () => replaceTo(context, const PlayScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 78,
                        child: GestureDetector(
                          onTap: () => replaceTo(context, const MovementMission()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                            decoration: BoxDecoration(
                              color: VeeTokens.yellow,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: const [
                                BoxShadow(
                                  color: VeeTokens.shadow,
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.explore_rounded, size: 30, color: VeeTokens.textOnLight),
                                SizedBox(width: 12),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'START A MOVEMENT MISSION',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: VeeTokens.textOnLight,
                                      ),
                                    ),
                                    Text(
                                      'Vee uses your adventure move to tune the experience.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: VeeTokens.textSecondaryOnLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}
