import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:turbo_blackjack/Game/Logic/best_moves.dart';
import 'package:turbo_blackjack/Game/Logic/deck_logic.dart';
import 'package:turbo_blackjack/Settings/settings_global_values.dart';

import '../Data/game_values.dart';
import '../Logic/game_logic.dart';
import 'playing_card_widget.dart';

class PlayTable extends StatefulWidget {
  const PlayTable({super.key});

  @override
  PlayTableState createState() => PlayTableState();
}

class PlayTableState extends State<PlayTable> {
  late Timer _timer;
  Timer? _betHoldDelayTimer;
  Timer? _betHoldRepeatTimer;

  PlayTableState() {
    GameValues.deck.clear();
    GameValues.discardPile.clear();
    DeckLogic.addCardsToDeck();
    GameLogic.createHands();
  }

  String _formatTokens(num value) {
    final double doubleValue = value.toDouble();
    if (doubleValue == doubleValue.roundToDouble()) {
      return doubleValue.toStringAsFixed(0);
    }
    return doubleValue.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopBetHold();
    super.dispose();
  }

  void _startBetHold(void Function() applyStep) {
    _stopBetHold();
    applyStep();
    _betHoldDelayTimer = Timer(const Duration(milliseconds: 400), () {
      _betHoldRepeatTimer =
          Timer.periodic(const Duration(milliseconds: 100), (_) {
        applyStep();
      });
    });
  }

  void _stopBetHold() {
    _betHoldDelayTimer?.cancel();
    _betHoldRepeatTimer?.cancel();
    _betHoldDelayTimer = null;
    _betHoldRepeatTimer = null;
  }

  Widget _buildBetStepButton(Hand hand, {required bool isIncrease}) {
    final bool enabled = isIncrease
        ? GameLogic.canIncreaseBet(hand)
        : GameLogic.canDecreaseBet(hand);

    void applyStep() {
      final int step = isIncrease
          ? GameLogic.getBetIncreaseStep(hand)
          : GameLogic.getBetDecreaseStep(hand);
      if (step <= 0) {
        _stopBetHold();
        return;
      }
      setState(() {
        hand.bet += isIncrease ? step : -step;
      });
    }

    return SizedBox(
      height: SettingsGlobalValues.getIconSize(context),
      width: SettingsGlobalValues.getIconSize(context),
      child: GestureDetector(
        onTapDown: enabled ? (_) => _startBetHold(applyStep) : null,
        onTapUp: (_) => _stopBetHold(),
        onTapCancel: _stopBetHold,
        child: Icon(
          isIncrease ? Icons.add : Icons.remove,
          color: enabled
              ? SettingsGlobalValues.neutralColor
              : SettingsGlobalValues.neutralColor.withValues(alpha: .3),
          size: SettingsGlobalValues.getIconSize(context),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    BestMoves.fToast = FToast();
    BestMoves.fToast.init(context);
    BestMoves.generateMatrix();

    _timer = Timer.periodic(
        const Duration(milliseconds: SettingsGlobalValues.tableRefreshTimeMS),
        (timer) {
      setState(() {});
    });
  }

  Widget _buildPosition(String text, Hand hand) {
    final bool isSelectionPhase =
        !GameValues.isGameStarted && !GameValues.isGameEnded && text != "D";
    final bool isSelected = hand.isPlayed;
    return GestureDetector(
      onTap: isSelectionPhase
          ? () {
              setState(() {
                hand.isPlayed = !hand.isPlayed;
                if (hand.isPlayed) {
                  GameValues.player.hands.add(hand);
                  SettingsGlobalValues.logger.d(
                      "Added hand $text to Player[${GameValues.player.hands}]");
                } else {
                  GameValues.player.hands.remove(hand);
                  hand.bet = 0;
                  SettingsGlobalValues.logger.d(
                      "Removed hand $text to Player[${GameValues.player.hands}]");
                }
              });
            }
          : null,
      child: Container(
        width: SettingsGlobalValues.getCardWidth(context),
        height: SettingsGlobalValues.getCardHeight(context),
        decoration: BoxDecoration(
          color: isSelected
              ? SettingsGlobalValues.positiveColor
              : SettingsGlobalValues.secondColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text,
                  style: TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontSize: SettingsGlobalValues.getFontSize(context))),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    children: [
                      Text('Bet: ${hand.bet}',
                          style: TextStyle(
                              color: SettingsGlobalValues.neutralColor,
                              fontSize:
                                  SettingsGlobalValues.getFontSize(context))),
                      if (!GameValues.isGameStarted)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBetStepButton(hand, isIncrease: false),
                            _buildBetStepButton(hand, isIncrease: true),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardStack(Hand hand, BuildContext context) {
    final cards = hand.cards;
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(builder: (context, constraints) {
      final double preferredHeight =
          SettingsGlobalValues.getMiniCardHeight(context);
      final double maxHeight =
          constraints.maxHeight.isFinite ? constraints.maxHeight : preferredHeight;
      final double cardHeight =
          preferredHeight > maxHeight ? maxHeight : preferredHeight;
      final double cardWidth = cardHeight * PlayingCardWidget.aspectRatio;
      final double maxWidth = constraints.maxWidth;

      // Cards overlap by default (fanned stack); shrink the overlap further
      // if there isn't enough room to fit every card at that spacing.
      double offset = cardWidth * 0.45;
      if (cards.length > 1) {
        final double fitOffset = (maxWidth - cardWidth) / (cards.length - 1);
        if (fitOffset < offset) {
          offset = fitOffset < 0 ? 0 : fitOffset;
        }
      }

      final double stackWidth = cardWidth + offset * (cards.length - 1);
      final double startX = ((maxWidth - stackWidth) / 2)
          .clamp(0, double.infinity)
          .toDouble();

      return SizedBox(
        width: maxWidth,
        height: cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < cards.length; i++)
              Positioned(
                left: startX + offset * i,
                top: 0,
                child: PlayingCardWidget(
                  card: cards[i],
                  width: cardWidth,
                  height: cardHeight,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildPositionFromHand(Hand hand) {
    return GestureDetector(
      child: Container(
        width: SettingsGlobalValues.getCardWidth(context),
        height: SettingsGlobalValues.getCardHeight(context),
        decoration: BoxDecoration(
          color: getHandColor(hand),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: GameValues.isGameStarted &&
                    !GameValues.isGameEnded &&
                    GameValues.currentHandIndex >= 0 &&
                    GameValues.currentHandIndex <
                        GameValues.player.hands.length &&
                    GameValues.player.hands[GameValues.currentHandIndex] == hand
                ? SettingsGlobalValues.activeColor
                : SettingsGlobalValues.darkColor,
            width: SettingsGlobalValues.cardBorderWidth,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Expanded(child: _buildCardStack(hand, context)),
              if (SettingsGlobalValues.showBestOption.settingValue &&
                  GameValues.isGameStarted &&
                  !GameValues.isGameEnded &&
                  hand.cards.length >= 2 &&
                  GameValues.player.hands.indexOf(hand) >=
                      GameValues.currentHandIndex)
                Text(
                  BestMoves.getBestOptionForHand(hand),
                  style: TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontSize: SettingsGlobalValues.getFontSize(context)),
                ),
              if (GameValues.isGameStarted &&
                  !GameValues.isGameEnded &&
                  GameValues.dealerHand == hand)
                Text(
                  "Dealer",
                  style: TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontSize: SettingsGlobalValues.getFontSize(context)),
                ),
              Text(
                hand.getValue() == 0 ? '' : hand.getValue().toString(),
                style: TextStyle(
                    color: SettingsGlobalValues.neutralColor,
                    fontSize: SettingsGlobalValues.getFontSize(context)),
              ),
              if (hand.bet > 0)
                Text(
                  'Bet: ${hand.bet}',
                  style: TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontSize: SettingsGlobalValues.getFontSize(context)),
                ),
              if (hand.insuranceBet > 0)
                Text(
                  'Insurance: ${_formatTokens(hand.insuranceBet / 2)}',
                  style: TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontSize: SettingsGlobalValues.getFontSize(context)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsGlobalValues.mainColor,
      appBar: AppBar(
        backgroundColor: SettingsGlobalValues.mainColor,
        iconTheme:
            const IconThemeData(color: SettingsGlobalValues.neutralColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/homePage'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () => BestMoves.showMatrix(context),
          ),
        ],
        title: const Text('Turbo Blackjack'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: [
                Text(
                  'Tokens: ${_formatTokens(GameValues.tokens / 2)}',
                  style: TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontWeight: FontWeight.bold,
                      fontSize: SettingsGlobalValues.getFontSize(context)),
                ),
                Text(
                  'Bankruptcies: ${GameValues.bankruptcyCount}',
                  style: TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontWeight: FontWeight.bold,
                      fontSize: SettingsGlobalValues.getFontSize(context)),
                ),
                if (!GameValues.isGameStarted)
                  Text(
                    'Total bet: ${GameLogic.getTotalBet()}',
                    style: TextStyle(
                        color: SettingsGlobalValues.neutralColor,
                        fontWeight: FontWeight.bold,
                        fontSize: SettingsGlobalValues.getFontSize(context)),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: SettingsGlobalValues.isLandscape(context)
          ? Row(
        children: getTable(),
      )
          : Column(
        children: getTable(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.center,
          spacing: SettingsGlobalValues.globalEdgeInset,
          runSpacing: SettingsGlobalValues.globalEdgeInset,
          children: getButtons(),
        ),
      ),
    );
  }

  getTable() {
    return [
      // Dealer position
      Padding(
        padding: const EdgeInsets.all(40.0),
        child: GameValues.isGameStarted
            ? _buildPositionFromHand(GameValues.dealerHand)
            : _buildPosition("D", Hand()),
      ),
      // Player's Hands
      Expanded(
          child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          direction: SettingsGlobalValues.isLandscape(context)
              ? Axis.vertical
              : Axis.horizontal,
          spacing: SettingsGlobalValues.globalEdgeInset,
          runSpacing: SettingsGlobalValues.globalEdgeInset,
          children: getCards(context),
        ),
      )),
    ];
  }

  getButtons() {
    if (!GameValues.isGameEnded && !GameValues.isGameStarted) {
      bool hasHands = GameValues.player.hands.isNotEmpty;
      bool canStart = hasHands && GameLogic.canStartGame();
      return [
        ElevatedButton(
          onPressed: canStart
              ? () {
                  setState(() {
                    GameLogic.startNewGame();
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canStart
                ? SettingsGlobalValues.positiveColor
                : SettingsGlobalValues.secondColor,
          ),
          child: Text(
            'Start Game',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
      ];
    }
    if (GameValues.isGameStarted && GameValues.waitingForInsuranceDecision) {
      final List<Widget> buttons = [];
      final bool multipleHands = GameValues.player.hands.length > 1;
      for (final hand in GameValues.player.hands) {
        final int handIndex = GameValues.player.hands.indexOf(hand);
        final bool canInsurance = GameLogic.canTakeInsurance(hand);
        final String label = hand.insuranceBet > 0
            ? (multipleHands ? 'Insured (Hand ${handIndex + 1})' : 'Insured')
            : (multipleHands
                ? 'Insure Hand ${handIndex + 1}'
                : 'Take Insurance');
        buttons.add(ElevatedButton(
          onPressed: canInsurance
              ? () {
                  setState(() {
                    GameLogic.takeInsurance(hand);
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: hand.insuranceBet > 0
                ? SettingsGlobalValues.activeColor
                : (canInsurance
                    ? SettingsGlobalValues.positiveColor
                    : SettingsGlobalValues.secondColor),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ));
      }
      buttons.add(ElevatedButton(
        onPressed: () {
          setState(() {
            GameLogic.resolveInsurancePhase();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: SettingsGlobalValues.positiveColor,
        ),
        child: Text(
          'Continue',
          style: TextStyle(
              color: SettingsGlobalValues.neutralColor,
              fontSize: SettingsGlobalValues.getFontSize(context)),
        ),
      ));
      return buttons;
    }
    if (GameValues.isGameStarted &&
        !GameValues.isGameEnded &&
        !GameValues.waitingForInsuranceDecision) {
      final List<Widget> buttons = [];
      final bool hasCurrentHand = GameValues.currentHandIndex >= 0 &&
          GameValues.currentHandIndex < GameValues.player.hands.length;
      final bool canDouble = hasCurrentHand && GameLogic.canDoubleCurrentHand();
      final bool canSplit = hasCurrentHand && GameLogic.canSplit();

      buttons.addAll([
        // Hit=
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (SettingsGlobalValues.showBestOptionAsPopup.settingValue) {
                BestMoves.displayToast(
                    BestMoves.getBestOptionTextWidget("HIT"));
              }
              GameLogic.hit(
                  GameValues.player.hands[GameValues.currentHandIndex]);
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: SettingsGlobalValues.positiveColor,
          ),
          child: Text(
            'Hit',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
        // Stand
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (SettingsGlobalValues.showBestOptionAsPopup.settingValue) {
                BestMoves.displayToast(
                    BestMoves.getBestOptionTextWidget("STAND"));
              }
              GameLogic.stand(
                  GameValues.player.hands[GameValues.currentHandIndex]);
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: SettingsGlobalValues.positiveColor,
          ),
          child: Text(
            'Stand',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
        // Double
        ElevatedButton(
          onPressed: canDouble
              ? () {
                  setState(() {
                    if (SettingsGlobalValues
                        .showBestOptionAsPopup.settingValue) {
                      BestMoves.displayToast(
                          BestMoves.getBestOptionTextWidget("DOUBLE"));
                    }
                    GameLogic.doubleOnHand(
                        GameValues.player.hands[GameValues.currentHandIndex]);
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canDouble
                ? SettingsGlobalValues.positiveColor
                : SettingsGlobalValues.secondColor,
          ),
          child: Text(
            'Double',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
        // Split
        ElevatedButton(
          onPressed: canSplit
              ? () {
                  setState(() {
                    if (SettingsGlobalValues
                        .showBestOptionAsPopup.settingValue) {
                      BestMoves.displayToast(
                          BestMoves.getBestOptionTextWidget("SPLIT"));
                    }
                    GameLogic.split(
                        GameValues.player.hands[GameValues.currentHandIndex]);
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSplit
                ? SettingsGlobalValues.positiveColor
                : SettingsGlobalValues.secondColor,
          ),
          child: Text(
            'Split',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
      ]);
      buttons.add(
        // Surrender
        ElevatedButton(
          onPressed: () {
            if (GameLogic.isFirstTurnForHand()) {
              setState(() {
                if (SettingsGlobalValues.showBestOptionAsPopup.settingValue) {
                  BestMoves.displayToast(
                      BestMoves.getBestOptionTextWidget("SURRENDER"));
                }
                GameLogic.surrender(
                    GameValues.player.hands[GameValues.currentHandIndex]);
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: GameLogic.isFirstTurnForHand()
                ? SettingsGlobalValues.positiveColor
                : SettingsGlobalValues.secondColor,
          ),
          child: Text(
            'Surrender',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
      );

      return buttons;
    }
    if (GameValues.isGameEnded && GameValues.isGameStarted) {
      final bool canRestart = GameLogic.canStartGame();
      return [
        ElevatedButton(
          onPressed: canRestart
              ? () async {
                  await GameLogic.restartGame();
                  setState(() {});
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canRestart
                ? SettingsGlobalValues.positiveColor
                : SettingsGlobalValues.secondColor,
          ),
          child: Text(
            'Restart Game',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await GameLogic.endGame();
            setState(() {});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: SettingsGlobalValues.positiveColor,
          ),
          child: Text(
            'End Game',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
      ];
    }
  }

  getHandColor(Hand hand) {
    if (!GameValues.isGameStarted && !GameValues.isGameEnded) {
      if (hand.isPlayed) {
        return SettingsGlobalValues.positiveColor;
      } else {
        return SettingsGlobalValues.secondColor;
      }
    } else if (GameValues.isGameStarted && !GameValues.isGameEnded) {
      int handIndex = GameValues.player.hands.indexOf(hand);
      if (handIndex == GameValues.currentHandIndex) {
        return SettingsGlobalValues.positiveColor;
      } else if (handIndex > GameValues.currentHandIndex) {
        return SettingsGlobalValues.secondColor;
      } else {
        if (hand.getValue() > 21) {
          return SettingsGlobalValues.negativeColor;
        } else {
          return SettingsGlobalValues.positiveColor;
        }
      }
    } else if (GameValues.isGameStarted && GameValues.isGameEnded) {
      switch (GameLogic.getVictoryStatus(GameValues.dealerHand, hand)) {
        case VictoryStatus.blackJack:
          return SettingsGlobalValues.goldColor;
        case VictoryStatus.win:
          return SettingsGlobalValues.positiveColor;
        case VictoryStatus.draw:
          return SettingsGlobalValues.activeColor;
        case VictoryStatus.surrender:
          return SettingsGlobalValues.orangeColor;
        case VictoryStatus.lost:
        case VictoryStatus.bust:
          return SettingsGlobalValues.negativeColor;
        case VictoryStatus.empty:
          return SettingsGlobalValues.darkColor;
      }
    }
  }

  List<Widget> getCards(BuildContext context) {
    final isStarted = GameValues.isGameStarted;
    final hands = isStarted ? GameValues.player.hands : GameValues.handsToPlay;
    final length = hands.length;

    return List.generate(length, (i) {
      final index =
          SettingsGlobalValues.isLandscape(context) ? i : length - 1 - i;
      final hand = hands[index];

      return isStarted
          ? _buildPositionFromHand(hand)
          : _buildPosition('$i', hand);
    });
  }
}
