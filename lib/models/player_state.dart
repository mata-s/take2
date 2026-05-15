import 'playing_card.dart';

class PlayerState {
  PlayerState({
    required this.name,
    required this.hand,
    this.isReach = false,
    this.hasFinished = false,
  });

  final String name;
  final List<PlayingCard> hand;
  bool isReach;
  bool hasFinished;

  int get handTotal {
    return hand.fold<int>(0, (total, card) => total + card.reachValue);
  }

  bool get canReach {
    return hand.isNotEmpty && handTotal <= 13;
  }
}
