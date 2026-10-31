import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../models/activity.dart';
import '../services/movement/movement_catalog.dart';
import 'juicy_tap.dart';

class MovementChallenge extends StatefulWidget {
  final MovementStep step;
  final VoidCallback onComplete;

  /// Called after each counted movement (1-based), before [onComplete].
  /// Screens use it to make Vee cheer.
  final ValueChanged<int>? onCount;

  const MovementChallenge({
    super.key,
    required this.step,
    required this.onComplete,
    this.onCount,
  });

  @override
  State<MovementChallenge> createState() => _MovementChallengeState();
}

class _MovementChallengeState extends State<MovementChallenge> {
  static const List<String> _cheers = <String>[
    'Yes!',
    'Great!',
    'Wow!',
    'Super!',
    'You did it!',
    'Amazing!',
  ];

  int done = 0;

  MovementDefinition get definition =>
      MovementCatalog.resolve(widget.step.name);

  String get label => '${definition.emoji} ${definition.label}';

  String get instruction => definition.instruction;

  void _count() {
    if (done >= widget.step.count) return;
    final nextDone = done + 1;
    setState(() => done = nextDone);
    widget.onCount?.call(nextDone);
    if (nextDone == widget.step.count) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.step.count;
    final finished = done >= total;
    final cheer = done == 0 ? '' : _cheers[(done - 1) % _cheers.length];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VeeTokens.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: VeeTokens.shadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: VeeTokens.textOnLight),
          ),
          const SizedBox(height: 5),
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.25,
              color: VeeTokens.textSecondaryOnLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adventure count: $total ${total == 1 ? 'time' : 'times'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: VeeTokens.textSecondaryOnLight,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: List.generate(
              total,
              (i) => AnimatedScale(
                scale: i < done ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: Icon(
                  i < done ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: VeeTokens.yellow,
                  size: 25,
                ),
              ),
            ),
          ),
          // A short cheer after each count; the space is always reserved so
          // the panel does not jump around.
          SizedBox(
            height: 28,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  cheer,
                  key: ValueKey<int>(done),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: VeeTokens.teal,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          JuicyTap(
            onTap: finished ? null : _count,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: VeeTokens.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'I did it!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
