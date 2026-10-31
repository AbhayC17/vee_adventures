import 'package:flutter/material.dart';

import '../models/content_catalog.dart';
import '../services/assets/optional_assets.dart';

/// Shows a catalog item as its illustrated icon (`assets/items/<id>.webp`),
/// or as its emoji until that icon has been added to the project.
///
/// Illustrated icons look the same on every device and avoid the web's
/// emoji-font download, so they are worth adding. See docs/ASSET_PROMPTS.md.
class ItemIcon extends StatelessWidget {
  final CatalogItem item;
  final double size;

  const ItemIcon(this.item, {super.key, this.size = 40});

  static String pathFor(String itemId) => 'assets/items/$itemId.webp';

  @override
  Widget build(BuildContext context) {
    final path = pathFor(item.id);
    final Widget picture;
    if (OptionalAssets.has(path)) {
      picture = Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        cacheWidth: (size * 3).round(),
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => _emoji(),
      );
    } else {
      picture = _emoji();
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(child: picture),
    );
  }

  Widget _emoji() => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(item.emoji, style: TextStyle(fontSize: size * .85)),
  );
}
