

import 'online_card.dart';

class OnlineGamePlayer {
  const OnlineGamePlayer({
    required this.uid,
    required this.name,
    required this.hand,
    required this.isReach,
    required this.hasFinished,
    required this.rank,
    required this.seatIndex,
    required this.isCpu,
  });

  final String uid;
  final String name;

  final List<OnlineCard> hand;

  final bool isReach;
  final bool hasFinished;

  final int? rank;
  final int seatIndex;

  final bool isCpu;

  factory OnlineGamePlayer.fromMap(Map<String, dynamic> map) {
    return OnlineGamePlayer(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? 'プレイヤー',
      hand: ((map['hand'] as List?) ?? [])
          .map((e) => OnlineCard.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isReach: map['isReach'] as bool? ?? false,
      hasFinished: map['hasFinished'] as bool? ?? false,
      rank: map['rank'] as int?,
      seatIndex: map['seatIndex'] as int? ?? 0,
      isCpu: map['isCpu'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'hand': hand.map((e) => e.toMap()).toList(),
      'isReach': isReach,
      'hasFinished': hasFinished,
      'rank': rank,
      'seatIndex': seatIndex,
      'isCpu': isCpu,
    };
  }

  OnlineGamePlayer copyWith({
    String? uid,
    String? name,
    List<OnlineCard>? hand,
    bool? isReach,
    bool? hasFinished,
    int? rank,
    int? seatIndex,
    bool? isCpu,
  }) {
    return OnlineGamePlayer(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      isReach: isReach ?? this.isReach,
      hasFinished: hasFinished ?? this.hasFinished,
      rank: rank ?? this.rank,
      seatIndex: seatIndex ?? this.seatIndex,
      isCpu: isCpu ?? this.isCpu,
    );
  }
}