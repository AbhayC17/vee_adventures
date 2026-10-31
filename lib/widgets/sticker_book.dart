import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/design_tokens.dart';
import '../models/content_catalog.dart';
import 'item_icon.dart';

/// Opens Vee's sticker book: every discovery in the game as a sticker.
/// Ones the child has met are in full colour; the rest wait as mystery
/// stickers, which gives children something to collect.
void showStickerBook(BuildContext context, AppController controller) {
  final collected = controller.collectedItemIds;
  int count(String prefix) => controller.completedActivities
      .where((id) => id.startsWith(prefix))
      .length;

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .32),
    builder: (dialogContext) => _StickerBookDialog(
      collected: collected,
      spotCount: count('spot-'),
      exploreCount: count('explore-'),
      playCount: count('play-'),
      mysteryCount: controller.discoveries
          .where((id) => id.startsWith('mystery-'))
          .length,
      worldCount: controller.discoveries
          .where((id) => id.startsWith('world-'))
          .length,
    ),
  );
}

class _StickerBookDialog extends StatelessWidget {
  final Set<String> collected;
  final int spotCount;
  final int exploreCount;
  final int playCount;
  final int mysteryCount;
  final int worldCount;

  const _StickerBookDialog({
    required this.collected,
    required this.spotCount,
    required this.exploreCount,
    required this.playCount,
    required this.mysteryCount,
    required this.worldCount,
  });

  static Color _categoryColor(String category) => switch (category) {
    'food' => VeeTokens.orange,
    'plant' => VeeTokens.leaf,
    'animal' => VeeTokens.sky,
    'nature' => VeeTokens.lilac,
    _ => VeeTokens.peach,
  };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width < 600
        ? size.width - 28
        : size.width.clamp(0, 920).toDouble();
    final height = size.height < 700
        ? size.height - 70
        : (size.height * .78).clamp(500.0, 700.0).toDouble();

    const items = ContentCatalog.items;
    final total = items.length;
    final found = items.where((item) => collected.contains(item.id)).length;
    final complete = found == total;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
          decoration: BoxDecoration(
            color: VeeTokens.cream,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: VeeTokens.shadow,
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '📖 My Sticker Book',
                      style: Theme.of(context).textTheme.headlineMedium,
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
                      '$found / $total',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: VeeTokens.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Close',
                    iconSize: 30,
                    color: VeeTokens.teal,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                complete
                    ? '🏆 You found every sticker. Amazing!'
                    : found == 0
                    ? 'Go on an adventure to find your first sticker!'
                    : 'Find ${total - found} more to fill the book.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: VeeTokens.textSecondaryOnLight,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: items
                          .map(
                            (item) => _StickerTile(
                              item: item,
                              found: collected.contains(item.id),
                              color: _categoryColor(item.category),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: <Widget>[
                  _BadgeChip(text: '🔍 SPOT adventures: $spotCount'),
                  _BadgeChip(text: '🌳 EXPLORE trips: $exploreCount'),
                  _BadgeChip(text: '⭐ PLAY stories: $playCount'),
                  _BadgeChip(text: '🔎 Mystery finds: $mysteryCount'),
                  _BadgeChip(text: '🏆 Worlds mastered: $worldCount'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerTile extends StatelessWidget {
  final CatalogItem item;
  final bool found;
  final Color color;

  const _StickerTile({
    required this.item,
    required this.found,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: found
          ? '${item.name} sticker, found'
          : 'Mystery sticker, not found yet',
      child: ExcludeSemantics(
        child: Container(
          width: 118,
          height: 118,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: found ? VeeTokens.white : VeeTokens.creamDeep,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: found ? color : VeeTokens.creamDeep,
              width: 4,
            ),
            boxShadow: found
                ? const <BoxShadow>[
                    BoxShadow(
                      color: VeeTokens.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              found
                  ? TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: .6, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: ItemIcon(item, size: 56),
                    )
                  : const Text(
                      '?',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: VeeTokens.textSecondaryOnLight,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(
                found ? item.name : '???',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.textOnLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String text;
  const _BadgeChip({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: VeeTokens.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: VeeTokens.textOnLight,
      ),
    ),
  );
}
