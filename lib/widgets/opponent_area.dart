import 'package:flutter/material.dart';

import '../models/player_state.dart';

class OpponentArea extends StatelessWidget {
  const OpponentArea({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
  });

  final List<PlayerState> players;
  final int currentPlayerIndex;

  @override
  Widget build(BuildContext context) {
    if (players.length < 4) {
      return const SizedBox(height: 150);
    }

    final leftPlayer = players[1];
    final topPlayer = players[2];
    final rightPlayer = players[3];

    return SizedBox(
      height: 212,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -66,
            child: _OpponentHandView(
              player: topPlayer,
              isTurn: currentPlayerIndex == 2,
              direction: _OpponentDirection.top,
            ),
          ),
          Positioned(
            left: -102,
            top: 48,
            child: _OpponentHandView(
              player: leftPlayer,
              isTurn: currentPlayerIndex == 1,
              direction: _OpponentDirection.left,
            ),
          ),
          Positioned(
            right: -102,
            top: 48,
            child: _OpponentHandView(
              player: rightPlayer,
              isTurn: currentPlayerIndex == 3,
              direction: _OpponentDirection.right,
            ),
          ),
        ],
      ),
    );
  }
}

enum _OpponentDirection { left, top, right }

class _OpponentHandView extends StatelessWidget {
  const _OpponentHandView({
    required this.player,
    required this.isTurn,
    required this.direction,
  });

  final PlayerState player;
  final bool isTurn;
  final _OpponentDirection direction;

  @override
  Widget build(BuildContext context) {
    final isSide = direction != _OpponentDirection.top;
    final labelOffset = switch (direction) {
      _OpponentDirection.left => const Offset(82, 0),
      _OpponentDirection.top => const Offset(0, 82),
      _OpponentDirection.right => const Offset(-82, 0),
    };

    return SizedBox(
      width: isSide ? 240 : 320,
      height: isSide ? 164 : 160,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isTurn)
            Container(
              width: isSide ? 190 : 260,
              height: isSide ? 150 : 132,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC857).withOpacity(0.34),
                    blurRadius: 28,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.88,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _OpponentCardFan(
              key: ValueKey(
                '${player.name}-${player.hand.length}-${player.hasFinished}',
              ),
              count: player.hand.length,
              isFinished: player.hasFinished,
              direction: direction,
            ),
          ),
          Transform.translate(
            offset: labelOffset,
            child: _OpponentLabel(
              player: player,
              isTurn: isTurn,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentLabel extends StatelessWidget {
  const _OpponentLabel({
    required this.player,
    required this.isTurn,
  });

  final PlayerState player;
  final bool isTurn;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isTurn ? const Color(0xFFFFC857) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.vertical,
                    child: child,
                  ),
                );
              },
              child: player.hasFinished
                  ? const SizedBox(
                      key: ValueKey('finished'),
                      height: 0,
                    )
                  : player.isReach
                      ? const Text(
                          'リーチ',
                          key: ValueKey('reach'),
                          style: TextStyle(
                            color: Color(0xFFFFC857),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('normal'),
                          height: 0,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpponentCardFan extends StatelessWidget {
  const _OpponentCardFan({
    super.key,
    required this.count,
    required this.isFinished,
    required this.direction,
  });

  final int count;
  final bool isFinished;
  final _OpponentDirection direction;

  @override
  Widget build(BuildContext context) {
    if (isFinished) {
      return const _FinishedBadge();
    }

    // 相手の手札は中身を見せず、裏向きの束としてだけ表現する。
    // 実際の枚数はラベルで表示し、カード束は最大5枚までにする。
    final visibleCount = count <= 0 ? 0 : count.clamp(1, 5);
    if (visibleCount == 0) {
      return const SizedBox.shrink();
    }

    final isSide = direction != _OpponentDirection.top;
    final cardWidth = isSide ? 34.0 : 42.0;
    final cardHeight = isSide ? 54.0 : 64.0;
    final center = (visibleCount - 1) / 2;

    final baseRotation = switch (direction) {
      _OpponentDirection.left => -1.48,
      _OpponentDirection.top => 3.14159,
      _OpponentDirection.right => 1.48,
    };

    return SizedBox(
      width: isSide ? 220 : 320,
      height: isSide ? 164 : 160,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < visibleCount; i++)
            _OpponentBackCard(
              width: cardWidth,
              height: cardHeight,
              index: i,
              center: center,
              baseRotation: baseRotation,
              direction: direction,
            ),
        ],
      ),
    );
  }
}

class _FinishedBadge extends StatelessWidget {
  const _FinishedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC857).withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFC857).withOpacity(0.9),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC857).withOpacity(0.22),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Text(
        '上がり',
        style: TextStyle(
          color: Color(0xFFFFC857),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OpponentBackCard extends StatelessWidget {
  const _OpponentBackCard({
    required this.width,
    required this.height,
    required this.index,
    required this.center,
    required this.baseRotation,
    required this.direction,
  });

  final double width;
  final double height;
  final int index;
  final double center;
  final double baseRotation;
  final _OpponentDirection direction;

  @override
  Widget build(BuildContext context) {
    final distance = index - center;
    final fanRotation = distance * 0.042;

    final offset = switch (direction) {
      _OpponentDirection.top => Offset(distance * 18, distance.abs() * 2.2),
      _OpponentDirection.left => Offset(distance.abs() * 1.8, distance * 14),
      _OpponentDirection.right => Offset(-distance.abs() * 1.8, distance * 14),
    };

    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: baseRotation + fanRotation,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF9E2F2A),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.white.withOpacity(0.82),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: Colors.white.withOpacity(0.46),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}