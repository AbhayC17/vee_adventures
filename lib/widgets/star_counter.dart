import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

class StarCounter extends StatelessWidget {
  final int stars;

  const StarCounter({super.key, required this.stars});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: VeeTokens.white.withOpacity(.92),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '★',
          style: TextStyle(fontSize: 18, color: VeeTokens.yellow),
        ),
        const SizedBox(width: 6),
        Text(
          '$stars',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: VeeTokens.textOnLight,
          ),
        ),
      ],
    ),
  );
}
