import 'package:flutter/material.dart';

class ReachBanner extends StatelessWidget {
  const ReachBanner({
    super.key,
    required this.playerName,
    required this.visible,
  });

  final String playerName;
  final bool visible;

  @override
  Widget build(BuildContext context) {
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
                begin: const Offset(-0.35, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        child: visible
            ? _ReachBannerBody(
                key: ValueKey(playerName),
                playerName: playerName,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _ReachBannerBody extends StatelessWidget {
  const _ReachBannerBody({
    super.key,
    required this.playerName,
  });

  final String playerName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFFFC857).withOpacity(0.8),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC857).withOpacity(0.22),
              blurRadius: 24,
              spreadRadius: 2,
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
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const TextSpan(
                text: 'リーチ！',
                style: TextStyle(
                  color: Color(0xFFFFC857),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
