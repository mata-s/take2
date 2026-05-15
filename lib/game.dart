import 'package:flutter/material.dart';

import 'models/playing_card.dart';
import 'models/player_state.dart';
import 'services/deck_service.dart';
import 'services/rule_service.dart';
import 'widgets/playing_card_widget.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Set<int> selectedIndexes = {};

  final List<PlayingCard> deck = [];
  final List<PlayingCard> discardPile = [];
  final List<PlayerState> players = [];
  PlayingCard? fieldCard;
  int currentPlayerIndex = 0;
  bool hasDrawnThisTurn = false;
  int pendingDrawCount = 0;
  final List<String> finishOrder = [];

  PlayerState get currentPlayer => players[currentPlayerIndex];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    deck
      ..clear()
      ..addAll(DeckService.createDeck());

    DeckService.shuffleDeck(deck);
    discardPile.clear();

    players
      ..clear()
      ..addAll([
        PlayerState(name: 'あなた', hand: DeckService.drawCards(deck, 5)),
        PlayerState(name: 'CPU 1', hand: DeckService.drawCards(deck, 5)),
        PlayerState(name: 'CPU 2', hand: DeckService.drawCards(deck, 5)),
        PlayerState(name: 'CPU 3', hand: DeckService.drawCards(deck, 5)),
      ]);

    fieldCard = DeckService.drawCard(deck);
    discardPile.add(fieldCard!);
    currentPlayerIndex = 0;
    hasDrawnThisTurn = false;
    pendingDrawCount = 0;
    selectedIndexes.clear();
    finishOrder.clear();
    _scheduleCpuTurnIfNeeded();
  }

  void _recycleDiscardPileIfNeeded() {
    if (!RuleService.shouldRecycleDeck(
      deckLength: deck.length,
      discardPileLength: discardPile.length,
    )) {
      return;
    }

    final topCard = discardPile.removeLast();
    deck.addAll(discardPile);
    DeckService.shuffleDeck(deck);

    discardPile
      ..clear()
      ..add(topCard);
  }

  List<PlayingCard> _drawCardsSafely(int count) {
    final drawnCards = <PlayingCard>[];

    for (int i = 0; i < count; i++) {
      _recycleDiscardPileIfNeeded();
      if (deck.isEmpty) break;

      drawnCards.add(DeckService.drawCard(deck));
    }

    return drawnCards;
  }

  void _setFieldCard(PlayingCard card) {
    fieldCard = card;
    discardPile.add(card);
  }

  void _drawOneCard() {
    _recycleDiscardPileIfNeeded();
    if (deck.isEmpty) return;
    if (hasDrawnThisTurn) return;

    final drawCount = pendingDrawCount > 0 ? pendingDrawCount : 1;

    setState(() {
      currentPlayer.hand.addAll(_drawCardsSafely(drawCount));
      selectedIndexes.clear();
      hasDrawnThisTurn = true;
      pendingDrawCount = 0;
    });
  }

  void _goToNextTurn() {
    if (players.isEmpty) return;

    setState(() {
      selectedIndexes.clear();
      hasDrawnThisTurn = false;

      int nextIndex = currentPlayerIndex;
      for (int i = 0; i < players.length; i++) {
        nextIndex = (nextIndex + 1) % players.length;
        if (!players[nextIndex].hasFinished) {
          currentPlayerIndex = nextIndex;
          break;
        }
      }
    });

    _scheduleCpuTurnIfNeeded();
  }

  void _scheduleCpuTurnIfNeeded() {
    if (players.isEmpty) return;
    if (currentPlayerIndex == 0) return;

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      if (players.isEmpty) return;
      if (currentPlayerIndex == 0) return;

      _playCpuTurn();
    });
  }

  void _playCpuTurn() {
    final cpu = currentPlayer;

    final playableIndex = cpu.hand.indexWhere((card) {
      final willFinish = cpu.hand.length == 1;
      if (willFinish && RuleService.isForbiddenFinishCard(card)) return false;

      if (pendingDrawCount > 0) {
        return RuleService.canRespondToDrawPenalty(card);
      }

      return RuleService.canPlayCard(
        card: card,
        fieldCard: fieldCard,
      );
    });

    if (playableIndex >= 0) {
      final card = cpu.hand[playableIndex];

      setState(() {
        _setFieldCard(card);
        cpu.hand.removeAt(playableIndex);

        if (RuleService.isDrawPenaltyCard(card)) {
          pendingDrawCount += RuleService.drawPenaltyCount(card);
        } else {
          pendingDrawCount = 0;
        }

        if (cpu.hand.isEmpty) {
          cpu.hasFinished = true;
          finishOrder.add(cpu.name);
        }
      });
    } else if (deck.isNotEmpty) {
      final drawCount = pendingDrawCount > 0 ? pendingDrawCount : 1;

      setState(() {
        cpu.hand.addAll(_drawCardsSafely(drawCount));
        pendingDrawCount = 0;
      });
    }

    _goToNextTurn();
  }

  void _passTurn() {
    _goToNextTurn();
  }

  void _playSelectedCards() {
    if (selectedIndexes.isEmpty) return;

    final hand = currentPlayer.hand;
    final selectedCards = selectedIndexes.map((index) => hand[index]).toList();
    final firstCard = selectedCards.first;

    if (pendingDrawCount > 0 &&
        !RuleService.canRespondToDrawPenalty(firstCard)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('2かジョーカーで返すか、引いてください'),
          duration: Duration(milliseconds: 900),
        ),
      );
      return;
    }

    if (RuleService.isForbiddenFinish(
      playedCards: selectedCards,
      handLength: hand.length,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('8とジョーカーでは上がれません'),
          duration: Duration(milliseconds: 900),
        ),
      );
      return;
    }

    if (!RuleService.hasSameRank(selectedCards)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('複数枚出しは同じ数字だけです'),
          duration: Duration(milliseconds: 900),
        ),
      );
      return;
    }

    if (!RuleService.canPlayCard(
      card: firstCard,
      fieldCard: fieldCard,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('同じ数字か同じマークのカードしか出せません'),
          duration: Duration(milliseconds: 900),
        ),
      );
      return;
    }

    final sortedIndexes = selectedIndexes.toList()..sort((a, b) => b.compareTo(a));

    setState(() {
      _setFieldCard(firstCard);

      for (final index in sortedIndexes) {
        hand.removeAt(index);
      }

      if (RuleService.isDrawPenaltyCard(firstCard)) {
        pendingDrawCount +=
            RuleService.drawPenaltyCount(firstCard) * selectedCards.length;
      } else {
        pendingDrawCount = 0;
      }

      if (hand.isEmpty) {
        currentPlayer.hasFinished = true;
        finishOrder.add(currentPlayer.name);
      }

      selectedIndexes.clear();
    });

    _goToNextTurn();
  }

  void _toggleSelectedCard(int index) {
    final hand = currentPlayer.hand;
    final tappedCard = hand[index];

    if (selectedIndexes.contains(index)) {
      setState(() {
        selectedIndexes.remove(index);
      });
      return;
    }

    if (selectedIndexes.isNotEmpty) {
      final firstSelectedCard = hand[selectedIndexes.first];
      if (tappedCard.rank != firstSelectedCard.rank) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('まとめて出すなら同じ数字を選んでください'),
            duration: Duration(milliseconds: 800),
          ),
        );
        return;
      }
    }

    setState(() {
      selectedIndexes.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (players.isEmpty)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else ...[
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Take2',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            _OpponentArea(
              players: players,
              currentPlayerIndex: currentPlayerIndex,
            ),
            const SizedBox(height: 10),
            _TurnBanner(player: currentPlayer),
            if (pendingDrawCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'ドロー累積: $pendingDrawCount枚',
                style: const TextStyle(
                  color: Color(0xFFFFC857),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            if (finishOrder.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '上がり: ${finishOrder.join(' → ')}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (fieldCard != null)
                  PlayingCardWidget(
                    rank: fieldCard!.rankLabel,
                    suit: fieldCard!.suitLabel,
                  ),
                const SizedBox(width: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const PlayingCardWidget(
                      rank: '',
                      suit: '',
                      isBack: true,
                    ),
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${deck.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: currentPlayerIndex == 0 ? _playSelectedCards : null,
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
                  onPressed: currentPlayerIndex == 0 && !hasDrawnThisTurn
                      ? _drawOneCard
                      : null,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    pendingDrawCount > 0
                        ? '${pendingDrawCount}枚引く'
                        : '引く',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.16),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: currentPlayerIndex == 0 && hasDrawnThisTurn
                      ? _passTurn
                      : null,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('パス'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.10),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: currentPlayer.hand.length,
                itemBuilder: (context, index) {
                  final card = currentPlayer.hand[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: PlayingCardWidget(
                      rank: card.rankLabel,
                      suit: card.suitLabel,
                      isSelected: selectedIndexes.contains(index),
                      onTap: currentPlayerIndex == 0 ? () => _toggleSelectedCard(index) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpponentArea extends StatelessWidget {
  const _OpponentArea({
    required this.players,
    required this.currentPlayerIndex,
  });

  final List<PlayerState> players;
  final int currentPlayerIndex;

  @override
  Widget build(BuildContext context) {
    final opponents = players.skip(1).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: opponents.map((player) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: players.indexOf(player) == currentPlayerIndex
                      ? const Color(0xFFFFC857)
                      : Colors.white.withOpacity(0.12),
                  width: players.indexOf(player) == currentPlayerIndex ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    player.hasFinished ? '上がり' : '手札 ${player.hand.length}枚',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.player});

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
