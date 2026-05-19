import 'package:flutter/material.dart';

class DrawEffect extends StatelessWidget {
  const DrawEffect({
    super.key,
    required this.visible,
    required this.target,
    required this.count,
  });

  final bool visible;
  final DrawEffectTarget target;
  final int count;

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
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
              child: child,
            ),
          );
        },
        child: visible
            ? _DrawEffectBody(
                key: ValueKey('${target.name}-$count'),
                target: target,
                count: count,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

enum DrawEffectTarget {
  self,
  left,
  top,
  right,
}

class _DrawEffectBody extends StatelessWidget {
  const _DrawEffectBody({
    super.key,
    required this.target,
    required this.count,
  });

  final DrawEffectTarget target;
  final int count;

  @override
  Widget build(BuildContext context) {
    final begin = Offset.zero;
    final end = switch (target) {
      DrawEffectTarget.self => const Offset(0, 2.2),
      DrawEffectTarget.left => const Offset(-2.6, -0.2),
      DrawEffectTarget.top => const Offset(0, -2.1),
      DrawEffectTarget.right => const Offset(2.6, -0.2),
    };

    final rotation = switch (target) {
      DrawEffectTarget.self => 0.04,
      DrawEffectTarget.left => -0.12,
      DrawEffectTarget.top => 0.02,
      DrawEffectTarget.right => 0.12,
    };

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final opacity = value < 0.82 ? 1.0 : (1 - value) / 0.18;

          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: SlideTransition(
              position: AlwaysStoppedAnimation(
                Offset.lerp(begin, end, value)!,
              ),
              child: Transform.rotate(
                angle: rotation * value,
                child: Transform.scale(
                  scale: 0.86 + 0.18 * value,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: _DrawCardStack(count: count),
      ),
    );
  }
}

class _DrawCardStack extends StatelessWidget {
  const _DrawCardStack({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final visibleCount = count.clamp(1, 6);
    final centerOffset = (visibleCount - 1) * 5.0;

    return SizedBox(
      width: 54 + (visibleCount - 1) * 10,
      height: 86,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < visibleCount; i++)
            Positioned(
              left: i * 10.0,
              top: (visibleCount - 1 - i) * 1.5,
              child: Transform.rotate(
                angle: (i - centerOffset / 10) * 0.035,
                child: const _DrawCardBack(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawCardBack extends StatelessWidget {
  const _DrawCardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF174E42),
            Color(0xFF0B2F28),
          ],
        ),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 30,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}