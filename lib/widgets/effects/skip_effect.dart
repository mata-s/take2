import 'package:flutter/material.dart';

class SkipEffect extends StatelessWidget {
  const SkipEffect({
    super.key,
    required this.visible,
    required this.playerName,
  });

  final bool visible;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFF8A3D);

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
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
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.22, 0),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.82, end: 1).animate(curved),
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
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.58),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: accentColor.withOpacity(0.86),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.34),
                        blurRadius: 26,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$playerName ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const TextSpan(
                          text: 'スキップ！',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}