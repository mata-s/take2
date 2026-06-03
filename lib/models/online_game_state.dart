

import 'online_card.dart';

class OnlineGameState {
  const OnlineGameState({
    required this.deck,
    required this.fieldCard,
    required this.currentPlayerUid,
    required this.pendingDrawCount,
    required this.pendingSkipCount,
    required this.forcedSuit,
    required this.started,
    required this.finished,
  });

  final List<OnlineCard> deck;
  final OnlineCard? fieldCard;
  final String? currentPlayerUid;

  final int pendingDrawCount;
  final int pendingSkipCount;

  final String? forcedSuit;

  final bool started;
  final bool finished;

  factory OnlineGameState.initial() {
    return const OnlineGameState(
      deck: [],
      fieldCard: null,
      currentPlayerUid: null,
      pendingDrawCount: 0,
      pendingSkipCount: 0,
      forcedSuit: null,
      started: false,
      finished: false,
    );
  }

  factory OnlineGameState.fromMap(Map<String, dynamic> map) {
    return OnlineGameState(
      deck: ((map['deck'] as List?) ?? [])
          .map((e) => OnlineCard.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      fieldCard: map['fieldCard'] == null
          ? null
          : OnlineCard.fromMap(
              Map<String, dynamic>.from(map['fieldCard'] as Map),
            ),
      currentPlayerUid: map['currentPlayerUid'] as String?,
      pendingDrawCount: map['pendingDrawCount'] as int? ?? 0,
      pendingSkipCount: map['pendingSkipCount'] as int? ?? 0,
      forcedSuit: map['forcedSuit'] as String?,
      started: map['started'] as bool? ?? false,
      finished: map['finished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deck': deck.map((e) => e.toMap()).toList(),
      'fieldCard': fieldCard?.toMap(),
      'currentPlayerUid': currentPlayerUid,
      'pendingDrawCount': pendingDrawCount,
      'pendingSkipCount': pendingSkipCount,
      'forcedSuit': forcedSuit,
      'started': started,
      'finished': finished,
    };
  }

  OnlineGameState copyWith({
    List<OnlineCard>? deck,
    OnlineCard? fieldCard,
    String? currentPlayerUid,
    int? pendingDrawCount,
    int? pendingSkipCount,
    String? forcedSuit,
    bool? started,
    bool? finished,
  }) {
    return OnlineGameState(
      deck: deck ?? this.deck,
      fieldCard: fieldCard ?? this.fieldCard,
      currentPlayerUid: currentPlayerUid ?? this.currentPlayerUid,
      pendingDrawCount: pendingDrawCount ?? this.pendingDrawCount,
      pendingSkipCount: pendingSkipCount ?? this.pendingSkipCount,
      forcedSuit: forcedSuit ?? this.forcedSuit,
      started: started ?? this.started,
      finished: finished ?? this.finished,
    );
  }
}