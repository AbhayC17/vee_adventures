import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'juicy_tap.dart';
import 'vee_avatar.dart';

/// One of the three big hub cards (SPOT, EXPLORE, PLAY): a white card with a
/// soft coloured picture area, a big title, a one-line description and a round
/// "go" arrow. The picture floats gently ([phase] staggers the three cards).
class MissionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final VeePose pose;
  final Color color;
  final VoidCallback onTap;
  final double phase;

  const MissionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pose,
    required this.color,
    required this.onTap,
    this.phase = 0,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  bool _hover = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _float.value = widget.phase.clamp(0.0, 1.0);
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final picture = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -6 * Curves.easeInOut.transform(_float.value)),
          child: child,
        ),
        child: Image.asset(
          VeeAvatar.assetFor(widget.pose),
          fit: BoxFit.contain,
          cacheHeight: 420,
          excludeFromSemantics: true,
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: JuicyTap(
        onTap: widget.onTap,
        semanticLabel: '${widget.title}. ${widget.subtitle}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VeeTokens.cardWhite,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: VeeTokens.shadow,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: picture,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: VeeTokens.textOnLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: VeeTokens.textSecondaryOnLight,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: VeeTokens.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: VeeTokens.textOnDark,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
