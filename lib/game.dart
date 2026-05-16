import 'package:flutter/material.dart';

import 'models/playing_card.dart';
import 'models/player_state.dart';
import 'services/deck_service.dart';
import 'services/rule_service.dart';
import 'widgets/field_area.dart';
import 'widgets/action_buttons.dart';
import 'widgets/opponent_area.dart';
import 'widgets/turn_banner.dart';
import 'widgets/player_hand_area.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
    String _suitLabel(CardSuit suit) {
  switch (suit) {
    case CardSuit.spade:
      return '♠';
    case CardSuit.heart:
      return '♥';
    case CardSuit.diamond:
      return '♦';
    case CardSuit.club:
      return '♣';
    case CardSuit.joker:
      return '★';
  }
}
  final Set<int> selectedIndexes = {};

  final List<PlayingCard> deck = [];
  final List<PlayingCard> discardPile = [];
  final List<PlayerState> players = [];
  PlayingCard? fieldCard;
  int currentPlayerIndex = 0;
  bool hasDrawnThisTurn = false;
  bool mustDrawAgain = false;
  int pendingDrawCount = 0;
  int pendingSkipCount = 0;
  CardSuit? forcedSuit;
  Offset playedCardBeginOffset = const Offset(0, 2.75);
  int playedByPlayerIndex = 0;
  List<PlayingCard> playedCardsForField = [];
  final List<String> finishOrder = [];
  bool canDawnNow = false;
  int? dawnTargetPlayerIndex;
  int? fieldCardPlayerIndex;

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

    // fieldCard should only be drawn inside the do-while loop below
do {
  fieldCard = DeckService.drawCard(deck);
  discardPile.add(fieldCard!);
} while (fieldCard!.isJoker && deck.isNotEmpty);

if (fieldCard!.isJoker && discardPile.length > 1) {
  final joker = discardPile.removeLast();
  final replacement = discardPile.removeLast();

  discardPile
    ..add(joker)
    ..add(replacement);

  fieldCard = replacement;
}
    currentPlayerIndex = 0;
    hasDrawnThisTurn = false;
    pendingDrawCount = 0;
    pendingSkipCount = 0;
    forcedSuit = null;
    playedCardBeginOffset = const Offset(0, 2.75);
    playedByPlayerIndex = 0;
    playedCardsForField = fieldCard == null ? [] : [fieldCard!];
    selectedIndexes.clear();
    finishOrder.clear();
    canDawnNow = false;
    dawnTargetPlayerIndex = null;
    fieldCardPlayerIndex = null;
    _scheduleCpuTurnIfNeeded();
  }
  void _checkDawnChance({
    required PlayingCard playedCard,
    required int playedByIndex,
  }) {
    if (playedByIndex == 0) {
      canDawnNow = false;
      dawnTargetPlayerIndex = null;
      return;
    }

final player = players[0];

final canDawn = RuleService.canDawn(
  hand: player.hand,
  playedCard: playedCard,
  hasDeclaredReach: player.isReach,
);

    canDawnNow = canDawn;
    dawnTargetPlayerIndex = canDawn ? playedByIndex : null;
  }

  void _performDawn() {
    if (!canDawnNow) return;
    if (dawnTargetPlayerIndex == null) return;
    if (players.isEmpty) return;

    final dawnPlayer = players[0];
    final targetPlayer = players[dawnTargetPlayerIndex!];
    final targetIndex = dawnTargetPlayerIndex!;
    final dawnCards = List<PlayingCard>.from(dawnPlayer.hand);

    setState(() {
      targetPlayer.hand.addAll(dawnCards);
      currentPlayerIndex = targetIndex;
      hasDrawnThisTurn = false;
      mustDrawAgain = false;
      selectedIndexes.clear();

      dawnPlayer.hand.clear();
      dawnPlayer.hasFinished = true;
      finishOrder.add(dawnPlayer.name);
      dawnPlayer.isReach = false;

      canDawnNow = false;
      dawnTargetPlayerIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ドーン成功！'),
        duration: Duration(milliseconds: 1000),
      ),
    );

    _scheduleCpuTurnIfNeeded();
  }

  void _recycleDiscardPileIfNeeded() {
    if (deck.isNotEmpty) return;
    if (discardPile.length <= 1) return;

    final topCard = discardPile.removeLast();

    deck
      ..clear()
      ..addAll(discardPile);
    DeckService.shuffleDeck(deck);

    discardPile
      ..clear()
      ..add(topCard);

    fieldCard = topCard;
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

  void _refreshReachState(PlayerState player) {
    final wasReach = player.isReach;

    if (!RuleService.canReach(player.hand)) {
      player.isReach = false;
    }

    if (wasReach && !player.isReach && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name}のリーチが解除されました'),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

void _setFieldCard(
  PlayingCard card, {
  required int playedByIndex,
}) {
  fieldCard = card;
  fieldCardPlayerIndex = playedByIndex;
  discardPile.add(card);
}

  void _drawOneCard() {
    _recycleDiscardPileIfNeeded();
    if (deck.isEmpty) return;
    if (hasDrawnThisTurn && !mustDrawAgain) return;

    final isPenaltyDraw = pendingDrawCount > 0;
    final drawCount = isPenaltyDraw ? pendingDrawCount : 1;

    setState(() {
      currentPlayer.hand.addAll(_drawCardsSafely(drawCount));
      pendingDrawCount = 0;

      final hasPlayableCard = currentPlayer.hand.any(
        (card) {
          if (pendingDrawCount > 0) {
            return RuleService.canRespondToDrawPenalty(card);
          }

          return RuleService.canPlayCard(
            card: card,
            fieldCard: fieldCard,
            forcedSuit: forcedSuit,
          );
        },
      );

      mustDrawAgain = isPenaltyDraw && !hasPlayableCard;
      hasDrawnThisTurn = !isPenaltyDraw && !mustDrawAgain;

      _refreshReachState(currentPlayer);
      selectedIndexes.clear();

      final currentFieldCard = fieldCard;
      final lastPlayerIndex = fieldCardPlayerIndex;

      if (currentFieldCard != null &&
          lastPlayerIndex != null &&
          lastPlayerIndex != currentPlayerIndex &&
          RuleService.canDawn(
            hand: currentPlayer.hand,
            playedCard: currentFieldCard,
            hasDeclaredReach: currentPlayer.isReach,
          )) {
        canDawnNow = true;
        dawnTargetPlayerIndex = lastPlayerIndex;
      } else {
        canDawnNow = false;
        dawnTargetPlayerIndex = null;
      }
    });
  }
void _goToNextTurn() {
  if (players.isEmpty) return;

  setState(() {
    selectedIndexes.clear();
    hasDrawnThisTurn = false;
    mustDrawAgain = false;

    int skipRemaining = pendingSkipCount;
    pendingSkipCount = 0;

    int nextIndex = currentPlayerIndex;

    while (true) {
      nextIndex = (nextIndex + 1) % players.length;

      if (players[nextIndex].hasFinished) {
        continue;
      }

      if (skipRemaining > 0) {
        skipRemaining--;
        continue;
      }

      currentPlayerIndex = nextIndex;
      break;
    }
  });

  _scheduleCpuTurnIfNeeded();
}

  void _scheduleCpuTurnIfNeeded() {
    if (players.isEmpty) return;
    if (currentPlayerIndex == 0) return;
    if (canDawnNow) return;

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      if (players.isEmpty) return;
      if (currentPlayerIndex == 0) return;
      if (canDawnNow) return;

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
        forcedSuit: forcedSuit,
      );
    });

    if (playableIndex >= 0) {
      final card = cpu.hand[playableIndex];

      setState(() {
        playedByPlayerIndex = currentPlayerIndex;
        playedCardsForField = [card];
        _setFieldCard(
          card,
          playedByIndex: currentPlayerIndex,
        );
        _checkDawnChance(
          playedCard: card,
          playedByIndex: currentPlayerIndex,
        );
        cpu.hand.removeAt(playableIndex);

        if (RuleService.isDrawPenaltyCard(card)) {
          pendingDrawCount += RuleService.drawPenaltyCount(card);
        } else {
          pendingDrawCount = 0;
        }

        if (RuleService.isSkipCard(card)) {
          pendingSkipCount += 1;
        }

        if (RuleService.isSuitChangeCard(card)) {
          final suits = CardSuit.values
              .where((suit) => suit != CardSuit.joker)
              .toList()
            ..shuffle();

          forcedSuit = suits.first;
        } else {
          forcedSuit = null;
        }

        if (cpu.hand.isEmpty) {
          cpu.hasFinished = true;
          finishOrder.add(cpu.name);
        }
      });
      _refreshReachState(cpu);
      if (RuleService.canReach(cpu.hand)) {
        cpu.isReach = true;
      }

      if (canDawnNow) {
        return;
      }
    } else {
      _recycleDiscardPileIfNeeded();
      if (deck.isEmpty) {
        _goToNextTurn();
        return;
      }

      final isPenaltyDraw = pendingDrawCount > 0;
      final drawCount = isPenaltyDraw ? pendingDrawCount : 1;

      setState(() {
        cpu.hand.addAll(_drawCardsSafely(drawCount));
        pendingDrawCount = 0;

        if (isPenaltyDraw &&
            !RuleService.hasPlayableCard(
              hand: cpu.hand,
              fieldCard: fieldCard,
              forcedSuit: forcedSuit,
            )) {
          cpu.hand.addAll(_drawCardsSafely(1));
        }

        _refreshReachState(cpu);
      });
    }

    _goToNextTurn();
  }

  void _passTurn() {
    if (mustDrawAgain) return;
    _goToNextTurn();
  }

  bool _canPlaySelectedCards() {
    if (currentPlayerIndex != 0) return false;
    if (selectedIndexes.isEmpty) return false;

    final hand = currentPlayer.hand;
    final selectedCards = selectedIndexes.map((index) => hand[index]).toList();
    final baseCard = selectedCards.lastWhere(
      (card) => !card.isJoker,
      orElse: () => selectedCards.last,
    );

    if (pendingDrawCount > 0 &&
        RuleService.drawPenaltyCountForPlay(selectedCards) == 0) {
      return false;
    }

    final willFinish = selectedCards.length == hand.length;
    if (willFinish && RuleService.isForbiddenFinishCard(baseCard)) {
      return false;
    }

    return RuleService.canPlayCards(
      cards: selectedCards,
      fieldCard: fieldCard,
      forcedSuit: forcedSuit,
    );
  }

  Future<void> _playSelectedCards() async {
    if (selectedIndexes.isEmpty) return;

    final hand = currentPlayer.hand;
    final selectedCards = selectedIndexes.map((index) => hand[index]).toList();
    final topCard = selectedCards.last;
    final baseCard = selectedCards.lastWhere(
      (card) => !card.isJoker,
      orElse: () => topCard,
    );

    if (pendingDrawCount > 0 &&
        RuleService.drawPenaltyCountForPlay(selectedCards) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('2かジョーカーで返すか、引いてください'),
          duration: Duration(milliseconds: 900),
        ),
      );
      return;
    }

    final willFinish = selectedCards.length == hand.length;
    if (willFinish && RuleService.isForbiddenFinishCard(baseCard)) {
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

    if (!RuleService.canPlayCards(
      cards: selectedCards,
      fieldCard: fieldCard,
      forcedSuit: forcedSuit,
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
    final displayIndexes = List<int>.generate(hand.length, (index) => index)
      ..sort((a, b) {
        final rankCompare = hand[a].rank.compareTo(hand[b].rank);
        if (rankCompare != 0) return rankCompare;
        return hand[a].suit.index.compareTo(hand[b].suit.index);
      });

    final topOriginalIndex = selectedIndexes.last;
    final displayIndex = displayIndexes.indexOf(topOriginalIndex);
    final centerIndex = (hand.length - 1) / 2;
    final horizontalDistance = displayIndex - centerIndex;
    final beginX = (horizontalDistance * 0.28).clamp(-1.35, 1.35).toDouble();

    CardSuit? selectedForcedSuit;
    if (RuleService.isSuitChangeCard(baseCard)) {
      selectedForcedSuit = await _selectSuit();
      if (selectedForcedSuit == null) return;
    }

    setState(() {
      playedByPlayerIndex = currentPlayerIndex;
      playedCardBeginOffset = Offset(beginX, 2.75);
      playedCardsForField = List<PlayingCard>.from(selectedCards);
      _setFieldCard(
        baseCard,
        playedByIndex: currentPlayerIndex,
      );
      _checkDawnChance(
        playedCard: baseCard,
        playedByIndex: currentPlayerIndex,
      );

      for (final index in sortedIndexes) {
        hand.removeAt(index);
      }

      final penaltyCount = RuleService.drawPenaltyCountForPlay(selectedCards);
      if (penaltyCount > 0) {
        pendingDrawCount += penaltyCount;
      } else {
        pendingDrawCount = 0;
      }

      if (RuleService.isSkipCard(baseCard)) {
        pendingSkipCount += selectedCards.length;
      }

      if (RuleService.isSuitChangeCard(baseCard)) {
        forcedSuit = selectedForcedSuit;
      } else {
        forcedSuit = null;
      }
      if (hand.isEmpty) {
        currentPlayer.hasFinished = true;
        finishOrder.add(currentPlayer.name);
      }

      mustDrawAgain = false;
      selectedIndexes.clear();
    });

    if (!currentPlayer.isReach && RuleService.canReach(currentPlayer.hand)) {
      final shouldReach = await _confirmReachAfterPlay();
      if (shouldReach) {
        setState(() {
          currentPlayer.isReach = true;
        });
      }
    }
    _refreshReachState(currentPlayer);
    _goToNextTurn();
  }
  Future<bool> _confirmReachAfterPlay() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF123F35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'リーチしますか？',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '手札合計 ${RuleService.handTotal(currentPlayer.hand)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.14),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('言わない'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC857),
                          foregroundColor: const Color(0xFF0E4B3C),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('リーチ'),
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

    return result ?? false;
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
      final selectedCards = [
        ...selectedIndexes.map((selectedIndex) => hand[selectedIndex]),
        tappedCard,
      ];

      if (!RuleService.hasSameRank(selectedCards)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('まとめて出すなら同じ数字かジョーカーを選んでください'),
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

  void _declareReach() {
    if (!RuleService.canReach(currentPlayer.hand)) return;

    setState(() {
      currentPlayer.isReach = true;
    });
  }

  Future<CardSuit?> _selectSuit() {
    return showModalBottomSheet<CardSuit>(
      context: context,
      backgroundColor: const Color(0xFF123F35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final suits = [
          CardSuit.spade,
          CardSuit.heart,
          CardSuit.diamond,
          CardSuit.club,
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '変更するマークを選択',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: suits.map((suit) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(suit),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0E4B3C),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: Text(_suitLabel(suit)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Set<int> _playableIndexesForPlayerHand() {
    if (players.isEmpty || currentPlayerIndex != 0) return const <int>{};

    final hand = players[0].hand;
    final playableIndexes = <int>{};

    for (int i = 0; i < hand.length; i++) {
      final card = hand[i];

      if (pendingDrawCount > 0) {
        if (RuleService.canRespondToDrawPenalty(card)) {
          playableIndexes.add(i);
        }
        continue;
      }

      if (RuleService.canPlayCard(
        card: card,
        fieldCard: fieldCard,
        forcedSuit: forcedSuit,
      )) {
        playableIndexes.add(i);
      }
    }

    return playableIndexes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: canDawnNow
          ? Padding(
              padding: const EdgeInsets.only(bottom: 148),
              child: FloatingActionButton.extended(
                heroTag: 'dawn-button',
                onPressed: _performDawn,
                backgroundColor: const Color(0xFFFF5A5F),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text(
                  'ドーン！',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : null,
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
            OpponentArea(
              players: players,
              currentPlayerIndex: currentPlayerIndex,
            ),
            const SizedBox(height: 10),
            TurnBanner(player: currentPlayer),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: (pendingSkipCount > 0 ||
                      forcedSuit != null ||
                      pendingDrawCount > 0)
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (pendingSkipCount > 0)
                            const _StatusChip(label: 'スキップ'),
                          if (forcedSuit != null)
                            _StatusChip(
                              label: '指定 ${_suitLabel(forcedSuit!)}',
                            ),
                          if (pendingDrawCount > 0)
                            _StatusChip(
                              label: 'ドロー +$pendingDrawCount',
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            FieldArea(
              fieldCard: fieldCard,
              deckCount: deck.length,
              playedCardBeginOffset: switch (playedByPlayerIndex) {
                1 => const Offset(-2.8, 0),
                2 => const Offset(0, -2.8),
                3 => const Offset(2.8, 0),
                _ => playedCardBeginOffset,
              },
              playedCards: playedCardsForField,
            ),
            const SizedBox(height: 22),
            ActionButtons(
              canPlay: _canPlaySelectedCards(),
              canDraw: currentPlayerIndex == 0 &&
                  (!hasDrawnThisTurn || mustDrawAgain),
              canPass: currentPlayerIndex == 0 &&
                  hasDrawnThisTurn &&
                  !mustDrawAgain,
              canReach: currentPlayerIndex == 0 &&
                  RuleService.canReach(currentPlayer.hand) &&
                  !currentPlayer.isReach,
              pendingDrawCount: pendingDrawCount,
              onPlay: _playSelectedCards,
              onDraw: _drawOneCard,
              onPass: _passTurn,
              onReach: _declareReach,
            ),
            const SizedBox(height: 10),
            PlayerHandArea(
              hand: players[0].hand,
              selectedIndexes: selectedIndexes,
              canSelect: currentPlayerIndex == 0,
              playableIndexes: _playableIndexesForPlayerHand(),
              onCardTap: _toggleSelectedCard,
            ),
            const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC857).withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFC857).withOpacity(0.65),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFC857),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}