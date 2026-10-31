import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../models/environment_mode.dart';
import 'juicy_tap.dart';

class EnvironmentModeToggle extends StatelessWidget {
  final EnvironmentMode value;
  final ValueChanged<EnvironmentMode> onChanged;

  const EnvironmentModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: VeeTokens.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: VeeTokens.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: EnvironmentMode.values.map((mode) {
          final selected = mode == value;
          return JuicyTap(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: selected ? VeeTokens.teal : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode == EnvironmentMode.indoor
                        ? Icons.home_rounded
                        : Icons.park_rounded,
                    size: 22,
                    color: selected ? VeeTokens.white : VeeTokens.teal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: selected ? VeeTokens.white : VeeTokens.textOnLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
