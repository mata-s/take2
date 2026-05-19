import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import 'animated_card.dart';
import 'playing_card_widget.dart';

class PlayerHandArea extends StatelessWidget {
  const PlayerHandArea({
    super.key,
    required this.hand,
    required this.selectedIndexes,
    required this.canSelect,
    this.playableIndexes = const <int>{},
    required this.onCardTap,
  });

  final List<PlayingCard> hand;
  final Set<int> selectedIndexes;
  final bool canSelect;
  final Set<int> playableIndexes;
  final ValueChanged<int> onCardTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const cardWidth = 72.0;
    const cardHeight = 104.0;
    const areaHeight = 180.0;

    if (hand.isEmpty) {
      return const SizedBox(height: areaHeight);
    }

    final displayIndexes = List<int>.generate(hand.length, (index) => index)
      ..sort((a, b) {
        final rankCompare = hand[a].rank.compareTo(hand[b].rank);
        if (rankCompare != 0) return rankCompare;
        return hand[a].suit.index.compareTo(hand[b].suit.index);
      });

    final count = hand.length;
    final visibleWidth = screenWidth - 24;
    final maxSpread = visibleWidth - cardWidth;
    final baseSpacing = count <= 1
        ? 0.0
        : (maxSpread / (count - 1)).clamp(18.0, 54.0);
    final totalWidth = cardWidth + baseSpacing * (count - 1);
    final startX = (screenWidth - totalWidth) / 2;
    final centerIndex = (count - 1) / 2;

    return SizedBox(
      height: areaHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(count, (index) {
          final originalIndex = displayIndexes[index];
          final card = hand[originalIndex];
          final distanceFromCenter = index - centerIndex;
          final rotate = distanceFromCenter * 0.045;
          final isSelected = selectedIndexes.contains(originalIndex);
          final isPlayable = canSelect && playableIndexes.contains(originalIndex);
          final x = startX + baseSpacing * index;
          final y = 28.0 + distanceFromCenter.abs() * 3 - (isSelected ? 18 : 0);

          return Positioned(
            left: x,
            top: y,
            child: Transform.rotate(
              angle: rotate,
              alignment: Alignment.bottomCenter,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isPlayable && !isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFC857).withOpacity(0.16),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : const [],
                  ),
                  child: AnimatedCardShell(
                    isSelected: isSelected,
                    child: PlayingCardWidget(
                      rank: card.rankLabel,
                      suit: card.suitLabel,
                      isSelected: isSelected,
                      width: cardWidth,
                      height: cardHeight,
                      onTap: canSelect ? () => onCardTap(originalIndex) : null,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}