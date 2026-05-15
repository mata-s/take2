enum CardSuit {
  spade,
  heart,
  diamond,
  club,
  joker,
}

class PlayingCard {
  const PlayingCard({
    required this.rank,
    required this.suit,
  });

  final int rank;
  final CardSuit suit;

  bool get isJoker => suit == CardSuit.joker;

  String get rankLabel {
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      case 0:
        return 'JOKER';
      default:
        return rank.toString();
    }
  }

  String get suitLabel {
    switch (suit) {
      case CardSuit.spade:
        return '♠';
      case CardSuit.heart:
        return '♥';
      case CardSuit.diamond:
        return '♦';
      case CardSuit.club:
        return '♣';
      case CardSuit.joker:
        return '★';
    }
  }

  int get reachValue {
    if (isJoker) return 0;
    return rank;
  }
}