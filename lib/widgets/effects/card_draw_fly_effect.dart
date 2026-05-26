import 'package:flutter/material.dart';

import '../../models/playing_card.dart';

class CardDrawFlyEffect extends StatefulWidget {
  const CardDrawFlyEffect({
    super.key,
    required this.visible,
    required this.card,
    this.from = const Offset(0.08, 0.42),
    this.to = const Offset(0.50, 0.92),
    this.duration = const Duration(milliseconds: 720),
    this.onCompleted,
  });

  final bool visible;
  final PlayingCard? card;

  /// 0.0〜1.0 の画面比率。山札付近から飛んでくる想定。
  final Offset from;

  /// 0.0〜1.0 の画面比率。自分の手札方向へ吸い込まれる想定。
  final Offset to;

  final Duration duration;
  final VoidCallback? onCompleted;

  @override
  State<CardDrawFlyEffect> createState() => _CardDrawFlyEffectState();
}

class _CardDrawFlyEffectState extends State<CardDrawFlyEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });

    if (widget.visible && widget.card != null) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant CardDrawFlyEffect oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }

    final shouldPlay = widget.visible && widget.card != null;
    final wasPlaying = oldWidget.visible && oldWidget.card != null;

    if (shouldPlay && !wasPlaying) {
      _controller.forward(from: 0);
    }

    if (!shouldPlay && wasPlaying) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    if (!widget.visible || card == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _curve,
            builder: (context, child) {
              final t = _curve.value;
              final start = Offset(
                constraints.maxWidth * widget.from.dx,
                constraints.maxHeight * widget.from.dy,
              );
              final end = Offset(
                constraints.maxWidth * widget.to.dx,
                constraints.maxHeight * widget.to.dy,
              );

              final control = Offset(
                constraints.maxWidth * 0.40,
                constraints.maxHeight * 0.52,
              );

              final position = _quadraticBezier(start, control, end, t);
              final scale = 1.0 - (t * 0.22);
              final opacity = t < 0.86 ? 1.0 : (1.0 - t) / 0.14;
              final rotation = -0.22 + (t * 0.34);

              return Stack(
                children: [
                  Positioned(
                    left: position.dx - 34,
                    top: position.dy - 48,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(
                          scale: scale,
                          child: _FlyingCard(card: card),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final oneMinusT = 1 - t;
    return Offset(
      oneMinusT * oneMinusT * p0.dx +
          2 * oneMinusT * t * p1.dx +
          t * t * p2.dx,
      oneMinusT * oneMinusT * p0.dy +
          2 * oneMinusT * t * p1.dy +
          t * t * p2.dy,
    );
  }
}

class _FlyingCard extends StatelessWidget {
  const _FlyingCard({required this.card});

  final PlayingCard card;

  String get rankLabel {
    if (card.isJoker) return 'JOKER';

    return switch (card.rank) {
      1 => 'A',
      11 => 'J',
      12 => 'Q',
      13 => 'K',
      _ => '${card.rank}',
    };
  }

  String get suitLabel {
    if (card.isJoker) return '★';

    return switch (card.suit.name) {
      'spade' => '♠',
      'heart' => '♥',
      'diamond' => '♦',
      'club' => '♣',
      _ => card.suit.name,
    };
  }

  Color get textColor {
    final suitName = card.suit.name;
    if (card.isJoker) return const Color(0xFF111111);
    if (suitName == 'heart' || suitName == 'diamond') {
      return const Color(0xFFD93838);
    }
    return const Color(0xFF111111);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: card.isJoker
            ? Text(
                rankLabel,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rankLabel,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suitLabel,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}