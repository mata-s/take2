

import 'package:flutter/material.dart';

class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({
    super.key,
    required this.rank,
    required this.suit,
    this.isSelected = false,
    this.isBack = false,
    this.width = 72,
    this.height = 104,
    this.onTap,
  });

  final String rank;
  final String suit;
  final bool isSelected;
  final bool isBack;
  final double width;
  final double height;
  final VoidCallback? onTap;

  bool get _isRed => suit == '♥' || suit == '♦';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: width,
        height: height,
        transform: Matrix4.translationValues(0, isSelected ? -10 : 0, 0),
        decoration: BoxDecoration(
          color: isBack ? const Color(0xFF243B6B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC857) : const Color(0xFFE2E2E2),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isBack ? _buildBack() : _buildFront(),
      ),
    );
  }

  Widget _buildFront() {
    final color = _isRed ? const Color(0xFFD63B3B) : const Color(0xFF202124);

    return Stack(
      children: [
        Positioned(
          top: 8,
          left: 8,
          child: _Corner(rank: rank, suit: suit, color: color),
        ),
        Center(
          child: Text(
            suit,
            style: TextStyle(
              fontSize: width * 0.42,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Transform.rotate(
            angle: 3.14159,
            child: _Corner(rank: rank, suit: suit, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildBack() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.55), width: 2),
        ),
        child: Center(
          child: Text(
            'T2',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: width * 0.28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({
    required this.rank,
    required this.suit,
    required this.color,
  });

  final String rank;
  final String suit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rank,
          style: TextStyle(
            fontSize: 16,
            height: 0.95,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          suit,
          style: TextStyle(
            fontSize: 14,
            height: 0.95,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}