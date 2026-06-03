import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvitationService {
  InvitationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Future<void> sendGameInvitation({
    required String friendUid,
    required String roomId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }

    if (friendUid.isEmpty) {
      throw Exception('招待するフレンドが選択されていません');
    }

    if (roomId.trim().isEmpty) {
      throw Exception('ルームが作成されていません');
    }

    if (friendUid == currentUser.uid) {
      throw Exception('自分には招待できません');
    }

    final myUserSnapshot = await _usersRef.doc(currentUser.uid).get();
    final myUserData = myUserSnapshot.data() ?? const <String, dynamic>{};
    final myName = myUserData['name'] as String?;
    final myFriendCode = myUserData['friendCode'] as String?;

    final invitationRef = _usersRef
        .doc(friendUid)
        .collection('invitations')
        .doc('${currentUser.uid}_${roomId.trim().toUpperCase()}');

    await invitationRef.set({
      'fromUid': currentUser.uid,
      'fromName': myName == null || myName.isEmpty ? 'プレイヤー' : myName,
      'fromFriendCode': myFriendCode ?? '',
      'roomId': roomId.trim().toUpperCase(),
      'message': 'Take2に招待されました',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> watchReceivedInvitations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }

    return _usersRef
        .doc(currentUser.uid)
        .collection('invitations')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final invitations = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      invitations.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];

        if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
          return bCreatedAt.compareTo(aCreatedAt);
        }

        return 0;
      });

      return invitations;
    });
  }

  Future<void> acceptInvitation(String invitationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }

    await _usersRef
        .doc(currentUser.uid)
        .collection('invitations')
        .doc(invitationId)
        .set({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> declineInvitation(String invitationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインしていません');
    }

    await _usersRef
        .doc(currentUser.uid)
        .collection('invitations')
        .doc(invitationId)
        .set({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}