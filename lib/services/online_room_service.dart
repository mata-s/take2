import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/online_player.dart';
import '../models/online_room.dart';

class OnlineRoomService {
  OnlineRoomService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');

  Future<User> _currentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) return currentUser;

    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  Stream<OnlineRoom?> watchRoom(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return OnlineRoom.fromMap(snapshot.id, data);
    });
  }

  Stream<List<OnlinePlayer>> watchPlayers(String roomId) {
    return _roomsRef
        .doc(roomId)
        .collection('players')
        .orderBy('seatIndex')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OnlinePlayer.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<String> createRoom({
    required String playerName,
    int maxPlayers = 4,
    bool fillWithCpu = true,
  }) async {
    final user = await _currentUser();
    final roomId = await _generateUniqueRoomId();
    final roomRef = _roomsRef.doc(roomId);
    final playerRef = roomRef.collection('players').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      transaction.set(roomRef, {
        'hostPlayerId': user.uid,
        'playerIds': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'maxPlayers': maxPlayers.clamp(2, 4),
        'fillWithCpu': fillWithCpu,
        'currentTurnPlayerId': null,
        'started': false,
      });

      transaction.set(playerRef, {
        'name': playerName.trim().isEmpty ? 'ホスト' : playerName.trim(),
        'joinedAt': FieldValue.serverTimestamp(),
        'isHost': true,
        'isReady': true,
        'seatIndex': 0,
        'connected': true,
      });
    });

    return roomId;
  }

  Future<void> joinRoom({
    required String roomId,
    required String playerName,
  }) async {
    final user = await _currentUser();
    final normalizedRoomId = roomId.trim().toUpperCase();
    final roomRef = _roomsRef.doc(normalizedRoomId);
    final playerRef = roomRef.collection('players').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      final roomData = roomSnapshot.data();

      if (!roomSnapshot.exists || roomData == null) {
        throw Exception('ルームが見つかりません');
      }

      final room = OnlineRoom.fromMap(roomSnapshot.id, roomData);
      if (room.started || room.status != 'waiting') {
        throw Exception('このルームはすでに開始されています');
      }

      final playerIds = List<String>.from(room.playerIds);
      final isAlreadyJoined = playerIds.contains(user.uid);

      if (!isAlreadyJoined && playerIds.length >= room.maxPlayers) {
        throw Exception('このルームは満員です');
      }

      if (!isAlreadyJoined) {
        playerIds.add(user.uid);
      }

      transaction.update(roomRef, {
        'playerIds': playerIds,
      });

      transaction.set(playerRef, {
        'name': playerName.trim().isEmpty ? 'プレイヤー' : playerName.trim(),
        'joinedAt': FieldValue.serverTimestamp(),
        'isHost': room.hostPlayerId == user.uid,
        'isReady': false,
        'seatIndex': playerIds.indexOf(user.uid),
        'connected': true,
      }, SetOptions(merge: true));
    });
  }

  Future<void> setReady({
    required String roomId,
    required bool isReady,
  }) async {
    final user = await _currentUser();

    await _roomsRef
        .doc(roomId.trim().toUpperCase())
        .collection('players')
        .doc(user.uid)
        .set({
      'isReady': isReady,
      'connected': true,
    }, SetOptions(merge: true));
  }

  Future<void> leaveRoom(String roomId) async {
    final user = await _currentUser();
    final normalizedRoomId = roomId.trim().toUpperCase();
    final roomRef = _roomsRef.doc(normalizedRoomId);
    final playerRef = roomRef.collection('players').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      final roomData = roomSnapshot.data();

      if (!roomSnapshot.exists || roomData == null) return;

      final room = OnlineRoom.fromMap(roomSnapshot.id, roomData);
      final playerIds = List<String>.from(room.playerIds)
        ..remove(user.uid);

      transaction.delete(playerRef);

      if (playerIds.isEmpty) {
        transaction.delete(roomRef);
        return;
      }

      final newHostId = room.hostPlayerId == user.uid
          ? playerIds.first
          : room.hostPlayerId;

      transaction.update(roomRef, {
        'playerIds': playerIds,
        'hostPlayerId': newHostId,
      });

      if (room.hostPlayerId == user.uid) {
        transaction.set(
          roomRef.collection('players').doc(newHostId),
          {
            'isHost': true,
            'isReady': true,
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> startRoom(String roomId) async {
    final user = await _currentUser();
    final normalizedRoomId = roomId.trim().toUpperCase();
    final roomRef = _roomsRef.doc(normalizedRoomId);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      final roomData = roomSnapshot.data();

      if (!roomSnapshot.exists || roomData == null) {
        throw Exception('ルームが見つかりません');
      }

      final room = OnlineRoom.fromMap(roomSnapshot.id, roomData);
      if (room.hostPlayerId != user.uid) {
        throw Exception('開始できるのはホストだけです');
      }

      if (room.playerIds.length < 2) {
        throw Exception('2人以上で開始できます');
      }

      transaction.update(roomRef, {
        'started': true,
        'status': 'playing',
        'currentTurnPlayerId': room.playerIds.first,
      });
    });
  }

  Future<String> _generateUniqueRoomId() async {
    for (var i = 0; i < 12; i++) {
      final roomId = _generateRoomId();
      final snapshot = await _roomsRef.doc(roomId).get();
      if (!snapshot.exists) return roomId;
    }

    throw Exception('ルームIDの生成に失敗しました');
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(6, (_) {
      return chars[random.nextInt(chars.length)];
    }).join();
  }
}