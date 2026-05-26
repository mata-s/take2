import 'package:cloud_firestore/cloud_firestore.dart';

class OnlinePlayer {
  const OnlinePlayer({
    required this.id,
    required this.name,
    required this.joinedAt,
    required this.isHost,
    required this.isReady,
    required this.seatIndex,
    required this.connected,
  });

  final String id;
  final String name;
  final Timestamp joinedAt;
  final bool isHost;
  final bool isReady;
  final int seatIndex;
  final bool connected;

  factory OnlinePlayer.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return OnlinePlayer(
      id: id,
      name: map['name'] as String? ?? 'プレイヤー',
      joinedAt: map['joinedAt'] as Timestamp? ?? Timestamp.now(),
      isHost: map['isHost'] as bool? ?? false,
      isReady: map['isReady'] as bool? ?? false,
      seatIndex: map['seatIndex'] as int? ?? 0,
      connected: map['connected'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'joinedAt': joinedAt,
      'isHost': isHost,
      'isReady': isReady,
      'seatIndex': seatIndex,
      'connected': connected,
    };
  }

  OnlinePlayer copyWith({
    String? id,
    String? name,
    Timestamp? joinedAt,
    bool? isHost,
    bool? isReady,
    int? seatIndex,
    bool? connected,
  }) {
    return OnlinePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      joinedAt: joinedAt ?? this.joinedAt,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      seatIndex: seatIndex ?? this.seatIndex,
      connected: connected ?? this.connected,
    );
  }
}
