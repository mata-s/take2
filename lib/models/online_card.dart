class OnlineCard {
  const OnlineCard({
    required this.suit,
    required this.rank,
  });

  final String suit;
  final String rank;

  factory OnlineCard.fromMap(Map<String, dynamic> map) {
    return OnlineCard(
      suit: map['suit'] as String? ?? '',
      rank: map['rank'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'suit': suit,
      'rank': rank,
    };
  }

  OnlineCard copyWith({
    String? suit,
    String? rank,
  }) {
    return OnlineCard(
      suit: suit ?? this.suit,
      rank: rank ?? this.rank,
    );
  }

  @override
  String toString() => '$suit-$rank';

  @override
  bool operator ==(Object other) {
    return other is OnlineCard &&
        other.suit == suit &&
        other.rank == rank;
  }

  @override
  int get hashCode => Object.hash(suit, rank);
}
