import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'room_lobby_page.dart';
import '../services/online_room_service.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  static const _useJokersKey = 'use_jokers';

  final OnlineRoomService _onlineRoomService = OnlineRoomService();

  int maxPlayers = 4;
  bool useJokers = false;
  bool fillWithCpu = true;
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadSavedRules();
  }

  Future<void> _loadSavedRules() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      useJokers = prefs.getBool(_useJokersKey) ?? false;
    });
  }

  Future<void> _createRoom() async {
    if (isCreating) return;

    setState(() {
      isCreating = true;
    });

    try {
      final roomId = await _onlineRoomService.createRoom(
        playerName: 'あなた',
        maxPlayers: maxPlayers,
        fillWithCpu: fillWithCpu,
      );

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RoomLobbyPage(roomId: roomId),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ルーム作成に失敗しました：$error'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E4B3C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'ルーム作成',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _SectionCard(
              title: '人数',
              child: Row(
                children: [
                  for (final count in [2, 3, 4]) ...[
                    Expanded(
                      child: _PlayerCountButton(
                        count: count,
                        selected: maxPlayers == count,
                        onTap: () {
                          setState(() {
                            maxPlayers = count;
                          });
                        },
                      ),
                    ),
                    if (count != 4) const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'CPU',
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: fillWithCpu,
                activeColor: const Color(0xFFFFC857),
                title: const Text(
                  '足りない人数をCPUで埋める',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  fillWithCpu
                      ? '招待した人が来なくても開始できます'
                      : '人が揃うまで待ちます',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    fillWithCpu = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: '禁止ルール',
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: useJokers,
                activeColor: const Color(0xFFFFC857),
                title: const Text(
                  'ジョーカーを使う',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  useJokers
                      ? 'ジョーカーありで遊びます'
                      : 'ジョーカーなしで遊びます',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    useJokers = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: isCreating ? null : _createRoom,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC857),
                  foregroundColor: const Color(0xFF0E4B3C),
                ),
                child: Text(
                  isCreating ? '作成中...' : 'この設定でルーム作成',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PlayerCountButton extends StatelessWidget {
  const _PlayerCountButton({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFFFFC857)
              : Colors.white.withOpacity(0.12),
          foregroundColor: selected ? const Color(0xFF0E4B3C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected
                  ? const Color(0xFFFFC857)
                  : Colors.white.withOpacity(0.14),
            ),
          ),
        ),
        child: Text(
          '$count人',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}