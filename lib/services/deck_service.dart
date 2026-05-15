

import 'dart:math';

import '../models/playing_card.dart';

class DeckService {
  static List<PlayingCard> createDeck() {
    final deck = <PlayingCard>[];

    final suits = [
      CardSuit.spade,
      CardSuit.heart,
      CardSuit.diamond,
      CardSuit.club,
    ];

    for (final suit in suits) {
      for (int rank = 1; rank <= 13; rank++) {
        deck.add(
          PlayingCard(
            rank: rank,
            suit: suit,
          ),
        );
      }
    }

    deck.add(
      const PlayingCard(
        rank: 0,
        suit: CardSuit.joker,
      ),
    );

    deck.add(
      const PlayingCard(
        rank: 0,
        suit: CardSuit.joker,
      ),
    );

    return deck;
  }

  static void shuffleDeck(List<PlayingCard> deck) {
    deck.shuffle(Random());
  }

  static PlayingCard drawCard(List<PlayingCard> deck) {
    return deck.removeLast();
  }

  static List<PlayingCard> drawCards(
    List<PlayingCard> deck,
    int count,
  ) {
    final cards = <PlayingCard>[];

    for (int i = 0; i < count; i++) {
      if (deck.isEmpty) break;

      cards.add(drawCard(deck));
    }

    return cards;
  }
}