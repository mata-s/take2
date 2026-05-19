import 'package:flutter/material.dart';

class SuitChangeEffect extends StatelessWidget {
  const SuitChangeEffect({
    super.key,
    required this.visible,
    required this.suitLabel,
    required this.suitColor,
  });

  final bool visible;
  final String suitLabel;
  final Color suitColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.55, end: 1.0).animate(curved),
              child: RotationTransition(
                turns: Tween<double>(begin: -0.04, end: 0).animate(curved),
                child: child,
              ),
            ),
          );
        },
        child: visible
            ? _SuitChangeBody(
                key: ValueKey(suitLabel),
                suitLabel: suitLabel,
                suitColor: suitColor,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _SuitChangeBody extends StatelessWidget {
  const _SuitChangeBody({
    super.key,
    required this.suitLabel,
    required this.suitColor,
  });

  final String suitLabel;
  final Color suitColor;

  @override
  Widget build(BuildContext context) {
    final isDarkSuit = suitColor.computeLuminance() < 0.2;
    final effectiveColor = isDarkSuit
        ? const Color(0xFFF5F5F5)
        : suitColor;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.52),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: effectiveColor.withOpacity(0.95),
            width: 2.4,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withOpacity(0.42),
              blurRadius: 34,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              suitLabel,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 92,
                fontWeight: FontWeight.w900,
                height: 0.9,
                shadows: [
                  Shadow(
                    color: effectiveColor.withOpacity(0.75),
                    blurRadius: 24,
                  ),
                  Shadow(
                    color: Colors.white.withOpacity(0.24),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'マーク変更！',
              style: TextStyle(
                color: effectiveColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: effectiveColor.withOpacity(0.55),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}