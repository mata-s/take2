

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/online_card.dart';
import '../models/online_game_player.dart';
import '../models/online_game_state.dart';
import '../models/online_player.dart';
import '../models/online_room.dart';

class OnlineGameService {
  OnlineGameService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');

  Stream<OnlineGameState?> watchGameState(String roomId) {
    return _roomsRef
        .doc(roomId.trim().toUpperCase())
        .collection('game')
        .doc('state')
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return OnlineGameState.fromMap(data);
    });
  }

  Stream<List<OnlineGamePlayer>> watchGamePlayers(String roomId) {
    return _roomsRef
        .doc(roomId.trim().toUpperCase())
        .collection('gamePlayers')
        .orderBy('seatIndex')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OnlineGamePlayer.fromMap(doc.data());
      }).toList();
    });
  }

  Future<void> startGame(String roomId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }

    final normalizedRoomId = roomId.trim().toUpperCase();
    final roomRef = _roomsRef.doc(normalizedRoomId);
    final stateRef = roomRef.collection('game').doc('state');
    final playersRef = roomRef.collection('players');
    final gamePlayersRef = roomRef.collection('gamePlayers');

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      final roomData = roomSnapshot.data();

      if (!roomSnapshot.exists || roomData == null) {
        throw Exception('ルームが見つかりません');
      }

      final room = OnlineRoom.fromMap(roomSnapshot.id, roomData);

      if (room.hostPlayerId != currentUser.uid) {
        throw Exception('開始できるのはホストだけです');
      }

      if (room.started || room.status == 'playing') {
        throw Exception('このゲームはすでに開始されています');
      }

      final playerSnapshots = await playersRef.orderBy('seatIndex').get();
      final humanPlayers = playerSnapshots.docs.map((doc) {
        return OnlinePlayer.fromMap(doc.id, doc.data());
      }).toList();

      if (humanPlayers.length < 2 && !room.fillWithCpu) {
        throw Exception('2人以上で開始できます');
      }

      final gamePlayers = <OnlineGamePlayer>[];
      for (final player in humanPlayers) {
        gamePlayers.add(
          OnlineGamePlayer(
            uid: player.id,
            name: player.name,
            hand: const [],
            isReach: false,
            hasFinished: false,
            rank: null,
            seatIndex: gamePlayers.length,
            isCpu: false,
          ),
        );
      }

      if (room.fillWithCpu) {
        while (gamePlayers.length < room.maxPlayers) {
          final cpuNumber = gamePlayers.length + 1;
          gamePlayers.add(
            OnlineGamePlayer(
              uid: 'cpu_$cpuNumber',
              name: 'CPU$cpuNumber',
              hand: const [],
              isReach: false,
              hasFinished: false,
              rank: null,
              seatIndex: gamePlayers.length,
              isCpu: true,
            ),
          );
        }
      }

      if (gamePlayers.length < 2) {
        throw Exception('2人以上で開始できます');
      }

      final deck = _createDeck(useJokers: roomData['useJokers'] as bool? ?? false)
        ..shuffle(Random.secure());

      final dealtPlayers = <OnlineGamePlayer>[];
      for (final player in gamePlayers) {
        final hand = <OnlineCard>[];
        for (var i = 0; i < 7; i++) {
          if (deck.isEmpty) break;
          hand.add(deck.removeLast());
        }

        dealtPlayers.add(
          player.copyWith(hand: hand),
        );
      }

      OnlineCard? fieldCard;
      while (deck.isNotEmpty) {
        final candidate = deck.removeLast();
        fieldCard = candidate;

        // 最初の場札がジョーカーだと強すぎるので、通常カードを優先する。
        if (candidate.rank != 'joker') break;
      }

      final firstPlayerUid = dealtPlayers.first.uid;

      transaction.set(
        stateRef,
        OnlineGameState(
          deck: deck,
          fieldCard: fieldCard,
          currentPlayerUid: firstPlayerUid,
          pendingDrawCount: 0,
          pendingSkipCount: 0,
          forcedSuit: null,
          started: true,
          finished: false,
        ).toMap(),
      );

      for (final player in dealtPlayers) {
        transaction.set(
          gamePlayersRef.doc(player.uid),
          player.toMap(),
        );
      }

      transaction.update(roomRef, {
        'started': true,
        'status': 'playing',
        'currentTurnPlayerId': firstPlayerUid,
      });
    });
  }

  List<OnlineCard> _createDeck({required bool useJokers}) {
    const suits = ['spade', 'heart', 'diamond', 'club'];
    const ranks = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
      '13',
    ];

    final cards = <OnlineCard>[
      for (final suit in suits)
        for (final rank in ranks) OnlineCard(suit: suit, rank: rank),
    ];

    if (useJokers) {
      cards.addAll(const [
        OnlineCard(suit: 'joker', rank: 'joker'),
        OnlineCard(suit: 'joker', rank: 'joker'),
      ]);
    }

    return cards;
  }
}