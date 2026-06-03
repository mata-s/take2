import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  UserProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Future<String> getOrCreateFriendCode() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('ログインしていません');
    }

    final userRef = _usersRef.doc(user.uid);
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      final data = snapshot.data();
      final friendCode = data?['friendCode'] as String?;

      if (friendCode != null && friendCode.isNotEmpty) {
        return friendCode;
      }
    }

    final friendCode = await _generateUniqueFriendCode();

    await userRef.set({
      'uid': user.uid,
      'friendCode': friendCode,
      'name': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return friendCode;
  }

  Future<void> saveName(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('ログインしていません');
    }

    await _usersRef.doc(user.uid).set({
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> _generateUniqueFriendCode() async {
    for (var i = 0; i < 20; i++) {
      final code = _generateFriendCode();

      final query = await _usersRef
          .where('friendCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return code;
      }
    }

    throw Exception('フレンドコード生成に失敗しました');
  }

  String _generateFriendCode() {
    final random = Random.secure();
    final number = random.nextInt(900000) + 100000;

    return 'TAK$number';
  }
}