import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/playing_card.dart';
import '../../models/player_state.dart';
import '../../services/turn_order_service.dart';

class TurnOrderOverlay extends StatefulWidget {
  const TurnOrderOverlay({
    super.key,
    required this.players,
    required this.targetCard,
    this.limitSeconds = 5,
  });

  final List<PlayerState> players;
  final PlayingCard targetCard;
  final int limitSeconds;

  @override
  State<TurnOrderOverlay> createState() => _TurnOrderOverlayState();
}

class _TurnOrderOverlayState extends State<TurnOrderOverlay> {
  final Stopwatch _stopwatch = Stopwatch();
  final Random _random = Random();

  Timer? _countdownTimer;
  int _remainingSeconds = 5;
  int? _selectedNumber;
  TurnOrderResult? _result;
  bool _hasClosed = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.limitSeconds;
    _stopwatch.start();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _finish();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _selectNumber(int number) {
    if (_result != null) return;

    setState(() {
      _selectedNumber = number;
    });

    _finish();
  }

  void _finish() {
    if (_result != null) return;

    _countdownTimer?.cancel();
    _stopwatch.stop();

    final entries = <TurnOrderEntry>[];

    final playerGuess = _selectedNumber ?? _random.nextInt(13) + 1;
    entries.add(
      TurnOrderEntry(
        playerIndex: 0,
        playerName: widget.players[0].name,
        guessedNumber: playerGuess,
        answeredAtMs: _selectedNumber == null
            ? widget.limitSeconds * 1000 + 999
            : _stopwatch.elapsedMilliseconds,
      ),
    );

    for (int i = 1; i < widget.players.length; i++) {
      entries.add(
        TurnOrderEntry(
          playerIndex: i,
          playerName: widget.players[i].name,
          guessedNumber: _random.nextInt(13) + 1,
          answeredAtMs: 500 + _random.nextInt(widget.limitSeconds * 1000),
        ),
      );
    }

    final result = TurnOrderService.determineOrder(
      targetCard: widget.targetCard,
      entries: entries,
    );

    setState(() {
      _result = result;
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _startGame();
    });
  }

  void _startGame() {
    if (_hasClosed) return;

    final result = _result;
    if (result == null) return;

    _hasClosed = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Dialog(
      backgroundColor: const Color(0xFF123F35),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: result == null ? _buildGuessView() : _buildResultView(result),
        ),
      ),
    );
  }

  Widget _buildGuessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '順番決め',
          style: TextStyle(
            color: Color(0xFFFFC857),
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'スタートカードに近い数字を選ぼう',
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        const _HiddenStartCard(
          width: 82,
          height: 116,
        ),
        const SizedBox(height: 10),
        Text(
          'カードは選択後にめくられます',
          style: TextStyle(
            color: Colors.white.withOpacity(0.66),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '残り $_remainingSeconds 秒',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (int number = 1; number <= 13; number++)
              _NumberButton(
                number: number,
                selected: _selectedNumber == number,
                onPressed: () => _selectNumber(number),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultView(TurnOrderResult result) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '順番決定！',
          style: TextStyle(
            color: Color(0xFFFFC857),
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        _TurnOrderCard(
          card: result.targetCard,
          width: 72,
          height: 102,
        ),
        const SizedBox(height: 12),
        Text(
          'スタートカード：${result.targetNumber}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < result.rankedEntries.length; i++) ...[
          _RankRow(
            rank: i + 1,
            entry: result.rankedEntries[i],
          ),
          if (i != result.rankedEntries.length - 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withOpacity(0.62),
                size: 24,
              ),
            ),
        ],
        const SizedBox(height: 10),
        Text(
          'まもなく開始します',
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HiddenStartCard extends StatelessWidget {
  const _HiddenStartCard({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0B2F29),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFC857).withOpacity(0.72),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '?',
          style: TextStyle(
            color: Color(0xFFFFC857),
            fontSize: 42,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TurnOrderCard extends StatelessWidget {
  const _TurnOrderCard({
    required this.card,
    required this.width,
    required this.height,
  });

  final PlayingCard card;
  final double width;
  final double height;

  String get _rankLabel {
    if (card.isJoker) return 'JOKER';

    return switch (card.rank) {
      1 => 'A',
      11 => 'J',
      12 => 'Q',
      13 => 'K',
      _ => '${card.rank}',
    };
  }

  String get _suitLabel {
    if (card.isJoker) return '';

    return switch (card.suit.name) {
      'spade' => '♠',
      'heart' => '♥',
      'diamond' => '♦',
      'club' => '♣',
      _ => card.suit.name,
    };
  }

  Color get _textColor {
    final suitName = card.suit.name;
    if (suitName == 'heart' || suitName == 'diamond') {
      return const Color(0xFFD93838);
    }
    return const Color(0xFF111111);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: card.isJoker
            ? Text(
                _rankLabel,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _rankLabel,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: width >= 80 ? 34 : 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _suitLabel,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: width >= 80 ? 28 : 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    required this.number,
    required this.selected,
    required this.onPressed,
  });

  final int number;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 44,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFFFFC857)
              : Colors.white.withOpacity(0.12),
          foregroundColor: selected ? const Color(0xFF0E4B3C) : Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.entry,
  });

  final int rank;
  final TurnOrderRankedEntry entry;

  bool get isYou => entry.playerIndex == 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isYou
            ? const Color(0xFFFFC857).withOpacity(0.18)
            : Colors.white.withOpacity(rank == 1 ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isYou
              ? const Color(0xFFFFC857)
              : rank == 1
                  ? const Color(0xFFFFC857).withOpacity(0.72)
                  : Colors.white.withOpacity(0.10),
          width: isYou ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '$rank番',
              style: const TextStyle(
                color: Color(0xFFFFC857),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isYou ? '${entry.playerName}（あなた）' : entry.playerName,
              style: TextStyle(
                color: isYou
                    ? const Color(0xFFFFE08A)
                    : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '選択 ${entry.guessedNumber} / 差${entry.difference}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}