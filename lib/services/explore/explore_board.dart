import 'dart:math';

import '../../models/content_catalog.dart';
import '../../models/environment_mode.dart';

/// What is hiding in one spot.
enum SpotKind {
  /// A catalogue item, with its fun fact and sticker.
  item,

  /// A friendly creature that just says hello. Nobody loses anything by
  /// finding one; it is there to make the board feel alive and funny.
  critter,

  /// A rare, shiny spot with a bonus star. It is optional.
  golden,
}

class Critter {
  final String emoji;
  final String name;
  final String line;

  const Critter(this.emoji, this.name, this.line);
}

class HideSpot {
  final int index;
  final SpotKind kind;
  final CatalogItem? item;
  final Critter? critter;

  const HideSpot({
    required this.index,
    required this.kind,
    this.item,
    this.critter,
  });
}

/// One round of hide-and-seek: a handful of hiding spots, each holding an
/// item, a critter or (rarely) a golden find.
///
/// The board prefers items the child has NOT collected yet, so every round has
/// something new to discover. This class is plain Dart so it can be tested.
class ExploreBoard {
  final List<HideSpot> spots;
  final Set<int> _opened = <int>{};

  ExploreBoard(this.spots);

  static const List<Critter> outdoorCritters = <Critter>[
    Critter('🐞', 'ladybird', 'A ladybird says hello!'),
    Critter('🐌', 'snail', 'A slow snail waves a feeler!'),
    Critter('🐛', 'caterpillar', 'A caterpillar wiggles by!'),
    Critter('🐝', 'bee', 'A busy bee buzzes past!'),
  ];

  static const List<Critter> indoorCritters = <Critter>[
    Critter('🐭', 'mouse', 'A tiny toy mouse squeaks hello!'),
    Critter('🐱', 'kitten', 'A sleepy kitten gives a big yawn!'),
    Critter('🧸', 'teddy', 'A teddy bear waves hello!'),
    Critter('🧦', 'sock', 'Just a lonely sock. It wants a friend!'),
  ];

  /// How many spots a round has for each pace (gentle, steady, energetic).
  static int spotsForItems(int itemLimit) => itemLimit.clamp(4, 8);

  int get itemSpotCount =>
      spots.where((spot) => spot.kind == SpotKind.item).length;

  int get openedItemCount => spots
      .where(
        (spot) => spot.kind == SpotKind.item && _opened.contains(spot.index),
      )
      .length;

  /// True when every ordinary item spot has been opened. The golden spot is a
  /// bonus and never has to be found.
  bool get roundComplete => openedItemCount >= itemSpotCount;

  bool isOpen(int index) => _opened.contains(index);

  /// Opens a spot. Returns it, or null if it was already open or does not exist.
  HideSpot? open(int index) {
    if (index < 0 || index >= spots.length || _opened.contains(index)) {
      return null;
    }
    _opened.add(index);
    return spots[index];
  }

  /// Item ids on this board (including the golden one).
  Set<String> get itemIds => <String>{
    for (final spot in spots)
      if (spot.item != null) spot.item!.id,
  };

  static ExploreBoard generate({
    required ExploreSetting setting,
    required Set<String> collected,
    required Random random,
    int spotCount = 6,
    Set<String> recent = const <String>{},
  }) {
    final count = spotCount.clamp(4, 8);
    final goldenCount = count >= 6 ? 1 : 0;
    var critterCount = max(1, count ~/ 4);
    var itemCount = count - critterCount - goldenCount;

    // Everything that can appear in this world; small worlds (the beach has
    // two items) are topped up with items from similar worlds.
    final pool = List<CatalogItem>.of(ContentCatalog.forSetting(setting.id));
    if (pool.length < itemCount + goldenCount) {
      for (final other in ContentCatalog.settings) {
        if (other.mode != setting.mode || other.id == setting.id) continue;
        for (final item in ContentCatalog.forSetting(other.id)) {
          if (pool.every((existing) => existing.id != item.id)) pool.add(item);
        }
      }
    }

    // New things first, then familiar ones, and what was just shown last.
    List<CatalogItem> shuffled(Iterable<CatalogItem> items) =>
        List<CatalogItem>.of(items)..shuffle(random);
    final fresh = shuffled(
      pool.where((i) => !collected.contains(i.id) && !recent.contains(i.id)),
    );
    final familiar = shuffled(
      pool.where((i) => collected.contains(i.id) && !recent.contains(i.id)),
    );
    final justSeen = shuffled(pool.where((i) => recent.contains(i.id)));
    final ordered = <CatalogItem>[...fresh, ...familiar, ...justSeen];

    if (ordered.length < itemCount) {
      itemCount = ordered.length;
      critterCount = count - goldenCount - itemCount;
    }
    final items = ordered.take(itemCount).toList();
    final leftover = ordered.skip(itemCount).toList();

    CatalogItem? goldenItem;
    if (goldenCount > 0 && ordered.isNotEmpty) {
      goldenItem = leftover.firstWhere(
        (i) => !collected.contains(i.id),
        orElse: () => leftover.isNotEmpty
            ? leftover[random.nextInt(leftover.length)]
            : ordered[random.nextInt(ordered.length)],
      );
    }

    final critterSource = setting.mode == EnvironmentMode.indoor
        ? indoorCritters
        : outdoorCritters;
    final critters = List<Critter>.of(critterSource)..shuffle(random);

    final contents = <HideSpot>[
      for (final item in items)
        HideSpot(index: 0, kind: SpotKind.item, item: item),
      if (goldenItem != null)
        HideSpot(index: 0, kind: SpotKind.golden, item: goldenItem),
      for (var i = 0; i < critterCount; i++)
        HideSpot(
          index: 0,
          kind: SpotKind.critter,
          critter: critters[i % critters.length],
        ),
    ]..shuffle(random);

    return ExploreBoard(<HideSpot>[
      for (var i = 0; i < contents.length; i++)
        HideSpot(
          index: i,
          kind: contents[i].kind,
          item: contents[i].item,
          critter: contents[i].critter,
        ),
    ]);
  }
}

/// How much of a world the child has collected so far.
class WorldProgress {
  final int found;
  final int total;

  const WorldProgress(this.found, this.total);

  bool get mastered => total > 0 && found >= total;

  double get fraction => total == 0 ? 0 : found / total;

  static WorldProgress of(ExploreSetting setting, Set<String> collected) {
    final items = ContentCatalog.forSetting(setting.id);
    final found = items.where((item) => collected.contains(item.id)).length;
    return WorldProgress(found, items.length);
  }
}
