

import '../models/playing_card.dart';

class RuleService {
  const RuleService._();

  static bool canPlayCard({
    required PlayingCard card,
    required PlayingCard? fieldCard,
  }) {
    if (fieldCard == null) return true;

    if (card.isJoker) return true;
    if (card.rank == 8) return true;
    if (fieldCard.isJoker) return true;

    return card.rank == fieldCard.rank || card.suit == fieldCard.suit;
  }

  static bool canPlayCards({
    required List<PlayingCard> cards,
    required PlayingCard? fieldCard,
  }) {
    if (cards.isEmpty) return false;
    if (!hasSameRank(cards)) return false;

    return canPlayCard(
      card: cards.first,
      fieldCard: fieldCard,
    );
  }

  static bool isDrawPenaltyCard(PlayingCard card) {
    return card.rank == 2 || card.isJoker;
  }

  static int drawPenaltyCount(PlayingCard card) {
    if (card.isJoker) return 4;
    if (card.rank == 2) return 2;
    return 0;
  }

  static bool canRespondToDrawPenalty(PlayingCard card) {
    return isDrawPenaltyCard(card);
  }

  static bool hasSameRank(List<PlayingCard> cards) {
    if (cards.isEmpty) return false;

    final firstRank = cards.first.rank;
    return cards.every((card) => card.rank == firstRank);
  }

  static bool isForbiddenFinishCard(PlayingCard card) {
    return card.rank == 8 || card.isJoker;
  }

  static bool isForbiddenFinish({
    required List<PlayingCard> playedCards,
    required int handLength,
  }) {
    if (playedCards.isEmpty) return false;

    final willFinish = playedCards.length == handLength;
    if (!willFinish) return false;

    return isForbiddenFinishCard(playedCards.first);
  }
  static bool shouldRecycleDeck({
    required int deckLength,
    required int discardPileLength,
  }) {
    return deckLength == 0 && discardPileLength > 1;
  }

  static bool canRecycleDiscardPile(int discardPileLength) {
    return discardPileLength > 1;
  }
}