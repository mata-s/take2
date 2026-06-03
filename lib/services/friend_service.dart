import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  FriendService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Stream<List<Map<String, dynamic>>> watchFriends() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }

    return _usersRef
        .doc(currentUser.uid)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> watchReceivedFriendRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }

    return _usersRef
        .doc(currentUser.uid)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      requests.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];

        if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
          return bCreatedAt.compareTo(aCreatedAt);
        }

        return 0;
      });

      return requests;
    });
  }

  Future<void> acceptFriendRequest(String fromUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }

    final myUserRef = _usersRef.doc(currentUser.uid);
    final fromUserRef = _usersRef.doc(fromUid);
    final requestRef = myUserRef.collection('friendRequests').doc(fromUid);
    final myFriendRef = myUserRef.collection('friends').doc(fromUid);
    final fromFriendRef = fromUserRef.collection('friends').doc(currentUser.uid);

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      final myUserSnapshot = await transaction.get(myUserRef);
      final fromUserSnapshot = await transaction.get(fromUserRef);

      if (!requestSnapshot.exists) {
        throw Exception('申請が見つかりません');
      }

      final requestData = requestSnapshot.data() ?? const <String, dynamic>{};
      final status = requestData['status'] as String? ?? 'pending';
      if (status != 'pending') {
        throw Exception('この申請は処理済みです');
      }

      final myData = myUserSnapshot.data() ?? const <String, dynamic>{};
      final fromData = fromUserSnapshot.data() ?? const <String, dynamic>{};

      final myName = myData['name'] as String?;
      final myFriendCode = myData['friendCode'] as String?;
      final fromName = fromData['name'] as String?;
      final fromFriendCode = fromData['friendCode'] as String?;

      transaction.set(myFriendRef, {
        'uid': fromUid,
        'name': fromName == null || fromName.isEmpty ? 'プレイヤー' : fromName,
        'friendCode': fromFriendCode ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(fromFriendRef, {
        'uid': currentUser.uid,
        'name': myName == null || myName.isEmpty ? 'プレイヤー' : myName,
        'friendCode': myFriendCode ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(requestRef, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectFriendRequest(String fromUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }

    await _usersRef
        .doc(currentUser.uid)
        .collection('friendRequests')
        .doc(fromUid)
        .set({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendFriendRequestByCode(String friendCode) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }

    final normalizedCode = friendCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw Exception('フレンドIDを入力してください');
    }

    final targetQuery = await _usersRef
        .where('friendCode', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (targetQuery.docs.isEmpty) {
      throw Exception('このフレンドIDのユーザーが見つかりません');
    }

    final targetDoc = targetQuery.docs.first;
    final targetUid = targetDoc.id;
    final targetData = targetDoc.data();

    if (targetUid == currentUser.uid) {
      throw Exception('自分には申請できません');
    }

    final currentUserDoc = await _usersRef.doc(currentUser.uid).get();
    final currentUserData = currentUserDoc.data() ?? const <String, dynamic>{};

    final currentName = currentUserData['name'] as String?;
    final currentFriendCode = currentUserData['friendCode'] as String?;
    final targetName = targetData['name'] as String?;

    final currentFriendRef = _usersRef
        .doc(currentUser.uid)
        .collection('friends')
        .doc(targetUid);
    final currentFriendSnapshot = await currentFriendRef.get();

    if (currentFriendSnapshot.exists) {
      throw Exception('すでにフレンドです');
    }

    final requestRef = _usersRef
        .doc(targetUid)
        .collection('friendRequests')
        .doc(currentUser.uid);

    final existingRequest = await requestRef.get();
    if (existingRequest.exists) {
      throw Exception('すでに申請済みです');
    }

    await requestRef.set({
      'fromUid': currentUser.uid,
      'fromName': currentName == null || currentName.isEmpty
          ? 'プレイヤー'
          : currentName,
      'fromFriendCode': currentFriendCode ?? '',
      'toUid': targetUid,
      'toName': targetName == null || targetName.isEmpty
          ? 'プレイヤー'
          : targetName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}