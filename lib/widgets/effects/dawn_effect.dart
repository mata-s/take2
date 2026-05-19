import 'package:flutter/material.dart';

class DawnEffect extends StatelessWidget {
  const DawnEffect({
    super.key,
    required this.visible,
    required this.isHikiDawn,
    required this.fromPlayerName,
    required this.toPlayerName,
  });

  final bool visible;
  final bool isHikiDawn;
  final String fromPlayerName;
  final String toPlayerName;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isHikiDawn ? const Color(0xFF9B5CFF) : const Color(0xFFFF5A5F);

    final label = isHikiDawn ? '引きどん！' : 'ドーン！';

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.82, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: child,
            ),
          );
        },
        child: visible
            ? Container(
                key: ValueKey(label),
                color: Colors.black.withOpacity(0.28),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 34,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: accentColor.withOpacity(0.9),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.38),
                          blurRadius: 28,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fromPlayerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: accentColor,
                                size: 24,
                              ),
                            ),
                            Text(
                              toPlayerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
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