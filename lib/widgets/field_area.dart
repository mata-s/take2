import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import 'animated_card.dart';
import 'playing_card_widget.dart';

class FieldArea extends StatelessWidget {
  const FieldArea({
    super.key,
    required this.fieldCard,
    required this.deckCount,
    this.playedCardBeginOffset = const Offset(0, 2.75),
    this.playedCards = const [],
  });

  final PlayingCard? fieldCard;
  final int deckCount;
  final Offset playedCardBeginOffset;
  final List<PlayingCard> playedCards;

  @override
  Widget build(BuildContext context) {
    final visiblePlayedCards = playedCards.isEmpty && fieldCard != null
        ? [fieldCard!]
        : playedCards;

    final topVisibleCard = visiblePlayedCards.isNotEmpty
        ? visiblePlayedCards.last
        : fieldCard;

    final backVisibleCards = visiblePlayedCards.length <= 1
        ? <PlayingCard>[]
        : visiblePlayedCards.sublist(0, visiblePlayedCards.length - 1);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (topVisibleCard != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.linear,
              switchOutCurve: Curves.linear,
              transitionBuilder: (child, animation) {
                return PlayedCardAnimation(
                  animation: animation,
                  beginOffset: playedCardBeginOffset,
                  stackChildren: backVisibleCards
                      .map(
                        (card) => PlayingCardWidget(
                          rank: card.rankLabel,
                          suit: card.suitLabel,
                        ),
                      )
                      .toList(),
                  child: child,
                );
              },
              child: AnimatedCardShell(
                key: ValueKey(
                  visiblePlayedCards
                      .map((card) => '${card.rankLabel}-${card.suitLabel}')
                      .join('|'),
                ),
                child: PlayingCardWidget(
                  rank: topVisibleCard.rankLabel,
                  suit: topVisibleCard.suitLabel,
                ),
              ),
            ),
          const SizedBox(width: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.86,
                      end: 1.0,
                    ).animate(animation),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.16),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: PlayingCardWidget(
                  key: ValueKey(deckCount),
                  rank: '',
                  suit: '',
                  isBack: true,
                ),
              ),
              Positioned(
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      '$deckCount',
                      key: ValueKey('deck-count-$deckCount'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}