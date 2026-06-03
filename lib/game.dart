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
import 'services/turn_order_service.dart';
import 'widgets/turn_order/turn_order_overlay.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    this.playerCount = 4,
    this.useJokers = false,
  });

  final int playerCount;
  final bool useJokers;

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
  final List<int> turnOrderIndexes = [];
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
  final Map<String, int> finishPlaces = {};
  int drawChainId = 0;
  int? pendingFinishPlayerIndex;
  int? pendingFinishDrawChainId;
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
  bool isPlayerTurnReady = false;
  int? highlightedDrawnCardIndex;

  bool showTurnStartEffect = false;
  String turnStartEffectPlayerName = '';
  bool showPassEffect = false;
  String passEffectPlayerName = '';

  bool showSkipEffect = false;
String skipEffectPlayerName = '';
  DateTime? cpuBlockedUntil;

  bool gameOverDialogShown = false;

  bool shouldEndTurnAfterFloatingReachChoice = false;

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
    if (!widget.useJokers) {
      deck.removeWhere((card) => card.isJoker);
    }

    DeckService.shuffleDeck(deck);
    discardPile.clear();

    final playerCount = widget.playerCount.clamp(2, 4);
    final playerNames = ['あなた', 'CPU 1', 'CPU 2', 'CPU 3'];

    players
      ..clear()
      ..addAll(
        List.generate(playerCount, (index) {
          return PlayerState(
            name: playerNames[index],
            hand: DeckService.drawCards(deck, 7),
          );
        }),
      );

    turnOrderIndexes
      ..clear()
      ..addAll(List.generate(players.length, (index) => index));

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
    gameOverDialogShown = false;
    finishOrder.clear();
    finishPlaces.clear();
    drawChainId = 0;
    pendingFinishPlayerIndex = null;
    pendingFinishDrawChainId = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (players.isEmpty) return;
      _showTurnOrderSelection();
    });
  }

  Future<void> _showTurnOrderSelection() async {
    if (!mounted) return;
    if (players.isEmpty) return;
    if (deck.isEmpty) return;

    final targetCard = fieldCard;
    if (targetCard == null) return;

    final result = await showDialog<TurnOrderResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return TurnOrderOverlay(
          players: players,
          targetCard: targetCard,
          limitSeconds: 5,
        );
      },
    );

    if (!mounted) return;

    final orderedIndexes = result?.orderedPlayerIndexes ??
        List.generate(players.length, (index) => index);

    setState(() {
      turnOrderIndexes
        ..clear()
        ..addAll(
          orderedIndexes.where(
            (index) => index >= 0 && index < players.length,
          ),
        );

      if (turnOrderIndexes.isEmpty) {
        turnOrderIndexes.addAll(List.generate(players.length, (index) => index));
      }

      currentPlayerIndex = turnOrderIndexes.first;
    });

    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (gameOverDialogShown) return;
      _showTurnStartEffect(currentPlayer.name);
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
    1 => players.length == 2
        ? DrawEffectTarget.top
        : DrawEffectTarget.left,
    2 => players.length == 3
        ? DrawEffectTarget.right
        : DrawEffectTarget.top,
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
      isPlayerTurnReady = false;
    });

    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      if (turnStartEffectPlayerName != playerName) return;

      setState(() {
        turnStartEffectPlayerName = playerName;
        showTurnStartEffect = false;
        isPlayerTurnReady = currentPlayerIndex == 0 && playerName == players[0].name;
      });
    });
  }

  void _showPassEffect(
    String playerName, {
    Duration visibleDuration = const Duration(milliseconds: 700),
    Duration blockDuration = const Duration(milliseconds: 760),
  }) {
    _blockCpuFor(blockDuration);
    setState(() {
      passEffectPlayerName = playerName;
      showPassEffect = true;
    });

    Future.delayed(visibleDuration, () {
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

int _registerFinishedPlayer(PlayerState player, {int? place}) {
  final resolvedPlace = place ?? (finishPlaces.length + 1);

  player.hasFinished = true;
  player.isReach = false;

  if (!finishOrder.contains(player.name)) {
    finishOrder.add(player.name);
  }

  finishPlaces[player.name] = resolvedPlace;
  return resolvedPlace;
}

void _markPendingFinishByDrawPenalty(PlayerState player) {
  final index = players.indexOf(player);
  if (index < 0) return;

  pendingFinishPlayerIndex = index;
  pendingFinishDrawChainId = drawChainId;
}

void _clearPendingFinishFor(PlayerState player) {
  final index = players.indexOf(player);
  if (pendingFinishPlayerIndex != index) return;

  pendingFinishPlayerIndex = null;
  pendingFinishDrawChainId = null;
}

int? _resolvePendingFinishAfterPenaltyDraw({
  required int drawerIndex,
}) {
  final pendingIndex = pendingFinishPlayerIndex;
  final pendingChainId = pendingFinishDrawChainId;

  if (pendingIndex == null || pendingChainId == null) return null;
  if (pendingChainId != drawChainId) return null;
  if (pendingIndex < 0 || pendingIndex >= players.length) {
    pendingFinishPlayerIndex = null;
    pendingFinishDrawChainId = null;
    return null;
  }

  final pendingPlayer = players[pendingIndex];

  if (drawerIndex == pendingIndex) {
    pendingFinishPlayerIndex = null;
    pendingFinishDrawChainId = null;
    return null;
  }

  pendingFinishPlayerIndex = null;
  pendingFinishDrawChainId = null;
  return _registerFinishedPlayer(pendingPlayer);
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

  // === CPU Dawn support ===
  List<int> _cpuDawnPlayerIndexesFor({
    required PlayingCard playedCard,
    required int playedByIndex,
  }) {
    final indexes = <int>[];

    for (int i = 1; i < players.length; i++) {
      if (i == playedByIndex) continue;

      final player = players[i];
      if (player.hasFinished) continue;

      final canDawn = RuleService.canDawn(
        hand: player.hand,
        playedCard: playedCard,
        hasDeclaredReach: player.isReach,
      );

      if (canDawn) {
        indexes.add(i);
      }
    }

    return indexes;
  }

  void _scheduleCpuDawnsIfPossible({
    required PlayingCard playedCard,
    required int playedByIndex,
  }) {
    if (gameOverDialogShown) return;

    final cpuDawnIndexes = _cpuDawnPlayerIndexesFor(
      playedCard: playedCard,
      playedByIndex: playedByIndex,
    );

    if (cpuDawnIndexes.isEmpty) return;

    Future.delayed(const Duration(milliseconds: 720), () {
      if (!mounted) return;
      if (gameOverDialogShown) return;
      if (playedByIndex >= players.length) return;

      final validIndexes = cpuDawnIndexes
          .where((index) => index < players.length && !players[index].hasFinished)
          .toList();

      if (validIndexes.isEmpty) return;

      _performCpuDawns(
        dawnPlayerIndexes: validIndexes,
        targetPlayerIndex: playedByIndex,
      );
    });
  }

  void _performCpuDawns({
    required List<int> dawnPlayerIndexes,
    required int targetPlayerIndex,
    bool isHikiDawn = false,
  }) {
    if (gameOverDialogShown) return;
    if (dawnPlayerIndexes.isEmpty) return;
    if (targetPlayerIndex < 0 || targetPlayerIndex >= players.length) return;

    final targetPlayer = players[targetPlayerIndex];
    final validDawnPlayers = dawnPlayerIndexes
        .where((index) => index > 0 && index < players.length)
        .map((index) => players[index])
        .where((player) => player.hand.isNotEmpty && !player.hasFinished)
        .toList();

    if (validDawnPlayers.isEmpty) return;

    final samePlace = finishPlaces.length + 1;
    final dawnPlayerNames = validDawnPlayers.map((player) => player.name).join('・');

    setState(() {
      targetPlayer.hasFinished = false;
      finishOrder.remove(targetPlayer.name);
      finishPlaces.remove(targetPlayer.name);
      _clearPendingFinishFor(targetPlayer);

      currentPlayerIndex = targetPlayerIndex;
      hasDrawnThisTurn = false;
      hasDeclinedReachThisTurn = false;
      showFloatingReachPrompt = false;
      mustDrawAgain = false;
      selectedIndexes.clear();

      for (final dawnPlayer in validDawnPlayers) {
        final dawnCards = List<PlayingCard>.from(dawnPlayer.hand);
        targetPlayer.hand.addAll(dawnCards);
        dawnPlayer.hand.clear();
        _registerFinishedPlayer(dawnPlayer, place: samePlace);
      }

      canDawnNow = false;
      isHikiDawnNow = false;
      dawnTargetPlayerIndex = null;
    });

    _showDawnEffect(
      isHikiDawn: isHikiDawn,
      fromPlayerName: dawnPlayerNames,
      toPlayerName: targetPlayer.name,
    );

    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      if (gameOverDialogShown) return;

      for (final dawnPlayer in validDawnPlayers) {
        _showFinishEffect(
          playerName: dawnPlayer.name,
          place: finishPlaces[dawnPlayer.name] ?? samePlace,
        );
      }
    });

    if (_isGameFinished()) {
      _showGameOverDialog(
        delay: const Duration(milliseconds: 1900),
      );
      return;
    }

    if (targetPlayerIndex == 0) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (gameOverDialogShown) return;
        if (players.isEmpty || currentPlayerIndex != 0) return;
        _showTurnStartEffect(currentPlayer.name);
      });
    } else {
      _scheduleCpuTurnIfNeeded();
    }
  }

  void _performDawn() {
    if (!canDawnNow) return;
    if (dawnTargetPlayerIndex == null) return;
    if (players.isEmpty) return;

    final playedCard = fieldCard;
    if (playedCard == null) return;

    final playerDawnPlayer = players[0];
    final targetIndex = dawnTargetPlayerIndex!;
    final targetPlayer = players[targetIndex];
    final dawnMessage = isHikiDawnNow ? '引きどん成功！' : 'ドーン成功！';
    final wasHikiDawn = isHikiDawnNow;

    final cpuDawnIndexes = _cpuDawnPlayerIndexesFor(
      playedCard: playedCard,
      playedByIndex: targetIndex,
    );

    final cpuDawnPlayers = cpuDawnIndexes
        .where((index) => index > 0 && index < players.length)
        .map((index) => players[index])
        .where((player) => player.hand.isNotEmpty && !player.hasFinished)
        .toList();

    final allDawnPlayers = <PlayerState>[
      playerDawnPlayer,
      ...cpuDawnPlayers,
    ];

    final samePlace = finishPlaces.length + 1;
    final dawnPlayerNames = allDawnPlayers.map((player) => player.name).join('・');

    setState(() {
      targetPlayer.hasFinished = false;
      finishOrder.remove(targetPlayer.name);
      finishPlaces.remove(targetPlayer.name);
      _clearPendingFinishFor(targetPlayer);
      currentPlayerIndex = targetIndex;
      hasDrawnThisTurn = false;
      hasDeclinedReachThisTurn = false;
      mustDrawAgain = false;
      selectedIndexes.clear();
      showFloatingReachPrompt = false;

      for (final dawnPlayer in allDawnPlayers) {
        final dawnCards = List<PlayingCard>.from(dawnPlayer.hand);
        targetPlayer.hand.addAll(dawnCards);
        dawnPlayer.hand.clear();
        _registerFinishedPlayer(dawnPlayer, place: samePlace);
      }

      canDawnNow = false;
      isHikiDawnNow = false;
      dawnTargetPlayerIndex = null;
    });

    _showDawnEffect(
      isHikiDawn: wasHikiDawn,
      fromPlayerName: dawnPlayerNames,
      toPlayerName: targetPlayer.name,
    );

    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      if (gameOverDialogShown) return;

      for (final dawnPlayer in allDawnPlayers) {
        _showFinishEffect(
          playerName: dawnPlayer.name,
          place: finishPlaces[dawnPlayer.name] ?? samePlace,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(dawnMessage),
        duration: const Duration(milliseconds: 1000),
      ),
    );

    if (_isGameFinished()) {
      _showGameOverDialog(
        delay: const Duration(milliseconds: 1900),
      );
      return;
    }

    if (targetIndex == 0) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (gameOverDialogShown) return;
        if (players.isEmpty || currentPlayerIndex != 0) return;
        _showTurnStartEffect(currentPlayer.name);
      });
    } else {
      _scheduleCpuTurnIfNeeded();
    }
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
    final pendingIndexBeforeResolve = pendingFinishPlayerIndex;
    String? resolvedPendingFinishPlayerName;
    int? resolvedPendingFinishPlace;

    var drawnCards = <PlayingCard>[];

    setState(() {
      final insertStartIndex = currentPlayer.hand.length;
      drawnCards = _drawCardsSafely(drawCount);
      currentPlayer.hand.addAll(drawnCards);

      highlightedDrawnCardIndex =
          drawerIndex == 0 && drawnCards.isNotEmpty
              ? insertStartIndex + drawnCards.length - 1
              : null;

      resolvedPendingFinishPlace = isPenaltyDraw
          ? _resolvePendingFinishAfterPenaltyDraw(drawerIndex: drawerIndex)
          : null;

      if (resolvedPendingFinishPlace != null &&
          pendingIndexBeforeResolve != null &&
          pendingIndexBeforeResolve >= 0 &&
          pendingIndexBeforeResolve < players.length) {
        resolvedPendingFinishPlayerName = players[pendingIndexBeforeResolve].name;
      }
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
            hasDeclaredReach: true,
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

    if (resolvedPendingFinishPlace != null &&
        resolvedPendingFinishPlayerName != null) {
      _showFinishEffect(
        playerName: resolvedPendingFinishPlayerName!,
        place: resolvedPendingFinishPlace!,
      );
    }

    if (_isGameFinished()) {
      _showGameOverDialog(
        delay: const Duration(milliseconds: 1200),
      );
      return;
    }

    setState(() {
      showFloatingReachPrompt = currentPlayerIndex == 0 &&
          !canDawnNow &&
          !currentPlayer.isReach &&
          RuleService.canReach(currentPlayer.hand) &&
          !hasDeclinedReachThisTurn;
    });
  }
  bool _isGameFinished() {
    return players.where((player) => !player.hasFinished).length <= 1;
  }

  List<PlayerState> _gameResultOrder() {
    final result = [...players];

    result.sort((a, b) {
      final aPlace = finishPlaces[a.name] ?? 999;
      final bPlace = finishPlaces[b.name] ?? 999;
      if (aPlace != bPlace) return aPlace.compareTo(bPlace);
      return players.indexOf(a).compareTo(players.indexOf(b));
    });

    return result;
  }

  void _showGameOverDialog({Duration delay = Duration.zero}) {
    if (gameOverDialogShown) return;
    gameOverDialogShown = true;

    Future.delayed(delay, () {
      if (!mounted) return;

      final resultOrder = _gameResultOrder();

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF123F35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              '試合終了！',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFC857),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < resultOrder.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 86,
                          child: Text(
                            '${finishPlaces[resultOrder[i].name] ?? i + 1}位',
                            style: const TextStyle(
                              color: Color(0xFFFFC857),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            resultOrder[i].name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).maybePop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      '終わる',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _startGame();
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC857),
                      foregroundColor: const Color(0xFF0E4B3C),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'もう一度',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    });
  }

  void _resetGame() {
    setState(() {
      _startGame();
    });
  }

void _skipToResult() {
  setState(() {
    selectedIndexes.clear();
    canDawnNow = false;
    isHikiDawnNow = false;
    dawnTargetPlayerIndex = null;
    showFloatingReachPrompt = false;
  });

  _showGameOverDialog();
}

void _goToNextTurn({Duration delayBeforeNextEffect = Duration.zero}) {
  if (gameOverDialogShown) return;
  if (players.isEmpty) return;
  final skippedPlayerNames = <String>[];

  setState(() {
    selectedIndexes.clear();
    highlightedDrawnCardIndex = null;
    isPlayerTurnReady = false;
    hasDrawnThisTurn = false;
    hasDeclinedReachThisTurn = false;
    showFloatingReachPrompt = false;
    mustDrawAgain = false;

    int skipRemaining = pendingSkipCount;
    pendingSkipCount = 0;

    final activeTurnOrder = turnOrderIndexes
        .where((index) => index >= 0 && index < players.length)
        .toList();

    if (activeTurnOrder.isEmpty) {
      activeTurnOrder.addAll(List.generate(players.length, (index) => index));
    }

    var orderPosition = activeTurnOrder.indexOf(currentPlayerIndex);
    if (orderPosition < 0) orderPosition = 0;

    while (true) {
      orderPosition = (orderPosition + 1) % activeTurnOrder.length;
      final nextIndex = activeTurnOrder[orderPosition];

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

  if (_isGameFinished()) {
    _showGameOverDialog(
      delay: delayBeforeNextEffect + const Duration(milliseconds: 1150),
    );
    return;
  }

  final shouldShowSkip = skippedPlayerNames.isNotEmpty;
  final skippedPlayerName = shouldShowSkip ? skippedPlayerNames.last : null;

  Future.delayed(delayBeforeNextEffect, () {
    if (!mounted) return;
    if (gameOverDialogShown) return;

    if (shouldShowSkip && skippedPlayerName != null) {
      _showSkipEffect(skippedPlayerName);
    }

    final afterSkipDelay = shouldShowSkip
        ? const Duration(milliseconds: 860)
        : Duration.zero;

    Future.delayed(afterSkipDelay, () {
      if (!mounted) return;
      if (gameOverDialogShown) return;

      if (players.isNotEmpty && currentPlayerIndex == 0) {
        Future.delayed(const Duration(milliseconds: 520), () {
          if (!mounted) return;
          if (gameOverDialogShown) return;
          if (players.isEmpty || currentPlayerIndex != 0) return;
          _showTurnStartEffect(currentPlayer.name);
        });
      }

      _scheduleCpuTurnIfNeeded();
    });
  });
}

  void _scheduleCpuTurnIfNeeded() {
    if (gameOverDialogShown) return;
    if (players.isEmpty) return;
    if (currentPlayerIndex == 0) return;
    if (canDawnNow) return;

    final remainingBlock = _remainingCpuBlockDuration();
    final delay = remainingBlock > Duration.zero
        ? remainingBlock + const Duration(milliseconds: 250)
        : const Duration(milliseconds: 850);

    Future.delayed(delay, () {
      if (!mounted) return;
      if (gameOverDialogShown) return;
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

  List<int> _cpuSelectedIndexesForPlay({
    required PlayerState cpu,
    required int firstPlayableIndex,
  }) {
    final hand = cpu.hand;
    final selectedIndexes = <int>[firstPlayableIndex];

    for (int i = 0; i < hand.length; i++) {
      if (i == firstPlayableIndex) continue;

      final candidateIndexes = [...selectedIndexes, i];
      final candidateCards = candidateIndexes.map((index) => hand[index]).toList();

      if (!RuleService.hasSameRank(candidateCards)) continue;

      if (pendingDrawCount > 0) {
        if (RuleService.drawPenaltyCountForPlay(candidateCards) == 0) {
          continue;
        }
      } else if (!RuleService.canPlayCards(
        cards: candidateCards,
        fieldCard: fieldCard,
        forcedSuit: forcedSuit,
      )) {
        continue;
      }

      final baseCard = candidateCards.lastWhere(
        (card) => !card.isJoker,
        orElse: () => candidateCards.last,
      );

      final wouldFinish = candidateCards.length == hand.length;
      if (wouldFinish && RuleService.isForbiddenFinishCard(baseCard)) {
        continue;
      }

      selectedIndexes.add(i);
    }

    return selectedIndexes;
  }

  List<PlayingCard> _cpuOrderCardsForTopSuit({
    required List<PlayingCard> selectedCards,
    required List<PlayingCard> remainingCards,
  }) {
    final normalCards = selectedCards.where((card) => !card.isJoker).toList();
    if (normalCards.length <= 1) return selectedCards;

    int suitScore(CardSuit suit) {
      return remainingCards
          .where((card) => !card.isJoker && card.suit == suit)
          .length;
    }

    PlayingCard bestTopCard = normalCards.first;
    var bestScore = suitScore(bestTopCard.suit);

    for (final card in normalCards.skip(1)) {
      final score = suitScore(card.suit);
      if (score > bestScore) {
        bestTopCard = card;
        bestScore = score;
      }
    }

    return [
      ...selectedCards.where((card) => card.isJoker),
      ...normalCards.where((card) => card != bestTopCard),
      bestTopCard,
    ];
  }

  CardSuit _chooseCpuForcedSuit(PlayerState cpu) {
    final suits = CardSuit.values
        .where((suit) => suit != CardSuit.joker)
        .toList();

    CardSuit bestSuit = suits.first;
    var bestCount = -1;

    for (final suit in suits) {
      final count = cpu.hand
          .where((card) => !card.isJoker && card.suit == suit)
          .length;

      if (count > bestCount) {
        bestSuit = suit;
        bestCount = count;
      }
    }

    return bestSuit;
  }

  void _playCpuTurn() {
    if (gameOverDialogShown) return;
    final cpu = currentPlayer;
    var didFinish = false;
    var finishedPlayerName = cpu.name;
    var finishedPlace = 0;
    var didDeclareReach = false;
    var didChangeSuit = false;

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
      final cpuSelectedIndexes = _cpuSelectedIndexesForPlay(
        cpu: cpu,
        firstPlayableIndex: playableIndex,
      );
      final selectedCards = cpuSelectedIndexes.map((index) => cpu.hand[index]).toList();
      final remainingCards = cpu.hand
          .asMap()
          .entries
          .where((entry) => !cpuSelectedIndexes.contains(entry.key))
          .map((entry) => entry.value)
          .toList();
      final orderedSelectedCards = _cpuOrderCardsForTopSuit(
        selectedCards: selectedCards,
        remainingCards: remainingCards,
      );
      final baseCard = orderedSelectedCards.lastWhere(
        (card) => !card.isJoker,
        orElse: () => orderedSelectedCards.last,
      );
      final sortedIndexes = cpuSelectedIndexes.toList()
        ..sort((a, b) => b.compareTo(a));

      setState(() {
        playedByPlayerIndex = currentPlayerIndex;
        playedCardsForField = List<PlayingCard>.from(orderedSelectedCards);
        _setFieldCard(
          baseCard,
          playedByIndex: currentPlayerIndex,
        );
        _checkDawnChance(
          playedCard: baseCard,
          playedByIndex: currentPlayerIndex,
        );

        for (final index in sortedIndexes) {
          cpu.hand.removeAt(index);
        }

        final penaltyCount = RuleService.drawPenaltyCountForPlay(orderedSelectedCards);
        if (penaltyCount > 0 && pendingDrawCount == 0) {
          drawChainId++;
        }

        if (penaltyCount > 0) {
          pendingDrawCount += penaltyCount;
        } else {
          pendingDrawCount = 0;
        }

        if (RuleService.isSkipCard(baseCard)) {
          pendingSkipCount += orderedSelectedCards.length;
        }

        if (RuleService.isSuitChangeCard(baseCard)) {
          forcedSuit = _chooseCpuForcedSuit(cpu);
          displayedSuitEffect = forcedSuit;
          didChangeSuit = true;
        } else {
          forcedSuit = null;
        }

if (cpu.hand.isEmpty) {
  if (penaltyCount > 0) {
    _markPendingFinishByDrawPenalty(cpu);
  } else {
    finishedPlace = _registerFinishedPlayer(cpu);
    didFinish = true;
  }
}
    });
      // CPU Dawn support: schedule CPU Dawn if possible after CPU plays a card
      _scheduleCpuDawnsIfPossible(
        playedCard: baseCard,
        playedByIndex: currentPlayerIndex,
      );

      if (didChangeSuit) {
        final changedSuit = forcedSuit;

        Future.delayed(const Duration(milliseconds: 650), () {
          if (!mounted) return;

          setState(() {
            if (displayedSuitEffect == changedSuit) {
              displayedSuitEffect = null;
            }
          });
        });
      }

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
      final pendingIndexBeforeResolve = pendingFinishPlayerIndex;
      String? resolvedPendingFinishPlayerName;
      int? resolvedPendingFinishPlace;
      var canPlayAfterDraw = false;
      int? cpuHikiDawnTargetPlayerIndex;

      setState(() {
        cpu.hand.addAll(_drawCardsSafely(drawCount));

        resolvedPendingFinishPlace = isPenaltyDraw
            ? _resolvePendingFinishAfterPenaltyDraw(drawerIndex: drawerIndex)
            : null;

        if (resolvedPendingFinishPlace != null &&
            pendingIndexBeforeResolve != null &&
            pendingIndexBeforeResolve >= 0 &&
            pendingIndexBeforeResolve < players.length) {
          resolvedPendingFinishPlayerName = players[pendingIndexBeforeResolve].name;
        }

        pendingDrawCount = 0;

        canPlayAfterDraw = RuleService.hasPlayableCard(
          hand: cpu.hand,
          fieldCard: fieldCard,
          forcedSuit: forcedSuit,
        );

        if (isPenaltyDraw && !canPlayAfterDraw) {
          cpu.hand.addAll(_drawCardsSafely(1));

          canPlayAfterDraw = RuleService.hasPlayableCard(
            hand: cpu.hand,
            fieldCard: fieldCard,
            forcedSuit: forcedSuit,
          );
        }

        final currentFieldCard = fieldCard;
        final lastPlayerIndex = fieldCardPlayerIndex;

        if (currentFieldCard != null &&
            lastPlayerIndex != null &&
            lastPlayerIndex != drawerIndex &&
            RuleService.canDawn(
              hand: cpu.hand,
              playedCard: currentFieldCard,
              hasDeclaredReach: true,
            )) {
          cpuHikiDawnTargetPlayerIndex = lastPlayerIndex;
        }

        _refreshReachState(cpu);
      });

      if (resolvedPendingFinishPlace != null &&
          resolvedPendingFinishPlayerName != null) {
        _showFinishEffect(
          playerName: resolvedPendingFinishPlayerName!,
          place: resolvedPendingFinishPlace!,
        );
      }

      if (_isGameFinished()) {
        _showGameOverDialog(
          delay: const Duration(milliseconds: 1200),
        );
        return;
      }

      _showDrawEffect(
        playerIndex: drawerIndex,
        count: drawCount,
      );

      if (cpuHikiDawnTargetPlayerIndex != null) {
        Future.delayed(const Duration(milliseconds: 760), () {
          if (!mounted) return;
          if (gameOverDialogShown) return;
          if (currentPlayerIndex != drawerIndex) return;
          final targetIndex = cpuHikiDawnTargetPlayerIndex!;
          if (targetIndex < 0 || targetIndex >= players.length) return;
          _performCpuDawns(
            dawnPlayerIndexes: [drawerIndex],
            targetPlayerIndex: targetIndex,
            isHikiDawn: true,
          );
        });
        return;
      }

      if (canPlayAfterDraw) {
        Future.delayed(const Duration(milliseconds: 720), () {
          if (!mounted) return;
          if (gameOverDialogShown) return;
          if (currentPlayerIndex != drawerIndex) return;
          _playCpuTurn();
        });
        return;
      }

      Future.delayed(const Duration(milliseconds: 640), () {
        if (!mounted) return;
        _showPassEffect(
          cpu.name,
          visibleDuration: const Duration(milliseconds: 420),
          blockDuration: const Duration(milliseconds: 480),
        );
      });

      _goToNextTurn(
        delayBeforeNextEffect: drawCount > 1
            ? const Duration(milliseconds: 1180)
            : const Duration(milliseconds: 980),
      );
      return;
    }

    _goToNextTurn(
      delayBeforeNextEffect: didFinish
          ? const Duration(milliseconds: 1080)
          : didDeclareReach
              ? const Duration(milliseconds: 1160)
              : didChangeSuit
                  ? const Duration(milliseconds: 780)
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
    var didChangeSuit = false;
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
  didChangeSuit = true;

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
      
      if (penaltyCount > 0 && pendingDrawCount == 0) {
        drawChainId++;
      }

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
        if (penaltyCount > 0) {
          _markPendingFinishByDrawPenalty(currentPlayer);
        }       else {
          finishedPlace = _registerFinishedPlayer(currentPlayer);
          didFinish = true;
        }
      }

      mustDrawAgain = false;
      selectedIndexes.clear();
      highlightedDrawnCardIndex = null;
    });

    // CPU Dawn support: schedule CPU Dawn if possible after player plays cards
    _scheduleCpuDawnsIfPossible(
      playedCard: baseCard,
      playedByIndex: currentPlayerIndex,
    );

    if (didFinish && !canDawnNow) {
      _showFinishEffect(
        playerName: finishedPlayerName,
        place: finishedPlace,
      );
    }
if (!currentPlayer.isReach &&
    RuleService.canReach(currentPlayer.hand)) {
  final shouldReach = await _confirmReachAfterPlay();

  if (shouldReach) {
    setState(() {
      currentPlayer.isReach = true;
      showFloatingReachPrompt = false;
      shouldEndTurnAfterFloatingReachChoice = false;
    });

    didDeclareReach = true;
    _showReachBanner(currentPlayer.name);
  } else {
    setState(() {
      hasDeclinedReachThisTurn = true;
      showFloatingReachPrompt = false;
      shouldEndTurnAfterFloatingReachChoice = false;
    });
  }
}
    _refreshReachState(currentPlayer);
    _goToNextTurn(
      delayBeforeNextEffect: didFinish
          ? const Duration(milliseconds: 1080)
          : didDeclareReach
              ? const Duration(milliseconds: 1160)
              : didChangeSuit
                  ? const Duration(milliseconds: 780)
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

  final shouldEndTurnAfterChoice = shouldEndTurnAfterFloatingReachChoice;

  setState(() {
    currentPlayer.isReach = true;
    showFloatingReachPrompt = false;
    shouldEndTurnAfterFloatingReachChoice = false;
  });

  _showReachBanner(currentPlayer.name);

  if (shouldEndTurnAfterChoice) {
    Future.delayed(const Duration(milliseconds: 760), () {
      if (!mounted) return;
      if (gameOverDialogShown) return;
      if (currentPlayerIndex != 0) return;
      _goToNextTurn(delayBeforeNextEffect: const Duration(milliseconds: 220));
    });
  }
}

void _declineReach() {
  final shouldEndTurnAfterChoice = shouldEndTurnAfterFloatingReachChoice;

  setState(() {
    hasDeclinedReachThisTurn = true;
    showFloatingReachPrompt = false;
    shouldEndTurnAfterFloatingReachChoice = false;
  });

  if (shouldEndTurnAfterChoice) {
    _goToNextTurn(delayBeforeNextEffect: const Duration(milliseconds: 180));
  }
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
    final usableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;

        final isVeryCompactHeight = usableHeight < 700;
        final isCompactHeight = usableHeight < 780;
        final topGap =
        isVeryCompactHeight ? 2.0 : isCompactHeight ? 6.0 : 10.0;
        final topBarHeight =
        isVeryCompactHeight ? 48.0 : isCompactHeight ? 54.0 : 58.0;
        final afterTopBarGap =
        isVeryCompactHeight ? 0.0 : isCompactHeight ? 4.0 : 8.0;
        final afterOpponentGap =
        isVeryCompactHeight ? 2.0 : isCompactHeight ? 6.0 : 10.0;
        final afterTurnBannerGap =
        isVeryCompactHeight ? 0.0 : isCompactHeight ? 2.0 : 6.0;
        final statusHeight =
        isVeryCompactHeight ? 30.0 : isCompactHeight ? 38.0 : 38.0;
        final afterFieldGap =
        isVeryCompactHeight ? 4.0 : isCompactHeight ? 8.0 : 14.0;
        final afterActionGap =
        isVeryCompactHeight ? 2.0 : isCompactHeight ? 6.0 : 10.0;
        final reachStatusHeight =
        isVeryCompactHeight ? 20.0 : isCompactHeight ? 26.0 : 26.0;
        final afterReachStatusGap =
        isVeryCompactHeight ? 0.0 : isCompactHeight ? 2.0 : 4.0;
        final bottomGap =
        isVeryCompactHeight ? 0.0 : isCompactHeight ? 0.0 : 2.0;
        
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
        SizedBox(height: topGap),
        SizedBox(
          height: topBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.topCenter,
              child: Row(
                children: [
                  _TopControlButton(
                    label: '終わる',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  _TopControlButton(
                    label: 'リセット',
                    onPressed: _resetGame,
                  ),
                  const Spacer(),
                  if (players[0].hasFinished)
                    _TopControlButton(
                      label: '観戦をスキップ',
                      isPrimary: true,
                      onPressed: _skipToResult,
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: afterTopBarGap),
            OpponentArea(
              players: players,
              currentPlayerIndex: currentPlayerIndex,
              finishOrder: finishOrder,
              finishPlaces: finishPlaces,
            ),
            SizedBox(height: afterOpponentGap),
            TurnBanner(player: currentPlayer),
            SizedBox(height: afterTurnBannerGap),
            SizedBox(
              height: statusHeight,
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
                2 => players.length == 3
                    ? const Offset(2.8, 0)
                    : const Offset(0, -2.8),
                3 => const Offset(2.8, 0),
                _ => playedCardBeginOffset,
              },
              playedCards: playedCardsForField,
            ),
            SizedBox(height: afterFieldGap),
            ActionButtons(
              canPlay: isPlayerTurnReady &&
                  _canPlaySelectedCards() &&
                  !showFloatingReachPrompt,
              canDraw: isPlayerTurnReady &&
                  currentPlayerIndex == 0 &&
                  selectedIndexes.isEmpty &&
                  (!hasDrawnThisTurn || mustDrawAgain) &&
                  !showFloatingReachPrompt,
              canPass: isPlayerTurnReady &&
                  currentPlayerIndex == 0 &&
                  hasDrawnThisTurn &&
                  !mustDrawAgain &&
                  !showFloatingReachPrompt,
              canReach: false,
              pendingDrawCount: pendingDrawCount,
              onPlay: _playSelectedCards,
              onDraw: _drawOneCard,
              onPass: _passTurn,
              onReach: _declareReach,
            ),

            SizedBox(height: afterActionGap),
            SizedBox(
              height: reachStatusHeight,
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
            SizedBox(height: afterReachStatusGap),
            PlayerHandArea(
              hand: players[0].hand,
              selectedIndexes: selectedIndexes,
              canSelect: isPlayerTurnReady && currentPlayerIndex == 0,
              playableIndexes: _playableIndexesForPlayerHand(),
              highlightedIndex: highlightedDrawnCardIndex,
              onCardTap: _toggleSelectedCard,
            ),
            SizedBox(height: bottomGap),
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
                bottom: 200,
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

class _TopControlButton extends StatelessWidget {
  const _TopControlButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isPrimary
            ? const Color(0xFFFFC857)
            : Colors.white.withOpacity(0.12),
        foregroundColor: isPrimary ? const Color(0xFF0E4B3C) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      child: Text(label),
    );
  }
}