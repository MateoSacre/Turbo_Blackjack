import 'dart:async';

import 'package:flutter/material.dart';
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
                      GameValues.player.hands.add(hand);
                      SettingsGlobalValues.logger.d(
                          "Added hand $text to Player[${GameValues.player.hands}]");
                    } else {
                      GameValues.player.hands.remove(hand);
                      SettingsGlobalValues.logger.d(
                          "Removed hand $text to Player[${GameValues.player.hands}]");
                    }
                  });
                }
              : null,
      child: Container(
        width: SettingsGlobalValues.playerCardWidth,
        height: SettingsGlobalValues.playerCardHeight,
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
        width: SettingsGlobalValues.playerCardWidth,
        height: SettingsGlobalValues.playerCardHeight,
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
                style:
                    const TextStyle(color: SettingsGlobalValues.neutralColor),
              )),
              Text(hand.getValue() == 0 ? '' : hand.getValue().toString(),
                  style: const TextStyle(
                      color: SettingsGlobalValues.neutralColor)),
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
        padding: const EdgeInsets.all(20.0),
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
      return [
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (hasHands) GameLogic.startNewGame();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: hasHands
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
      return [
        // Hit=
        ElevatedButton(
          onPressed: () {
            setState(() {
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
          onPressed: () {
            if (GameLogic.isFirstTurnForHand()) {
              setState(() {
                GameLogic.double(
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
            'Double',
            style: TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
        ),
        // Split
        ElevatedButton(
          onPressed: () {
            if (GameLogic.isFirstTurnForHand() && GameLogic.canSplit()) {
              setState(() {
                GameLogic.split(
                    GameValues.player.hands[GameValues.currentHandIndex]);
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                GameLogic.isFirstTurnForHand() && GameLogic.canSplit()
                    ? SettingsGlobalValues.positiveColor
                    : SettingsGlobalValues.secondColor,
          ),
          child: const Text(
            'Split',
            style: TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
        ),
        // Surrender
        ElevatedButton(
          onPressed: () {
            if (GameLogic.isFirstTurnForHand()) {
              setState(() {
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
      ];
    }
    if (GameValues.isGameEnded && GameValues.isGameStarted) {
      return [
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
