import 'package:flutter/material.dart';

import '../models/online_game_player.dart';
import '../models/online_game_state.dart';
import '../services/online_game_service.dart';

class OnlineGamePage extends StatelessWidget {
  const OnlineGamePage({
    super.key,
    required this.roomId,
  });

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final gameService = OnlineGameService();

    return Scaffold(
      backgroundColor: const Color(0xFF0E4B3C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Take2 Online'),
      ),
      body: StreamBuilder<OnlineGameState?>(
        stream: gameService.watchGameState(roomId),
        builder: (context, stateSnapshot) {
          final gameState = stateSnapshot.data;

          if (gameState == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return StreamBuilder<List<OnlineGamePlayer>>(
            stream: gameService.watchGamePlayers(roomId),
            builder: (context, playerSnapshot) {
              final players = playerSnapshot.data ?? const [];

              return Column(
                children: [
                  const SizedBox(height: 16),

                  Text(
                    '現在のターン',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),

                  Text(
                    gameState.currentPlayerUid ?? '-',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: 90,
                    height: 130,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      gameState.fieldCard == null
                          ? '-'
                          : '${gameState.fieldCard!.suit}\n${gameState.fieldCard!.rank}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '山札 ${gameState.deck.length}枚',
                    style: const TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];

                        return ListTile(
                          title: Text(
                            player.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '手札 ${player.hand.length}枚',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
