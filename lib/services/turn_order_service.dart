import '../models/playing_card.dart';

class TurnOrderEntry {
  const TurnOrderEntry({
    required this.playerIndex,
    required this.playerName,
    required this.guessedNumber,
    required this.answeredAtMs,
  });

  final int playerIndex;
  final String playerName;
  final int guessedNumber;
  final int answeredAtMs;
}

class TurnOrderRankedEntry {
  const TurnOrderRankedEntry({
    required this.playerIndex,
    required this.playerName,
    required this.guessedNumber,
    required this.answeredAtMs,
    required this.difference,
  });

  final int playerIndex;
  final String playerName;
  final int guessedNumber;
  final int answeredAtMs;
  final int difference;
}

class TurnOrderResult {
  const TurnOrderResult({
    required this.targetCard,
    required this.targetNumber,
    required this.rankedEntries,
  });

  final PlayingCard targetCard;
  final int targetNumber;
  final List<TurnOrderRankedEntry> rankedEntries;

  List<int> get orderedPlayerIndexes =>
      rankedEntries.map((entry) => entry.playerIndex).toList();
}

class TurnOrderService {
  const TurnOrderService._();

  static int cardNumber(PlayingCard card) {
    if (card.isJoker) return 14;
    return card.rank;
  }

  static TurnOrderResult determineOrder({
    required PlayingCard targetCard,
    required List<TurnOrderEntry> entries,
  }) {
    final targetNumber = cardNumber(targetCard);

    final rankedEntries = entries.map((entry) {
      return TurnOrderRankedEntry(
        playerIndex: entry.playerIndex,
        playerName: entry.playerName,
        guessedNumber: entry.guessedNumber,
        answeredAtMs: entry.answeredAtMs,
        difference: (entry.guessedNumber - targetNumber).abs(),
      );
    }).toList()
      ..sort((a, b) {
        final differenceCompare = a.difference.compareTo(b.difference);
        if (differenceCompare != 0) return differenceCompare;

        final speedCompare = a.answeredAtMs.compareTo(b.answeredAtMs);
        if (speedCompare != 0) return speedCompare;

        return a.playerIndex.compareTo(b.playerIndex);
      });

    return TurnOrderResult(
      targetCard: targetCard,
      targetNumber: targetNumber,
      rankedEntries: rankedEntries,
    );
  }
}