import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'magical_door.dart';
import 'primary_button.dart';

class ParentPass extends StatefulWidget {
  final TextEditingController controller;
  final bool activated;
  final bool open;
  final VoidCallback onSubmit;
  final String? error;
  final VoidCallback onDoorContinue;

  const ParentPass({
    super.key,
    required this.controller,
    required this.activated,
    required this.open,
    required this.onSubmit,
    required this.onDoorContinue,
    this.error,
  });

  @override
  State<ParentPass> createState() => _ParentPassState();
}

class _ParentPassState extends State<ParentPass> {
  bool revealed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 560.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 620.0;

        final compact = height < 600;
        final doorWidth = math.min(width * .54, compact ? 250.0 : 310.0);
        final doorHeight = doorWidth * 1.5;
        final panelWidth = math.min(width * .82, 500.0);

        final lower = widget.activated
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.open
                        ? 'Adventure unlocked!'
                        : 'Your grown-up helped!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 17 : 20,
                      fontWeight: FontWeight.w900,
                      color: VeeTokens.textOnLight,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  SizedBox(
                    height: compact ? 42 : 48,
                    child: WorldButton(
                      child: Text(
                        widget.open
                            ? "Let's go!"
                            : 'Tap the door to continue',
                        style: TextStyle(
                          fontSize: compact ? 14 : 16,
                        ),
                      ),
                      onPressed:
                          widget.open ? widget.onDoorContinue : null,
                      color: VeeTokens.teal,
                    ),
                  ),
                ],
              )
            : (!revealed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Whoa! Look at that magical door.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 17 : 20,
                          fontWeight: FontWeight.w900,
                          color: VeeTokens.textOnLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap it to discover what it needs.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w700,
                          color: VeeTokens.textSecondaryOnLight,
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: panelWidth,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 16,
                      vertical: compact ? 9 : 13,
                    ),
                    decoration: BoxDecoration(
                      color: VeeTokens.white.withOpacity(.96),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PARENT PASS',
                          style: TextStyle(
                            fontSize: compact ? 11 : 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: VeeTokens.teal,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 7),
                        Text(
                          'A grown-up can add their email here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 14 : 17,
                            fontWeight: FontWeight.w800,
                            color: VeeTokens.textOnLight,
                          ),
                        ),
                        SizedBox(height: compact ? 6 : 10),
                        SizedBox(
                          height: compact ? 42 : 48,
                          child: TextField(
                            controller: widget.controller,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => widget.onSubmit(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: VeeTokens.textOnLight,
                              fontSize: compact ? 14 : 17,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              hintText: 'grown-up email',
                              hintStyle: TextStyle(
                                color: VeeTokens.textSecondaryOnLight,
                                fontSize: compact ? 14 : 17,
                                fontWeight: FontWeight.w600,
                              ),
                              filled: true,
                              fillColor: VeeTokens.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                        if (widget.error != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: compact ? 11 : 13,
                              fontWeight: FontWeight.w900,
                              color: VeeTokens.orange,
                            ),
                          ),
                        ],
                        SizedBox(height: compact ? 6 : 9),
                        SizedBox(
                          height: compact ? 40 : 46,
                          child: WorldButton(
                            child: Text(
                              'Add the magic pass',
                              style: TextStyle(
                                fontSize: compact ? 13 : 15,
                              ),
                            ),
                            onPressed: widget.onSubmit,
                            color: VeeTokens.yellow,
                          ),
                        ),
                      ],
                    ),
                  ));

        return SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: math.max(4, height * .015),
                child: SizedBox(
                  width: doorWidth,
                  height: doorHeight,
                  child: MagicalDoor(
                    activated: widget.activated,
                    open: widget.open,
                    onTap: widget.activated && !widget.open
                        ? widget.onDoorContinue
                        : () => setState(() => revealed = true),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: math.max(4, height * .015),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: lower,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
