import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

class SpeechBubble extends StatelessWidget {
  final String text;
  final String? eyebrow;
  final double? maxWidth;

  const SpeechBubble({
    super.key,
    required this.text,
    this.eyebrow,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: VeeTokens.white.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: VeeTokens.shadow,
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (eyebrow != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                eyebrow!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.0,
                  color: VeeTokens.teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 19,
              height: 1.12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (maxWidth == null) return bubble;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: bubble,
    );
  }
}
