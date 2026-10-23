import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

/// Three-line options button used on activity pages.
class GameOptionsButton extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const GameOptionsButton({
    super.key,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Options',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showGameOptions(context, onRestart: onRestart, onMainMenu: onMainMenu),
          child: Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: VeeTokens.white.withOpacity(.92),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: VeeTokens.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MenuLine(),
                SizedBox(height: 4),
                _MenuLine(),
                SizedBox(height: 4),
                _MenuLine(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuLine extends StatelessWidget {
  const _MenuLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      width: 24,
      decoration: BoxDecoration(
        color: VeeTokens.teal,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

Future<void> showGameOptions(
  BuildContext context, {
  required VoidCallback onRestart,
  required VoidCallback onMainMenu,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(.25),
    isScrollControlled: false,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: VeeTokens.cream,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: VeeTokens.shadow,
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: VeeTokens.textSecondaryOnLight.withOpacity(.28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Adventure options',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: VeeTokens.textOnLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    _OptionTile(
                      icon: Icons.home_rounded,
                      label: 'Main menu',
                      color: VeeTokens.teal,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onMainMenu();
                      },
                    ),
                    const SizedBox(height: 10),
                    _OptionTile(
                      icon: Icons.refresh_rounded,
                      label: 'Restart mission',
                      color: VeeTokens.yellow,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onRestart();
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: VeeTokens.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: VeeTokens.shadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: VeeTokens.textOnLight, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: VeeTokens.textOnLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const SizedBox(
                width: 27,
                child: Icon(Icons.chevron_right_rounded, color: VeeTokens.textSecondaryOnLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
