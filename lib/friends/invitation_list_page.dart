

import 'package:flutter/material.dart';

import '../online/room_lobby_page.dart';
import '../services/invitation_service.dart';
import '../services/online_room_service.dart';

class InvitationListPage extends StatefulWidget {
  const InvitationListPage({super.key});

  @override
  State<InvitationListPage> createState() => _InvitationListPageState();
}

class _InvitationListPageState extends State<InvitationListPage> {
  final InvitationService _invitationService = InvitationService();
  final OnlineRoomService _onlineRoomService = OnlineRoomService();

  Future<void> _acceptInvitation(Map<String, dynamic> invitation) async {
    final invitationId = invitation['id'] as String? ?? '';
    final roomId = invitation['roomId'] as String? ?? '';

    try {
      await _onlineRoomService.joinRoom(
        roomId: roomId,
        playerName: 'あなた',
      );

      await _invitationService.acceptInvitation(invitationId);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoomLobbyPage(roomId: roomId),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('参加失敗: $e')),
      );
    }
  }

  Future<void> _declineInvitation(String invitationId) async {
    try {
      await _invitationService.declineInvitation(invitationId);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拒否失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E4B3C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '招待',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _invitationService.watchReceivedInvitations(),
        builder: (context, snapshot) {
          final invitations = snapshot.data ?? const [];

          if (invitations.isEmpty) {
            return const Center(
              child: Text(
                '届いている招待はありません',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final invitationId = invitation['id'] as String? ?? '';
              final fromName = invitation['fromName'] as String? ?? 'プレイヤー';
              final roomId = invitation['roomId'] as String? ?? '';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('ルーム: $roomId'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _acceptInvitation(invitation),
                              child: const Text('参加'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _declineInvitation(invitationId),
                              child: const Text('拒否'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}