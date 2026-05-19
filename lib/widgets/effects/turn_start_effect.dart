import 'package:flutter/material.dart';

class TurnStartEffect extends StatelessWidget {
  const TurnStartEffect({
    super.key,
    required this.visible,
    required this.playerName,
  });

  final bool visible;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFC857);

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.18),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                child: child,
              ),
            ),
          );
        },
        child: visible
            ? Center(
                key: ValueKey(playerName),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.46),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: accentColor.withOpacity(0.78),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.22),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    '$playerNameのターン',
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}