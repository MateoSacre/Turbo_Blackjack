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
    return GestureDetector(
      onTap:
          (!GameValues.isGameStarted && !GameValues.isGameEnded && text != "D")
              ? () {
                  setState(() {
                    hand.isPlayed = !hand.isPlayed;
                    if (hand.isPlayed) {
                      if (!GameValues.player.hands.contains(hand)) {
                        GameValues.player.hands.add(hand);
                      }
                      SettingsGlobalValues.logger.d(
                          "Added hand $text to Player[${GameValues.player.hands}]");
                    } else {
                      GameValues.player.hands.remove(hand);
                      GameValues.playerTokens += hand.insuranceBet;
                      hand.bet = 0;
                      hand.insuranceBet = 0;
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
          color: hand.isPlayed
              ? SettingsGlobalValues.positiveColor
              : SettingsGlobalValues.secondColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(text,
              style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
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
              if (GameValues.isGameStarted &&
                  GameValues.dealerHand != hand)
                Text(
                  'Bet: ${hand.bet}',
                  style: TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontSize: SettingsGlobalValues.getFontSize(context)),
                ),
              if (GameValues.isGameStarted &&
                  GameValues.dealerHand != hand &&
                  hand.insuranceBet > 0)
                Text(
                  'Ins: ${hand.insuranceBet}',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokensSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SettingsGlobalValues.secondColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tokens: ${GameValues.playerTokens}',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
          Text(
            'Bankruptcies: ${GameValues.bankruptcyCount}',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
        ],
      ),
    );
  }

  List<Hand> _selectedHandsPreGame() {
    return GameValues.handsToPlay.where((hand) => hand.isPlayed).toList();
  }

  int _computeTotalBet() {
    return _selectedHandsPreGame().fold<int>(0, (sum, hand) => sum + hand.bet);
  }

  Widget _buildBetControl(Hand hand, int displayIndex) {
    final bool canDecrease = hand.bet > 0;
    final bool canIncrease = _computeTotalBet() < GameValues.playerTokens;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SettingsGlobalValues.secondColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hand $displayIndex bet',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: canDecrease
                    ? () {
                        setState(() {
                          hand.bet--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove),
                color: SettingsGlobalValues.neutralColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '${hand.bet}',
                  style:
                      const TextStyle(color: SettingsGlobalValues.neutralColor),
                ),
              ),
              IconButton(
                onPressed: canIncrease
                    ? () {
                        setState(() {
                          hand.bet++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.add),
                color: SettingsGlobalValues.neutralColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceControl(Hand hand, int displayIndex) {
    final int maxInsurance = hand.bet ~/ 2;
    final bool canDecrease = hand.insuranceBet > 0;
    final bool canIncrease =
        GameValues.playerTokens > 0 && hand.insuranceBet < maxInsurance;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SettingsGlobalValues.secondColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hand $displayIndex insurance (max $maxInsurance)',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: canDecrease
                    ? () {
                        setState(() {
                          hand.insuranceBet--;
                          GameValues.playerTokens++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove),
                color: SettingsGlobalValues.neutralColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '${hand.insuranceBet}',
                  style:
                      const TextStyle(color: SettingsGlobalValues.neutralColor),
                ),
              ),
              IconButton(
                onPressed: canIncrease
                    ? () {
                        setState(() {
                          hand.insuranceBet++;
                          GameValues.playerTokens--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.add),
                color: SettingsGlobalValues.neutralColor,
              ),
            ],
          ),
        ],
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

  List<Widget> getButtons() {
    final tokensSummary = _buildTokensSummary();

    if (!GameValues.isGameStarted && !GameValues.isGameEnded) {
      final selectedHands = _selectedHandsPreGame();
      final totalBet = _computeTotalBet();
      final bool hasHands = selectedHands.isNotEmpty;
      final bool allHandsHaveBet =
          selectedHands.every((hand) => hand.bet > 0);
      final bool canStart =
          hasHands && allHandsHaveBet && totalBet <= GameValues.playerTokens;

      final widgets = <Widget>[tokensSummary];

      if (hasHands) {
        for (int i = 0; i < selectedHands.length; i++) {
          widgets.add(_buildBetControl(selectedHands[i], i + 1));
        }
      }

      widgets.add(Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          'Total bet: $totalBet',
          style: TextStyle(
            color: totalBet > GameValues.playerTokens
                ? SettingsGlobalValues.negativeColor
                : SettingsGlobalValues.neutralColor,
          ),
        ),
      ));

      widgets.add(ElevatedButton(
        onPressed: canStart
            ? () async {
                await GameLogic.startNewGame();
                setState(() {});
              }
            : () {
                final messenger = ScaffoldMessenger.of(context);
                if (!hasHands) {
                  messenger.showSnackBar(const SnackBar(
                      content: Text('Select at least one hand to play.')));
                } else if (!allHandsHaveBet) {
                  messenger.showSnackBar(const SnackBar(
                      content: Text(
                          'Place a bet on every selected hand to begin.')));
                } else if (totalBet > GameValues.playerTokens) {
                  messenger.showSnackBar(const SnackBar(
                      content: Text('Not enough tokens for these bets.')));
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: canStart
              ? SettingsGlobalValues.positiveColor
              : SettingsGlobalValues.secondColor,
        ),
        child: const Text(
          'Start Game',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
      ));

      if (!hasHands) {
        widgets.add(const Text(
          'Tap a position to add a hand before starting.',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
        ));
      }

      return widgets;
    }

    if (GameValues.isGameStarted && GameValues.waitingForInsuranceDecision) {
      final widgets = <Widget>[tokensSummary];
      widgets.add(const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Dealer shows an Ace. Choose your insurance bets.',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
          textAlign: TextAlign.center,
        ),
      ));

      for (int i = 0; i < GameValues.player.hands.length; i++) {
        widgets.add(_buildInsuranceControl(GameValues.player.hands[i], i + 1));
      }

      widgets.add(ElevatedButton(
        onPressed: () async {
          await GameLogic.resolveInsurancePhase();
          setState(() {});
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: SettingsGlobalValues.positiveColor,
        ),
        child: const Text(
          'Confirm Insurance',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
      ));

      return widgets;
    }

    if (GameValues.isGameStarted && !GameValues.isGameEnded) {
      final widgets = <Widget>[tokensSummary];

      widgets.add(ElevatedButton(
        onPressed: () {
          setState(() {
            if (SettingsGlobalValues.showBestOptionAsPopup.settingValue) {
              BestMoves.displayToast(
                  BestMoves.getBestOptionTextWidget("HIT"));
            }
            GameLogic.hit(GameValues.player.hands[GameValues.currentHandIndex]);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: SettingsGlobalValues.positiveColor,
        ),
        child: const Text(
          'Hit',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
      ));

      widgets.add(ElevatedButton(
        onPressed: () {
          setState(() {
            if (SettingsGlobalValues.showBestOptionAsPopup.settingValue) {
              BestMoves.displayToast(
                  BestMoves.getBestOptionTextWidget("STAND"));
            }
            GameLogic.stand(GameValues.player.hands[GameValues.currentHandIndex]);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: SettingsGlobalValues.positiveColor,
        ),
        child: const Text(
          'Stand',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
      ));

      final bool canDouble = GameLogic.canDoubleCurrentHand();
      widgets.add(ElevatedButton(
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
      ));

      final bool canSplit = GameLogic.canSplit();
      widgets.add(ElevatedButton(
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
      ));

      final bool canSurrender = GameLogic.isFirstTurnForHand();
      widgets.add(ElevatedButton(
        onPressed: canSurrender
            ? () {
                setState(() {
                  if (SettingsGlobalValues.showBestOptionAsPopup.settingValue) {
                    BestMoves.displayToast(
                        BestMoves.getBestOptionTextWidget("SURRENDER"));
                  }
                  GameLogic.surrender(
                      GameValues.player.hands[GameValues.currentHandIndex]);
                });
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSurrender
              ? SettingsGlobalValues.positiveColor
              : SettingsGlobalValues.secondColor,
        ),
        child: const Text(
          'Surrender',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
      ));

      return widgets;
    }

    if (GameValues.isGameEnded && GameValues.isGameStarted) {
      return [
        tokensSummary,
        ElevatedButton(
          onPressed: () async {
            await GameLogic.restartGame();
            setState(() {});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: SettingsGlobalValues.positiveColor,
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

    return [tokensSummary];
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
