

import 'package:cloud_firestore/cloud_firestore.dart';

class OnlineRoom {
  const OnlineRoom({
    required this.id,
    required this.hostPlayerId,
    required this.playerIds,
    required this.createdAt,
    required this.status,
    required this.maxPlayers,
    required this.currentTurnPlayerId,
    required this.started,
  });

  final String id;
  final String hostPlayerId;
  final List<String> playerIds;
  final Timestamp createdAt;

  /// waiting / playing / finished
  final String status;

  final int maxPlayers;
  final String? currentTurnPlayerId;
  final bool started;

  bool get isFull => playerIds.length >= maxPlayers;

  factory OnlineRoom.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return OnlineRoom(
      id: id,
      hostPlayerId: map['hostPlayerId'] as String? ?? '',
      playerIds: List<String>.from(map['playerIds'] ?? const []),
      createdAt:
          map['createdAt'] as Timestamp? ?? Timestamp.now(),
      status: map['status'] as String? ?? 'waiting',
      maxPlayers: map['maxPlayers'] as int? ?? 4,
      currentTurnPlayerId:
          map['currentTurnPlayerId'] as String?,
      started: map['started'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostPlayerId': hostPlayerId,
      'playerIds': playerIds,
      'createdAt': createdAt,
      'status': status,
      'maxPlayers': maxPlayers,
      'currentTurnPlayerId': currentTurnPlayerId,
      'started': started,
    };
  }

  OnlineRoom copyWith({
    String? id,
    String? hostPlayerId,
    List<String>? playerIds,
    Timestamp? createdAt,
    String? status,
    int? maxPlayers,
    String? currentTurnPlayerId,
    bool? started,
  }) {
    return OnlineRoom(
      id: id ?? this.id,
      hostPlayerId:
          hostPlayerId ?? this.hostPlayerId,
      playerIds: playerIds ?? this.playerIds,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      currentTurnPlayerId:
          currentTurnPlayerId ?? this.currentTurnPlayerId,
      started: started ?? this.started,
    );
  }
}