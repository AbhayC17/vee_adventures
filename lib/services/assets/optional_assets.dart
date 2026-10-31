import 'package:flutter/services.dart';

/// Knows which artwork files are really bundled in the app.
///
/// Some artwork is optional (extra Vee poses, item icons, hub card art). The
/// game uses it when it exists and quietly falls back to the older artwork or
/// emoji when it does not. Asking this class first means a missing file is
/// never requested over and over, which would cause failed downloads and
/// stutter on the web.
class OptionalAssets {
  OptionalAssets._();

  static Set<String> _available = const <String>{};

  /// Reads the bundle's asset list once. Safe to call again; never throws.
  static Future<void> load([AssetBundle? bundle]) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(
        bundle ?? rootBundle,
      );
      _available = manifest.listAssets().toSet();
    } catch (_) {
      _available = const <String>{};
    }
  }

  /// True when [path] (for example `assets/items/apple.webp`) is bundled.
  static bool has(String path) => _available.contains(path);

  /// Test helper: pretend these files exist.
  static void setForTesting(Set<String> paths) => _available = paths;
}
