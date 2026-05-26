import 'package:flutter/material.dart';

import '../models/player_state.dart';

class OpponentArea extends StatelessWidget {
  const OpponentArea({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    required this.finishOrder,
    required this.finishPlaces,
  });

  final List<PlayerState> players;
  final int currentPlayerIndex;
  final List<String> finishOrder;
  final Map<String, int> finishPlaces;

  @override
  Widget build(BuildContext context) {
    if (players.length <= 1) {
      return const SizedBox(height: 150);
    }

    final opponentCount = players.length - 1;

    return SizedBox(
      height: 212,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (opponentCount == 1)
            Positioned(
              top: -36,
              child: _OpponentHandView(
                player: players[1],
                isTurn: currentPlayerIndex == 1,
                direction: _OpponentDirection.top,
                finishOrder: finishOrder,
                finishPlaces: finishPlaces,
              ),
            ),

          if (opponentCount == 2) ...[
            Positioned(
              left: -102,
              top: 48,
              child: _OpponentHandView(
                player: players[1],
                isTurn: currentPlayerIndex == 1,
                direction: _OpponentDirection.left,
                finishOrder: finishOrder,
                finishPlaces: finishPlaces,
              ),
            ),
            Positioned(
              right: -102,
              top: 48,
              child: _OpponentHandView(
                player: players[2],
                isTurn: currentPlayerIndex == 2,
                direction: _OpponentDirection.right,
                finishOrder: finishOrder,
                finishPlaces: finishPlaces,
              ),
            ),
          ],

          if (opponentCount >= 3) ...[
            Positioned(
              top: -66,
              child: _OpponentHandView(
                player: players[2],
                isTurn: currentPlayerIndex == 2,
                direction: _OpponentDirection.top,
                finishOrder: finishOrder,
                finishPlaces: finishPlaces,
              ),
            ),
            Positioned(
              left: -102,
              top: 48,
              child: _OpponentHandView(
                player: players[1],
                isTurn: currentPlayerIndex == 1,
                direction: _OpponentDirection.left,
                finishOrder: finishOrder,
                finishPlaces: finishPlaces,
              ),
            ),
            Positioned(
              right: -102,
              top: 48,
              child: _OpponentHandView(
                player: players[3],
                isTurn: currentPlayerIndex == 3,
                direction: _OpponentDirection.right,
                finishOrder: finishOrder,
                finishPlaces: finishPlaces,
              ),
            ),
          ],
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
    required this.finishOrder,
    required this.finishPlaces,
  });

  final PlayerState player;
  final bool isTurn;
  final _OpponentDirection direction;
  final List<String> finishOrder;
  final Map<String, int> finishPlaces;

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
              finishOrder: finishOrder,
              finishPlaces: finishPlaces,
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
    required this.finishOrder,
    required this.finishPlaces,
  });

  final PlayerState player;
  final bool isTurn;
  final List<String> finishOrder;
  final Map<String, int> finishPlaces;

  @override
  Widget build(BuildContext context) {
    final finishedPlace = finishPlaces[player.name];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${player.name} ・ ${player.hand.length}枚',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isTurn ? const Color(0xFFFFC857) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 18,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: player.hasFinished
                  ? _OpponentStatusText(
                      key: ValueKey('finished-${finishedPlace ?? 0}'),
                      label: finishedPlace == null ? '上がり' : '$finishedPlace位',
                      color: const Color(0xFFFFC857),
                    )
                  : player.isReach
                      ? const _OpponentStatusText(
                          key: ValueKey('reach'),
                          label: 'リーチ中',
                          color: Color(0xFFFFC857),
                        )
                      : const SizedBox(
                          key: ValueKey('normal'),
                          height: 0,
                        ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OpponentStatusText extends StatelessWidget {
  const _OpponentStatusText({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            color: color.withOpacity(0.45),
            blurRadius: 8,
          ),
        ],
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
      return const SizedBox.shrink();
    }

    // 相手の手札は中身を見せず、裏向きの束として表現する。
    // 見た目は最大7枚までに抑える。
    final visibleCount = count <= 0 ? 0 : count.clamp(1, 7);
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
      width: isSide ? 250 : 360,
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
      _OpponentDirection.top => Offset(distance * 15, distance.abs() * 2.0),
      _OpponentDirection.left => Offset(distance.abs() * 1.4, distance * 11),
      _OpponentDirection.right => Offset(-distance.abs() * 1.4, distance * 11),
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