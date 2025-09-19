import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:turbo_blackjack/Game/Logic/best_moves.dart';
import 'package:turbo_blackjack/Game/Logic/deck_logic.dart';
import 'package:turbo_blackjack/Settings/settings_global_values.dart';

import '../Data/game_values.dart';
import '../Logic/game_logic.dart';

class PlayTable extends StatefulWidget {
  const PlayTable({super.key});

  @override
  PlayTableState createState() => PlayTableState();
}

class PlayTableState extends State<PlayTable> {
  late Timer _timer;

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
    super.dispose();
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
                  style:
                      const TextStyle(color: SettingsGlobalValues.neutralColor)),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    children: [
                      Text('Bet: ${hand.bet}',
                          style: const TextStyle(
                              color: SettingsGlobalValues.neutralColor)),
                      if (!GameValues.isGameStarted)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove,
                                  color: SettingsGlobalValues.neutralColor),
                              onPressed: GameLogic.canDecreaseBet(hand)
                                  ? () {
                                      setState(() {
                                        if (hand.bet > 0) {
                                          hand.bet--;
                                        }
                                      });
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add,
                                  color: SettingsGlobalValues.neutralColor),
                              onPressed: GameLogic.canIncreaseBet(hand)
                                  ? () {
                                      setState(() {
                                        hand.bet++;
                                      });
                                    }
                                  : null,
                            ),
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
              Expanded(
                  child: Text(
                hand.getCardsValues().join(' '),
                style: TextStyle(
                    color: SettingsGlobalValues.neutralColor,
                    fontSize: SettingsGlobalValues.getFontSize(context)),
              )),
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
                  'Insurance: ${_formatTokens(hand.insuranceBet)}',
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
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: [
                Text(
                  'Tokens: ${_formatTokens(GameValues.tokens)}',
                  style: const TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Bankruptcies: ${GameValues.bankruptcyCount}',
                  style: const TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontWeight: FontWeight.bold),
                ),
                if (!GameValues.isGameStarted)
                  Text(
                    'Total bet: ${GameLogic.getTotalBet()}',
                    style: const TextStyle(
                        color: SettingsGlobalValues.neutralColor,
                        fontWeight: FontWeight.bold),
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
      // Contextual Buttons
      Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Wrap(
              direction: SettingsGlobalValues.isLandscape(context)
                  ? Axis.vertical
                  : Axis.horizontal,
              alignment: WrapAlignment.center,
              spacing: SettingsGlobalValues.globalEdgeInset,
              runSpacing: SettingsGlobalValues.globalEdgeInset,
              children: getButtons(),
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
          child: const Text(
            'Start Game',
            style: TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
        ),
      ];
    }
    if (GameValues.isGameStarted && !GameValues.isGameEnded) {
      final List<Widget> buttons = [];
      final bool hasCurrentHand = GameValues.currentHandIndex >= 0 &&
          GameValues.currentHandIndex < GameValues.player.hands.length;
      final Hand? currentHand =
          hasCurrentHand ? GameValues.player.hands[GameValues.currentHandIndex] : null;
      final bool canDouble =
          hasCurrentHand && GameLogic.canDoubleCurrentHand();
      final bool canSplit = hasCurrentHand && GameLogic.canSplit();
      final bool canInsurance =
          hasCurrentHand && currentHand != null && GameLogic.canTakeInsurance(currentHand);

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
          child: const Text(
            'Hit',
            style: TextStyle(color: SettingsGlobalValues.neutralColor),
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
          child: const Text(
            'Stand',
            style: TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
        ),
        // Double
        ElevatedButton(
          onPressed: canDouble
              ? () {
                  setState(() {
                    if (SettingsGlobalValues.showBestOptionAsPopup.settingValue) {
                      BestMoves.displayToast(
                          BestMoves.getBestOptionTextWidget("DOUBLE"));
                    }
                    GameLogic.double(
                        GameValues.player.hands[GameValues.currentHandIndex]);
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canDouble
                ? SettingsGlobalValues.positiveColor
                : SettingsGlobalValues.secondColor,
          ),
          child: const Text(
            'Double',
            style: TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
        ),
        // Split
        ElevatedButton(
          onPressed: canSplit
              ? () {
                  setState(() {
                    if (SettingsGlobalValues.showBestOptionAsPopup.settingValue) {
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
          child: const Text(
            'Split',
            style: TextStyle(color: SettingsGlobalValues.neutralColor),
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
          child: const Text(
            'Surrender',
            style: TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
        ),
      );

      buttons.add(ElevatedButton(
        onPressed: canInsurance && currentHand != null
            ? () {
                setState(() {
                  GameLogic.takeInsurance(currentHand);
                });
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canInsurance
              ? SettingsGlobalValues.positiveColor
              : SettingsGlobalValues.secondColor,
        ),
        child: const Text(
          'Insurance',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
      ));

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
          child: const Text(
            'Restart Game',
            style: TextStyle(color: SettingsGlobalValues.neutralColor),
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
          child: const Text(
            'End Game',
            style: TextStyle(color: SettingsGlobalValues.neutralColor),
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
