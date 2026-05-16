import 'package:flutter/material.dart';

import '../models/player_state.dart';

class TurnBanner extends StatelessWidget {
  const TurnBanner({
    super.key,
    required this.player,
  });

  final PlayerState player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${player.name}のターン',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}