import 'package:flutter/material.dart';
import '../app/design_tokens.dart';
import '../models/activity.dart';
import '../services/movement/movement_catalog.dart';

class MovementChallenge extends StatefulWidget {
  final MovementStep step;
  final VoidCallback onComplete;
  const MovementChallenge({super.key, required this.step, required this.onComplete});
  @override State<MovementChallenge> createState() => _MovementChallengeState();
}

class _MovementChallengeState extends State<MovementChallenge> {
  int done = 0;
  MovementDefinition get definition =>
      MovementCatalog.resolve(widget.step.name);

  String get label => '${definition.emoji} ${definition.label}';

  String get instruction => definition.instruction;

  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: VeeTokens.white.withOpacity(.96), borderRadius: BorderRadius.circular(26),
      boxShadow: const [BoxShadow(color: VeeTokens.shadow, blurRadius: 14, offset: Offset(0, 8))]),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: VeeTokens.textOnLight)),
      const SizedBox(height: 5),
      Text(instruction, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, height: 1.25, color: VeeTokens.textSecondaryOnLight)),
      const SizedBox(height: 8),
      Text(
        'Adventure count: ${widget.step.count} ${widget.step.count == 1 ? 'time' : 'times'}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: VeeTokens.textSecondaryOnLight,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 6, children: List.generate(widget.step.count, (i) => Icon(i < done ? Icons.star_rounded : Icons.star_outline_rounded,
        color: VeeTokens.yellow, size: 25))),
      const SizedBox(height: 14),
      GestureDetector(onTap: () {
        if (done >= widget.step.count) return;
        final nextDone = done + 1;
        setState(() => done = nextDone);
        if (nextDone == widget.step.count) {
          widget.onComplete();
        }
      }, child: AnimatedContainer(duration: const Duration(milliseconds: 120), padding: const EdgeInsets.symmetric(horizontal: 28,
      vertical: 16), decoration: BoxDecoration(color: VeeTokens.teal, borderRadius: BorderRadius.circular(20)),
        child: const Text('I did it!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: VeeTokens.white))))
    ]),
  );
}
