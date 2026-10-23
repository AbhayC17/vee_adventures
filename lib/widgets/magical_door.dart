import 'package:flutter/material.dart';

class MagicalDoor extends StatelessWidget {
  final bool activated;
  final bool open;
  final VoidCallback onTap;
  final Widget? overlay;

  const MagicalDoor({
    super.key,
    required this.activated,
    required this.open,
    required this.onTap,
    this.overlay,
  });

  static const closedDoor = 'assets/world/magical_door_closed.png';
  static const openDoor = 'assets/world/magical_door_open.png';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Image.asset(
              open ? openDoor : closedDoor,
              key: ValueKey(open),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Magical door asset could not load: $error');
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A542B),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFFFD56A), width: 5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55000000), blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.door_front_door_rounded, size: 70, color: Color(0xFFFFE2A1)),
                );
              },
            ),
          ),
          if (activated && !open)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(70),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(.32),
                      blurRadius: 28,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}
