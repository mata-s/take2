import 'package:flutter/material.dart';
import '../friends/friend_list_page.dart';
import 'online_game_page.dart';

import '../models/online_player.dart';
import '../models/online_room.dart';
import '../services/online_room_service.dart';
import '../services/online_game_service.dart';

class RoomLobbyPage extends StatefulWidget {
  const RoomLobbyPage({
    super.key,
    required this.roomId,
  });

  final String roomId;

  @override
  State<RoomLobbyPage> createState() => _RoomLobbyPageState();
}

class _RoomLobbyPageState extends State<RoomLobbyPage> {
  static final OnlineRoomService _service = OnlineRoomService();
  static final OnlineGameService _gameService = OnlineGameService();

  bool _hasNavigatedToGame = false;

  void _goToOnlineGamePage() {
    if (_hasNavigatedToGame) return;
    _hasNavigatedToGame = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnlineGamePage(roomId: widget.roomId),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンド対戦'),
      ),
      body: StreamBuilder<OnlineRoom?>(
        stream: _service.watchRoom(widget.roomId),
        builder: (context, roomSnapshot) {
          return StreamBuilder<List<OnlinePlayer>>(
            stream: _service.watchPlayers(widget.roomId),
            builder: (context, playersSnapshot) {
              final room = roomSnapshot.data;
              final players = playersSnapshot.data ?? const <OnlinePlayer>[];

              if (room?.status == 'playing') {
                _goToOnlineGamePage();
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'ルームコード',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              widget.roomId,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FriendListPage(
                                    selectMode: true,
                                    roomId: widget.roomId,
                                  ),
                                ),
                              );
                                },
                                icon: const Icon(Icons.person_add_alt_1_rounded),
                                label: const Text('フレンドを招待'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '参加プレイヤー (${players.length}/${room?.maxPlayers ?? 4})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (room != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        room.fillWithCpu
                            ? '足りない人数はCPUで参加します'
                            : '人が揃うまで待機します',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.54),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];

                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(player.name),
                            subtitle: Text(
                              player.isHost ? 'ホスト' : '参加者',
                            ),
                            trailing: Icon(
                              player.isReady
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Ready'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: room == null
                          ? null
                          : () async {
                              try {
                                await _gameService.startGame(widget.roomId);

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ゲームを開始しました'),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('開始失敗: $e'),
                                  ),
                                );
                              }
                            },
                      child: const Text('ゲーム開始'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('退出'),
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