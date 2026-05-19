

import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    required this.canPlay,
    required this.canDraw,
    required this.canPass,
    required this.canReach,
    required this.pendingDrawCount,
    required this.onPlay,
    required this.onDraw,
    required this.onPass,
    required this.onReach,
  });

  final bool canPlay;
  final bool canDraw;
  final bool canPass;
  final bool canReach;
  final int pendingDrawCount;
  final VoidCallback onPlay;
  final VoidCallback onDraw;
  final VoidCallback onPass;
  final VoidCallback onReach;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: canPlay ? onPlay : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('出す'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0E4B3C),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: canDraw ? onDraw : null,
            icon: const Icon(Icons.add_rounded),
            label: Text(pendingDrawCount > 0 ? '$pendingDrawCount枚引く' : '引く'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.16),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: canPass ? onPass : null,
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('パス'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.10),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          if (canReach) ...[
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onReach,
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('リーチ'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC857),
                foregroundColor: const Color(0xFF0E4B3C),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}