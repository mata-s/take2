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
import 'widgets/effects/reach_banner.dart';
import 'widgets/effects/dawn_effect.dart';
import 'widgets/effects/finish_effect.dart';
import 'widgets/effects/draw_effect.dart';
import 'widgets/effects/suit_change_effect.dart';
import 'widgets/effects/turn_start_effect.dart';
import 'widgets/effects/pass_effect.dart';
import 'widgets/effects/skip_effect.dart';

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

Color _suitColor(CardSuit suit) {
  switch (suit) {
    case CardSuit.heart:
    case CardSuit.diamond:
      return const Color(0xFFE84855);

    case CardSuit.spade:
    case CardSuit.club:
      return const Color(0xFF1F2937);

    case CardSuit.joker:
      return const Color(0xFFFFC857);
  }
}

  final Set<int> selectedIndexes = {};

  final List<PlayingCard> deck = [];
  final List<PlayingCard> discardPile = [];
  final List<PlayerState> players = [];
  PlayingCard? fieldCard;
  int currentPlayerIndex = 0;
  bool hasDrawnThisTurn = false;
  bool hasDeclinedReachThisTurn = false;
  bool showFloatingReachPrompt = false;
  bool showReachBanner = false;
  String reachBannerPlayerName = '';
  bool mustDrawAgain = false;
  int pendingDrawCount = 0;
  int pendingSkipCount = 0;
  CardSuit? forcedSuit;
  CardSuit? displayedSuitEffect;
  Offset playedCardBeginOffset = const Offset(0, 2.75);
  int playedByPlayerIndex = 0;
  List<PlayingCard> playedCardsForField = [];
  final List<String> finishOrder = [];
  bool canDawnNow = false;
  bool isHikiDawnNow = false;
  int? dawnTargetPlayerIndex;
  int? fieldCardPlayerIndex;
bool showDawnEffect = false;
bool dawnEffectIsHikiDawn = false;
String dawnEffectPlayerName = '';
String dawnEffectTargetPlayerName = '';
bool showFinishEffect = false;
String finishEffectPlayerName = '';
  int finishEffectPlace = 1;
  bool showDrawEffect = false;
  DrawEffectTarget drawEffectTarget = DrawEffectTarget.self;
  int drawEffectCount = 1;

  bool showTurnStartEffect = false;
  String turnStartEffectPlayerName = '';
  bool showPassEffect = false;
  String passEffectPlayerName = '';

  bool showSkipEffect = false;
String skipEffectPlayerName = '';
  DateTime? cpuBlockedUntil;

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
        PlayerState(name: 'あなた', hand: DeckService.drawCards(deck, 7)),
        PlayerState(name: 'CPU 1', hand: DeckService.drawCards(deck, 7)),
        PlayerState(name: 'CPU 2', hand: DeckService.drawCards(deck, 7)),
        PlayerState(name: 'CPU 3', hand: DeckService.drawCards(deck, 7)),
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
    hasDeclinedReachThisTurn = false;
    showFloatingReachPrompt = false;
    showReachBanner = false;
    reachBannerPlayerName = '';

    pendingDrawCount = 0;
    pendingSkipCount = 0;
    forcedSuit = null;
    displayedSuitEffect = null;
    playedCardBeginOffset = const Offset(0, 2.75);
    playedByPlayerIndex = 0;
    playedCardsForField = fieldCard == null ? [] : [fieldCard!];
    selectedIndexes.clear();
    finishOrder.clear();
    canDawnNow = false;
    isHikiDawnNow = false;
    dawnTargetPlayerIndex = null;
    fieldCardPlayerIndex = null;
    showDawnEffect = false;
    dawnEffectIsHikiDawn = false;
    dawnEffectPlayerName = '';
    dawnEffectTargetPlayerName = '';
    showFinishEffect = false;
    finishEffectPlayerName = '';
    finishEffectPlace = 1;
    showDrawEffect = false;
    drawEffectTarget = DrawEffectTarget.self;
    drawEffectCount = 1;
    showTurnStartEffect = false;
    turnStartEffectPlayerName = '';
    showPassEffect = false;
    passEffectPlayerName = '';
    showSkipEffect = false;
    skipEffectPlayerName = '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (players.isEmpty) return;
      _showTurnStartEffect(players[0].name);
    });
    _scheduleCpuTurnIfNeeded();
  }

  void _blockCpuFor(Duration duration) {
    final until = DateTime.now().add(duration);

    if (cpuBlockedUntil == null || until.isAfter(cpuBlockedUntil!)) {
      cpuBlockedUntil = until;
    }
  }

  Duration _remainingCpuBlockDuration() {
    final until = cpuBlockedUntil;
    if (until == null) return Duration.zero;

    final remaining = until.difference(DateTime.now());
    if (remaining.isNegative) {
      cpuBlockedUntil = null;
      return Duration.zero;
    }

    return remaining;
  }

  void _showReachBanner(String playerName) {
    _blockCpuFor(const Duration(milliseconds: 1150));
    setState(() {
      reachBannerPlayerName = playerName;
      showReachBanner = true;
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (reachBannerPlayerName != playerName) return;

      setState(() {
        showReachBanner = false;
      });
    });
  }

void _showDawnEffect({
  required bool isHikiDawn,
  required String fromPlayerName,
  required String toPlayerName,
}) {
  _blockCpuFor(const Duration(milliseconds: 850));
  setState(() {
    dawnEffectIsHikiDawn = isHikiDawn;
    dawnEffectPlayerName = fromPlayerName;
    dawnEffectTargetPlayerName = toPlayerName;
    showDawnEffect = true;
  });

  Future.delayed(const Duration(milliseconds: 750), () {
    if (!mounted) return;

    setState(() {
      showDawnEffect = false;
    });
  });
}

void _showFinishEffect({
  required String playerName,
  required int place,
}) {
  _blockCpuFor(const Duration(milliseconds: 1050));
  setState(() {
    finishEffectPlayerName = playerName;
    finishEffectPlace = place;
    showFinishEffect = true;
  });

  Future.delayed(const Duration(milliseconds: 950), () {
    if (!mounted) return;

    setState(() {
      showFinishEffect = false;
    });
  });
}


void _showDrawEffect({
  required int playerIndex,
  required int count,
}) {
  _blockCpuFor(const Duration(milliseconds: 620));
  final target = switch (playerIndex) {
    0 => DrawEffectTarget.self,
    1 => DrawEffectTarget.left,
    2 => DrawEffectTarget.top,
    3 => DrawEffectTarget.right,
    _ => DrawEffectTarget.self,
  };

  setState(() {
    drawEffectTarget = target;
    drawEffectCount = count;
    showDrawEffect = true;
  });

  Future.delayed(const Duration(milliseconds: 560), () {
    if (!mounted) return;

    setState(() {
      showDrawEffect = false;
    });
  });
}

  void _showTurnStartEffect(String playerName) {
    _blockCpuFor(const Duration(milliseconds: 900));
    setState(() {
      turnStartEffectPlayerName = playerName;
      showTurnStartEffect = true;
    });

    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      if (turnStartEffectPlayerName != playerName) return;

      setState(() {
        showTurnStartEffect = false;
      });
    });
  }

  void _showPassEffect(String playerName) {
    _blockCpuFor(const Duration(milliseconds: 760));
    setState(() {
      passEffectPlayerName = playerName;
      showPassEffect = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (passEffectPlayerName != playerName) return;

      setState(() {
        showPassEffect = false;
      });
    });
  }

  void _showSkipEffect(String playerName) {
  _blockCpuFor(const Duration(milliseconds: 820));
  setState(() {
    skipEffectPlayerName = playerName;
    showSkipEffect = true;
  });

  Future.delayed(const Duration(milliseconds: 760), () {
    if (!mounted) return;
    if (skipEffectPlayerName != playerName) return;

    setState(() {
      showSkipEffect = false;
    });
  });
}

  void _checkDawnChance({
    required PlayingCard playedCard,
    required int playedByIndex,
  }) {
    if (playedByIndex == 0) {
      canDawnNow = false;
      isHikiDawnNow = false;
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
    isHikiDawnNow = false;
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
    final dawnMessage = isHikiDawnNow ? '引きどん成功！' : 'ドーン成功！';
    final wasHikiDawn = isHikiDawnNow;

    setState(() {
      targetPlayer.hand.addAll(dawnCards);
      targetPlayer.hasFinished = false;
      finishOrder.remove(targetPlayer.name);
      currentPlayerIndex = targetIndex;
      hasDrawnThisTurn = false;
      mustDrawAgain = false;
      selectedIndexes.clear();

      dawnPlayer.hand.clear();
      dawnPlayer.hasFinished = true;
      finishOrder.add(dawnPlayer.name);
      dawnPlayer.isReach = false;

      canDawnNow = false;
      isHikiDawnNow = false;
      dawnTargetPlayerIndex = null;
    });

    _showDawnEffect(
      isHikiDawn: wasHikiDawn,
      fromPlayerName: dawnPlayer.name,
      toPlayerName: targetPlayer.name,
    );

    if (dawnPlayer.hasFinished) {
      final finishedPlayerName = dawnPlayer.name;
      final finishedPlace = finishOrder.indexOf(dawnPlayer.name) + 1;

      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;

        _showFinishEffect(
          playerName: finishedPlayerName,
          place: finishedPlace,
        );
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(dawnMessage),
        duration: const Duration(milliseconds: 1000),
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

  Future<void> _drawOneCard() async {
    _recycleDiscardPileIfNeeded();
    if (deck.isEmpty) return;
    if (hasDrawnThisTurn && !mustDrawAgain) return;

    final isPenaltyDraw = pendingDrawCount > 0;
    final drawCount = isPenaltyDraw ? pendingDrawCount : 1;
    final drawerIndex = currentPlayerIndex;

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
        isHikiDawnNow = true;
        dawnTargetPlayerIndex = lastPlayerIndex;
      } else {
        canDawnNow = false;
        isHikiDawnNow = false;
        dawnTargetPlayerIndex = null;
      }
    });

    if (!mounted) return;

    _showDrawEffect(
      playerIndex: drawerIndex,
      count: drawCount,
    );

    setState(() {
      showFloatingReachPrompt = currentPlayerIndex == 0 &&
          !currentPlayer.isReach &&
          RuleService.canReach(currentPlayer.hand) &&
          !hasDeclinedReachThisTurn;
    });
  }
void _goToNextTurn({Duration delayBeforeNextEffect = Duration.zero}) {
  if (players.isEmpty) return;
  final skippedPlayerNames = <String>[];

  setState(() {
    selectedIndexes.clear();
    hasDrawnThisTurn = false;
    hasDeclinedReachThisTurn = false;
    showFloatingReachPrompt = false;
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
        skippedPlayerNames.add(players[nextIndex].name);
        skipRemaining--;
        continue;
      }

      currentPlayerIndex = nextIndex;
      break;
    }
  });

  final shouldShowSkip = skippedPlayerNames.isNotEmpty;
  final skippedPlayerName = shouldShowSkip ? skippedPlayerNames.last : null;

  Future.delayed(delayBeforeNextEffect, () {
    if (!mounted) return;

    if (shouldShowSkip && skippedPlayerName != null) {
      _showSkipEffect(skippedPlayerName);
    }

    final afterSkipDelay = shouldShowSkip
        ? const Duration(milliseconds: 860)
        : Duration.zero;

    Future.delayed(afterSkipDelay, () {
      if (!mounted) return;

      if (players.isNotEmpty && currentPlayerIndex == 0) {
        _showTurnStartEffect(currentPlayer.name);
      }

      _scheduleCpuTurnIfNeeded();
    });
  });
}

  void _scheduleCpuTurnIfNeeded() {
    if (players.isEmpty) return;
    if (currentPlayerIndex == 0) return;
    if (canDawnNow) return;

    final remainingBlock = _remainingCpuBlockDuration();
    final delay = remainingBlock > Duration.zero
        ? remainingBlock + const Duration(milliseconds: 420)
        : const Duration(milliseconds: 950);

    Future.delayed(delay, () {
      if (!mounted) return;
      if (players.isEmpty) return;
      if (currentPlayerIndex == 0) return;
      if (canDawnNow) return;

      final stillBlocked = _remainingCpuBlockDuration();
      if (stillBlocked > Duration.zero) {
        _scheduleCpuTurnIfNeeded();
        return;
      }

      _playCpuTurn();
    });
  }

  void _playCpuTurn() {
    final cpu = currentPlayer;
    var didFinish = false;
    var finishedPlayerName = cpu.name;
    var finishedPlace = 0;
    var didDeclareReach = false;

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
          finishedPlace = finishOrder.length + 1;
          finishOrder.add(cpu.name);
          didFinish = true;
        }
      });
      if (didFinish && !canDawnNow) {
        _showFinishEffect(
          playerName: finishedPlayerName,
          place: finishedPlace,
        );
      }
      _refreshReachState(cpu);
      if (RuleService.canReach(cpu.hand)) {
        cpu.isReach = true;
        didDeclareReach = true;
        _showReachBanner(cpu.name);
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
      final drawerIndex = currentPlayerIndex;

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
      _showDrawEffect(
        playerIndex: drawerIndex,
        count: drawCount,
      );

      Future.delayed(const Duration(milliseconds: 640), () {
        if (!mounted) return;
        _showPassEffect(cpu.name);
      });

      _goToNextTurn(delayBeforeNextEffect: const Duration(milliseconds: 1420));
      return;
    }

    _goToNextTurn(
      delayBeforeNextEffect: didFinish
          ? const Duration(milliseconds: 1080)
          : didDeclareReach
              ? const Duration(milliseconds: 1160)
              : Duration.zero,
    );
  }

  void _passTurn() {
    if (mustDrawAgain) return;

    final passerName = currentPlayer.name;
    _showPassEffect(passerName);

    Future.delayed(const Duration(milliseconds: 360), () {
      if (!mounted) return;
      _goToNextTurn();
    });
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

    var didFinish = false;
    var finishedPlayerName = currentPlayer.name;
    var finishedPlace = 0;
    var didDeclareReach = false;
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

  setState(() {
    displayedSuitEffect = selectedForcedSuit;
  });

  Future.delayed(const Duration(milliseconds: 500), () {
    if (!mounted) return;

    setState(() {
      if (displayedSuitEffect == selectedForcedSuit) {
        displayedSuitEffect = null;
      }
    });
  });
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
        finishedPlace = finishOrder.length + 1;
        finishOrder.add(currentPlayer.name);
        didFinish = true;
      }

      mustDrawAgain = false;
      selectedIndexes.clear();
    });

    if (didFinish && !canDawnNow) {
      _showFinishEffect(
        playerName: finishedPlayerName,
        place: finishedPlace,
      );
    }
    if (!currentPlayer.isReach && RuleService.canReach(currentPlayer.hand)) {
      final shouldReach = await _confirmReachAfterPlay();
      if (shouldReach) {
        setState(() {
          currentPlayer.isReach = true;
        });
        didDeclareReach = true;
        _showReachBanner(currentPlayer.name);
      }
    }
    _refreshReachState(currentPlayer);
    _goToNextTurn(
      delayBeforeNextEffect: didFinish
          ? const Duration(milliseconds: 1080)
          : didDeclareReach
              ? const Duration(milliseconds: 1160)
              : Duration.zero,
    );
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
      showFloatingReachPrompt = false;
    });
    _showReachBanner(currentPlayer.name);
  }

  void _declineReach() {
    setState(() {
      hasDeclinedReachThisTurn = true;
      showFloatingReachPrompt = false;
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
                         child: Text(
                           _suitLabel(suit),
                           style: TextStyle(
                             color: _suitColor(suit),
                             fontSize: 26,
                             fontWeight: FontWeight.w900,
                           ),
                         ),
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
                label: Text(
                  isHikiDawnNow ? '引きどん！' : 'ドーン！',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
            const SizedBox(height: 14),
            ActionButtons(
              canPlay: _canPlaySelectedCards(),
              canDraw: currentPlayerIndex == 0 &&
                  selectedIndexes.isEmpty &&
                  (!hasDrawnThisTurn || mustDrawAgain),
              canPass: currentPlayerIndex == 0 &&
                  hasDrawnThisTurn &&
                  !mustDrawAgain,
              canReach: false,
              pendingDrawCount: pendingDrawCount,
              onPlay: _playSelectedCards,
              onDraw: _drawOneCard,
              onPass: _passTurn,
              onReach: _declareReach,
            ),

            const SizedBox(height: 10),
            SizedBox(
              height: 26,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: players[0].isReach
                    ? _StatusChip(
                        key: const ValueKey('player-reach'),
                        label: 'あなた：リーチ中 ${RuleService.handTotal(players[0].hand)}',
                      )
                    : const SizedBox(
                        key: ValueKey('player-normal'),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            PlayerHandArea(
              hand: players[0].hand,
              selectedIndexes: selectedIndexes,
              canSelect: currentPlayerIndex == 0,
              playableIndexes: _playableIndexesForPlayerHand(),
              onCardTap: _toggleSelectedCard,
            ),
            const SizedBox(height: 2),
            ],
              ],
          ),
            
            Positioned.fill(
              child: ReachBanner(
                playerName: reachBannerPlayerName,
                visible: showReachBanner,
              ),
            ),
            Positioned.fill(
              child: DawnEffect(
                visible: showDawnEffect,
                isHikiDawn: dawnEffectIsHikiDawn,
                fromPlayerName: dawnEffectPlayerName,
                toPlayerName: dawnEffectTargetPlayerName,
              ),
            ),
            Positioned.fill(
              child: FinishEffect(
                visible: showFinishEffect,
                playerName: finishEffectPlayerName,
                place: finishEffectPlace,
              ),
            ),
            Positioned.fill(
              child: DrawEffect(
                visible: showDrawEffect,
                target: drawEffectTarget,
                count: drawEffectCount,
              ),
            ),
            Positioned.fill(
              child: TurnStartEffect(
                visible: showTurnStartEffect,
                playerName: turnStartEffectPlayerName,
              ),
            ),
            Positioned.fill(
              child: PassEffect(
                visible: showPassEffect,
                playerName: passEffectPlayerName,
              ),
            ),
            Positioned.fill(
              child: SkipEffect(
                visible: showSkipEffect,
                playerName: skipEffectPlayerName,
              ),
            ),
            if (showFloatingReachPrompt &&
                currentPlayerIndex == 0 &&
                RuleService.canReach(currentPlayer.hand) &&
                !currentPlayer.isReach &&
                !hasDeclinedReachThisTurn)
              Positioned(
                bottom: 180,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: _declineReach,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.16),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('言わない'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _declareReach,
                        icon: const Icon(Icons.flash_on_rounded, size: 18),
                        label: const Text('リーチ'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC857),
                          foregroundColor: const Color(0xFF0E4B3C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned.fill(
              child: SuitChangeEffect(
                visible: displayedSuitEffect != null,
                suitLabel: displayedSuitEffect == null
                    ? ''
                    : _suitLabel(displayedSuitEffect!),
                suitColor: displayedSuitEffect == null
                    ? Colors.transparent
                    : _suitColor(displayedSuitEffect!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    super.key,
    required this.label,
  });

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