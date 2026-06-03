import 'package:flutter/material.dart';
import '../services/invitation_service.dart';

import '../services/friend_service.dart';

class FriendListPage extends StatelessWidget {
  FriendListPage({
    super.key,
    this.selectMode = false,
    this.roomId,
  });

  final bool selectMode;
  final String? roomId;

  final FriendService _friendService = FriendService();
  final InvitationService _invitationService = InvitationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E4B3C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          selectMode ? '招待するフレンド' : 'フレンド一覧',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _friendService.watchFriends(),
        builder: (context, snapshot) {
          final friends = snapshot.data ?? const <Map<String, dynamic>>[];

          if (snapshot.connectionState == ConnectionState.waiting &&
              friends.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (friends.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  selectMode
                      ? '招待できるフレンドがいません\n先にフレンドを追加してみよう'
                      : 'まだフレンドはいません\nフレンド申請から追加してみよう',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final friend = friends[index];
              final name = friend['name'] as String? ?? 'プレイヤー';
              final friendCode = friend['friendCode'] as String? ?? '';
              final friendUid =
                  friend['uid'] as String? ?? friend['id'] as String? ?? '';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0E4B3C),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'プレイヤー' : name,
                            style: const TextStyle(
                              color: Color(0xFF0E4B3C),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            friendCode,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.52),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: selectMode
                          ? () async {
                              final inviteRoomId = roomId;

                              if (inviteRoomId == null || inviteRoomId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ルームが見つかりません'),
                                  ),
                                );
                                return;
                              }

                              try {
                                await _invitationService.sendGameInvitation(
                                  friendUid: friendUid,
                                  roomId: inviteRoomId,
                                );

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${name.isEmpty ? 'プレイヤー' : name}さんを招待しました',
                                    ),
                                  ),
                                );
                              } catch (error) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('招待に失敗しました：$error'),
                                  ),
                                );
                              }
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ロビーから招待できます'),
                                ),
                              );
                            },
                      child: Text(selectMode ? '送る' : '招待'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
