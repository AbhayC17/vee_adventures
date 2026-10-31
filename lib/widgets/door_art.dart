import 'package:flutter/material.dart';

/// The archway door: closed for the grown-up card, open for "Your adventure is
/// ready!". Both pictures are transparent, so they sit on any scene.
class DoorArt extends StatelessWidget {
  final bool open;
  final double? height;

  const DoorArt({super.key, required this.open, this.height});

  static const String closedPath = 'assets/scenes/door_closed.webp';
  static const String openPath = 'assets/scenes/door_open.webp';

  @override
  Widget build(BuildContext context) => Image.asset(
    open ? openPath : closedPath,
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
  );
}
