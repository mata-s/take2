

import 'package:flutter/material.dart';

import '../services/friend_service.dart';

class FriendApprovalPage extends StatefulWidget {
  const FriendApprovalPage({super.key});

  @override
  State<FriendApprovalPage> createState() => _FriendApprovalPageState();
}

class _FriendApprovalPageState extends State<FriendApprovalPage> {
  final FriendService _friendService = FriendService();

  Future<void> _accept(String fromUid) async {
    try {
      await _friendService.acceptFriendRequest(fromUid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('フレンドになりました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('承認失敗: $e')),
      );
    }
  }

  Future<void> _reject(String fromUid) async {
    try {
      await _friendService.rejectFriendRequest(fromUid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('申請を拒否しました')),
      );
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
          'フレンド承認',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _friendService.watchReceivedFriendRequests(),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? const [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                '届いている申請はありません',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final fromUid = request['fromUid'] as String? ?? '';
              final fromName = request['fromName'] as String? ?? 'プレイヤー';
              final fromCode = request['fromFriendCode'] as String? ?? '';

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
                      Text(fromCode),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _accept(fromUid),
                              child: const Text('承認'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _reject(fromUid),
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