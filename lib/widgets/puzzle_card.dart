import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../models/content_catalog.dart';
import '../services/play/play_puzzles.dart';
import 'juicy_tap.dart';
import 'haptics.dart';
import 'item_icon.dart';

/// Shows one [PlayPuzzle] and reports when the child solves it.
///
/// * Drag puzzles accept a drag **or a simple tap**, because dragging is hard
///   for the youngest children.
/// * A wrong answer gives a gentle shake and a kind nudge; it never ends the
///   puzzle, and there is no penalty.
/// * A right answer pops, gives a small haptic tick, and calls [onSolved]
///   after a short pause so the child can enjoy it.
class PuzzleCard extends StatefulWidget {
  final PlayPuzzle puzzle;
  final VoidCallback onSolved;

  /// Called after every try with `true` for correct and `false` for wrong.
  /// Screens use it to make Vee react.
  final ValueChanged<bool>? onAttempt;

  /// Hide the built-in heading when the screen already shows one.
  final bool showTitle;

  const PuzzleCard({
    super.key,
    required this.puzzle,
    required this.onSolved,
    this.onAttempt,
    this.showTitle = true,
  });

  @override
  State<PuzzleCard> createState() => _PuzzleCardState();
}

class _PuzzleCardState extends State<PuzzleCard> {
  static const List<String> _cheers = <String>[
    '🎉 You got it!',
    '⭐ Super!',
    '🌟 Yes! That’s it!',
    '👏 Great thinking!',
  ];
  static const List<String> _nudges = <String>[
    'Almost! Try another one 💛',
    'Look again! 🔎',
    'So close! Have another go ✨',
  ];

  final math.Random _random = math.Random();
  Timer? _doneTimer;
  String? _wrongId;
  int _wrongTick = 0;
  bool _solved = false;
  String _message = '';

  @override
  void dispose() {
    _doneTimer?.cancel();
    super.dispose();
  }

  CatalogItem? _byId(String id) {
    for (final item in widget.puzzle.options) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _choose(CatalogItem item) {
    if (_solved) return;
    if (item.id == widget.puzzle.answer.id) {
      Haptics.medium();
      setState(() {
        _solved = true;
        _wrongId = null;
        _message = _cheers[_random.nextInt(_cheers.length)];
      });
      widget.onAttempt?.call(true);
      _doneTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) widget.onSolved();
      });
    } else {
      setState(() {
        _wrongId = item.id;
        _wrongTick++;
        _message = _nudges[_random.nextInt(_nudges.length)];
      });
      widget.onAttempt?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.puzzle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.showTitle) ...<Widget>[
          Text(
            puzzle.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: VeeTokens.textOnLight,
            ),
          ),
          const SizedBox(height: 6),
        ],
        _prompt(puzzle),
        const SizedBox(height: 12),
        _body(puzzle),
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _solved
                    ? VeeTokens.teal
                    : VeeTokens.textSecondaryOnLight,
              ),
            ),
          ),
      ],
    );
  }

  Widget _prompt(PlayPuzzle puzzle) {
    if (puzzle.kind == PlayPuzzleKind.clueGuess) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: VeeTokens.mint,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          puzzle.prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w800,
            color: VeeTokens.textOnLight,
          ),
        ),
      );
    }
    return Text(
      puzzle.prompt,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: VeeTokens.textSecondaryOnLight,
      ),
    );
  }

  Widget _body(PlayPuzzle puzzle) {
    switch (puzzle.kind) {
      case PlayPuzzleKind.dragMatch:
        return _dragBody(puzzle);
      case PlayPuzzleKind.pattern:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _patternRow(puzzle),
            const SizedBox(height: 14),
            _tapBody(puzzle),
          ],
        );
      case PlayPuzzleKind.oddOneOut:
      case PlayPuzzleKind.clueGuess:
        return _tapBody(puzzle);
    }
  }

  Widget _tapBody(PlayPuzzle puzzle) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 10,
    runSpacing: 10,
    children: puzzle.options
        .map(
          (item) =>
              JuicyTap(onTap: () => _choose(item), child: _optionCard(item)),
        )
        .toList(),
  );

  Widget _dragBody(PlayPuzzle puzzle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: puzzle.options
              .map(
                (item) => JuicyTap(
                  onTap: () => _choose(item),
                  child: Draggable<String>(
                    data: item.id,
                    maxSimultaneousDrags: _solved ? 0 : 1,
                    feedback: Material(
                      color: Colors.transparent,
                      child: ItemIcon(item, size: 64),
                    ),
                    childWhenDragging: Opacity(
                      opacity: .25,
                      child: _optionCard(item),
                    ),
                    child: _optionCard(item),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        DragTarget<String>(
          onWillAcceptWithDetails: (_) => !_solved,
          onAcceptWithDetails: (details) {
            final item = _byId(details.data);
            if (item != null) _choose(item);
          },
          builder: (context, candidates, rejected) {
            final hovering = candidates.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 200,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _solved
                    ? VeeTokens.mint
                    : VeeTokens.yellow.withValues(alpha: hovering ? .95 : .6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: hovering || _solved
                      ? VeeTokens.teal
                      : VeeTokens.orange.withValues(alpha: .7),
                  width: 3,
                ),
              ),
              child: _solved
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ItemIcon(puzzle.answer, size: 40),
                        const SizedBox(width: 8),
                        Text(
                          puzzle.answer.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: VeeTokens.textOnLight,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      '✨ PUT IT HERE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: VeeTokens.textOnLight,
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _patternRow(PlayPuzzle puzzle) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final item in puzzle.sequence) _tile(ItemIcon(item, size: 38)),
        _tile(
          _solved
              ? ItemIcon(puzzle.answer, size: 38)
              : const Text(
                  '?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: VeeTokens.orange,
                  ),
                ),
          highlight: true,
        ),
      ],
    );
  }

  Widget _tile(Widget content, {bool highlight = false}) => Container(
    width: 58,
    height: 58,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: highlight
          ? VeeTokens.yellow.withValues(alpha: .6)
          : VeeTokens.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: highlight ? VeeTokens.orange : VeeTokens.creamDeep,
        width: 2.5,
      ),
    ),
    child: content,
  );

  Widget _optionCard(CatalogItem item) {
    final solvedHere = _solved && item.id == widget.puzzle.answer.id;
    final wrongHere = !_solved && _wrongId == item.id;
    final background = solvedHere
        ? VeeTokens.mint
        : wrongHere
        ? VeeTokens.softPeach
        : VeeTokens.white;
    final border = solvedHere
        ? VeeTokens.teal
        : wrongHere
        ? VeeTokens.orange
        : Colors.transparent;

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(wrongHere ? '${item.id}-$_wrongTick' : item.id),
      tween: Tween<double>(begin: 0, end: 1),
      duration: wrongHere ? const Duration(milliseconds: 420) : Duration.zero,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(
          wrongHere ? math.sin(t * math.pi * 6) * 9 * (1 - t) : 0,
          0,
        ),
        child: child,
      ),
      child: AnimatedScale(
        scale: solvedHere ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: Container(
          width: 112,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 3),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: VeeTokens.shadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ItemIcon(item, size: 48),
              const SizedBox(height: 4),
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.textOnLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
