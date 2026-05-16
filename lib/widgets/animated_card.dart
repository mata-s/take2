import 'package:flutter/material.dart';

class AnimatedCardShell extends StatelessWidget {
  const AnimatedCardShell({
    super.key,
    required this.child,
    this.isSelected = false,
    this.offsetY = 0,
  });

  final Widget child;
  final bool isSelected;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      offset: Offset(0, offsetY),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        scale: isSelected ? 1.08 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: 1,
          child: child,
        ),
      ),
    );
  }
}

class DrawnCardAnimation extends StatelessWidget {
  const DrawnCardAnimation({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final safeValue = value.clamp(0.0, 1.0);

        return Opacity(
          opacity: safeValue,
          child: Transform.translate(
            offset: Offset(
              0,
              -70 * (1 - safeValue),
            ),
            child: Transform.scale(
              scale: 0.82 + 0.18 * safeValue,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class PlayedCardAnimation extends StatelessWidget {
  const PlayedCardAnimation({
    super.key,
    required this.child,
    required this.animation,
    this.beginOffset = const Offset(0, 2.75),
    this.stackChildren = const [],
  });

  final Widget child;
  final Animation<double> animation;
  final Offset beginOffset;
  final List<Widget> stackChildren;

  @override
  Widget build(BuildContext context) {
    final moveAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInCubic,
    );

    final popAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(
        0.55,
        1.0,
        curve: Curves.easeOutBack,
      ),
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final isLeaving = animation.status == AnimationStatus.reverse;

        if (isLeaving) {
          return Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          );
        }

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(moveAnimation),
            child: RotationTransition(
              turns: Tween<double>(
                begin: 0.02,
                end: 0,
              ).animate(moveAnimation),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 1.08,
                  end: 1.0,
                ).animate(popAnimation),
                child: _PlayedCardStack(
                  stackChildren: stackChildren,
                  animation: animation,
                  child: child!,
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _PlayedCardStack extends StatelessWidget {
  const _PlayedCardStack({
    required this.stackChildren,
    required this.animation,
    required this.child,
  });

  final List<Widget> stackChildren;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visibleBackCards = stackChildren.take(3).toList();

    if (visibleBackCards.isEmpty) {
      return child;
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value.clamp(0.0, 1.0);
        final spread = 0.45 + progress * 0.55;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < visibleBackCards.length; i++)
              Positioned(
                left: -22.0 * (visibleBackCards.length - i) * spread,
                top: 10.0 * (visibleBackCards.length - i) * spread,
                child: Opacity(
                  opacity: 0.86,
                  child: Transform.rotate(
                    angle: -0.025 * (visibleBackCards.length - i) * spread,
                    child: visibleBackCards[i],
                  ),
                ),
              ),
            child!,
          ],
        );
      },
      child: child,
    );
  }
}
