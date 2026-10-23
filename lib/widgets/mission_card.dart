import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

class MissionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String asset;
  final Color color;
  final VoidCallback onTap;
  final String icon;

  const MissionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.color,
    required this.onTap,
    this.icon = '✦',
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hover = true),
    onExit: (_) => setState(() => hover = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, hover ? -4 : 0, 0),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: VeeTokens.shadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Image.asset(
                      widget.asset,
                      fit: BoxFit.contain,
                      height: 170,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: VeeTokens.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        widget.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: VeeTokens.textOnLight,
              ),
            ),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: VeeTokens.textSecondaryOnLight,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
