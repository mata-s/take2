import 'package:flutter/material.dart';

class FinishEffect extends StatelessWidget {
  const FinishEffect({
    super.key,
    required this.visible,
    required this.playerName,
    required this.place,
  });

  final bool visible;
  final String playerName;
  final int place;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFC857);

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutExpo,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            ),
          );
        },
        child: visible
            ? Container(
                key: ValueKey(playerName),
                color: accentColor.withOpacity(0.16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 34,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.92),
                          accentColor.withOpacity(0.24),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: accentColor.withOpacity(0.95),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.52),
                          blurRadius: 28,
                          spreadRadius: 7,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          playerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '上がり！ $place位',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                            shadows: [
                              Shadow(
                                 color: accentColor.withOpacity(0.85),
                                blurRadius: 26,
                              ),
                              Shadow(
                                color: Colors.white.withOpacity(0.24),
                                blurRadius: 12,
                              ),
                            ],
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