import '../models/playing_card.dart';

class RuleService {
  const RuleService._();

  static bool canPlayCard({
    required PlayingCard card,
    required PlayingCard? fieldCard,
    CardSuit? forcedSuit,
  }) {
    if (fieldCard == null) return true;

    if (card.isJoker) return true;
    if (card.rank == 8) return true;

    if (forcedSuit != null) {
      return card.suit == forcedSuit;
    }

    if (fieldCard.isJoker) return true;

    return card.rank == fieldCard.rank || card.suit == fieldCard.suit;
  }

  static bool canPlayCards({
    required List<PlayingCard> cards,
    required PlayingCard? fieldCard,
    CardSuit? forcedSuit,
  }) {
    if (cards.isEmpty) return false;
    if (!hasSameRank(cards)) return false;

    final hasJoker = cards.any((card) => card.isJoker);
    if (hasJoker) {
      // Jokerを含む複数枚出しでは、Jokerが場札に合わせたカードに化けられる。
      // 例: 場が4♦、手札がJoker + 7♠ の場合、Jokerを7♦として扱える。
      return true;
    }

    final baseCard = cards.first;

    return canPlayCard(
      card: baseCard,
      fieldCard: fieldCard,
      forcedSuit: forcedSuit,
    );
  }

  static bool hasPlayableCard({
    required List<PlayingCard> hand,
    required PlayingCard? fieldCard,
    CardSuit? forcedSuit,
    int pendingDrawCount = 0,
  }) {
    if (hand.isEmpty) return false;

    if (pendingDrawCount > 0) {
      return hand.any(canRespondToDrawPenalty);
    }

    return hand.any(
      (card) => canPlayCard(
        card: card,
        fieldCard: fieldCard,
        forcedSuit: forcedSuit,
      ),
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

  static int drawPenaltyCountForPlay(List<PlayingCard> cards) {
    if (cards.isEmpty) return 0;

    // Joker単体は +4。
    // Jokerを他のカードと重ねて出す場合はワイルドカード扱いで +4なし。
    final nonJokerCards = cards.where((card) => !card.isJoker).toList();
    if (nonJokerCards.isEmpty) {
      return cards.length * 4;
    }

    final baseCard = nonJokerCards.first;
    if (baseCard.rank == 2) {
      return nonJokerCards.length * 2;
    }

    return 0;
  }

  static bool canRespondToDrawPenalty(PlayingCard card) {
    return isDrawPenaltyCard(card);
  }

  static bool hasSameRank(List<PlayingCard> cards) {
    if (cards.isEmpty) return false;

    final baseCard = cards.firstWhere(
      (card) => !card.isJoker,
      orElse: () => cards.first,
    );

    if (baseCard.isJoker) return true;

    return cards.every((card) => card.isJoker || card.rank == baseCard.rank);
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

  static int handTotal(List<PlayingCard> hand) {
    return hand.fold<int>(
      0,
      (total, card) => total + (card.isJoker ? 1 : card.reachValue),
    );
  }

  static bool canReach(List<PlayingCard> hand) {
    return hand.length >= 2 && handTotal(hand) <= 13;
  }

  static bool canDawn({
    required List<PlayingCard> hand,
    required PlayingCard playedCard,
    required bool hasDeclaredReach,
  }) {
    if (!hasDeclaredReach) return false;
    if (playedCard.isJoker) return false;

    final jokerCount = hand.where((card) => card.isJoker).length;
    final totalWithoutJoker = handTotal(hand);
    final target = playedCard.rank;

    // Jokerは好きな数字として扱える
    // 例: 1 + 5 + 3 + Joker
    // => 9 + Joker なので 10〜13 を作れる
    for (int value = 1; value <= 13; value++) {
      final possibleTotal = totalWithoutJoker + value * jokerCount;
      if (possibleTotal == target) {
        return true;
      }
    }

    return jokerCount == 0 && totalWithoutJoker == target;
  }

  static bool isSkipCard(PlayingCard card) {
    return card.rank == 1;
  }

  static bool isSuitChangeCard(PlayingCard card) {
    return card.rank == 8 || card.isJoker;
  }
}