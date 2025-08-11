import 'dart:async';
import 'dart:math';

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
          child: Text(text),
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
          color: hand.isPlayed
              ? SettingsGlobalValues.positiveColor
              : SettingsGlobalValues.secondColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: GameValues.isGameStarted &&
                    !GameValues.isGameEnded &&
                    GameValues.currentHandIndex >= 0 &&
                    GameValues.player.hands[GameValues.currentHandIndex] == hand
                ? SettingsGlobalValues.activeColor
                : SettingsGlobalValues.darkColor,
            width: SettingsGlobalValues.cardBorderWidth,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Expanded(child: Text(hand.getCardsValues().join(' '))),
              Text(hand.getValue() == 0 ? '' : hand.getValue().toString()),
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
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final center = Offset(
                    constraints.maxWidth / 2, constraints.maxHeight * .35);
                final radius =
                    min(constraints.maxWidth, constraints.maxHeight) * 0.40;
                List<Widget> stackChildren = [];
                int length = (GameValues.isGameStarted
                    ? GameValues.player.hands.length
                    : GameValues.handsToPlay.length);
                double offset = 0;
                double startAngle = pi + offset;
                double endAngle = startAngle + (pi - 2 * offset);
                double step = (endAngle - startAngle) / (length + 1);
                for (int i = 0; i < length; i++) {
                  final angle = startAngle + step * (i + 1);
                  final offsetForCard = Offset.fromDirection(angle, radius);
                  stackChildren.add(Positioned(
                    left: center.dx -
                        offsetForCard.dx -
                        SettingsGlobalValues.playerCardWidth / 2,
                    top: center.dy -
                        offsetForCard.dy -
                        SettingsGlobalValues.playerCardHeight / 2,
                    child: GameValues.isGameStarted
                        ? _buildPositionFromHand(GameValues.player.hands[i])
                        : _buildPosition("$i", GameValues.handsToPlay[i]),
                  ));
                }

                // Dealer position
                stackChildren.add(Positioned(
                  left: center.dx - SettingsGlobalValues.playerCardWidth / 2,
                  top: center.dy * .5 -
                      SettingsGlobalValues.playerCardHeight / 2,
                  child: GameValues.isGameStarted
                      ? _buildPositionFromHand(GameValues.dealerHand)
                      : _buildPosition("D", Hand()),
                ));

                return Stack(children: stackChildren);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: getButtons(),
          ),
        ],
      ),
    );
  }

  getButtons() {
    if (!GameValues.isGameEnded && !GameValues.isGameStarted) {
      bool hasHands = GameValues.player.hands.isNotEmpty;
      return ElevatedButton(
        onPressed: () {
          setState(() {
            if (hasHands) GameLogic.startNewGame();
          });
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: hasHands
              ? SettingsGlobalValues.positiveColor
              : SettingsGlobalValues.secondColor,
        ),
        child: const Text(
          'Start Game',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
      );
    }
    if (GameValues.isGameStarted &&
        !GameValues.isGameEnded &&
        !GameValues.isDrawing) {
      return Wrap(
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                GameLogic.hit(
                    GameValues.player.hands[GameValues.currentHandIndex]);
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: SettingsGlobalValues.positiveColor,
            ),
            child: const Text(
              'Hit',
              style: TextStyle(color: SettingsGlobalValues.neutralColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                GameLogic.stand(
                    GameValues.player.hands[GameValues.currentHandIndex]);
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: SettingsGlobalValues.positiveColor,
            ),
            child: const Text(
              'Stand',
              style: TextStyle(color: SettingsGlobalValues.neutralColor),
            ),
          ),
          if (GameLogic.isFirstTurnForHand())
            ElevatedButton(
              onPressed: () {
                setState(() {
                  GameLogic.double(
                      GameValues.player.hands[GameValues.currentHandIndex]);
                });
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: SettingsGlobalValues.positiveColor,
              ),
              child: const Text(
                'Double',
                style: TextStyle(color: SettingsGlobalValues.neutralColor),
              ),
            ),
          if (GameLogic.isFirstTurnForHand() && GameLogic.canSplit())
            ElevatedButton(
              onPressed: () {
                setState(() {
                  GameLogic.split(
                      GameValues.player.hands[GameValues.currentHandIndex]);
                });
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: SettingsGlobalValues.positiveColor,
              ),
              child: const Text(
                'Split',
                style: TextStyle(color: SettingsGlobalValues.neutralColor),
              ),
            ),
          if (GameLogic.isFirstTurnForHand())
            ElevatedButton(
              onPressed: () {
                setState(() {
                  GameLogic.surrender(
                      GameValues.player.hands[GameValues.currentHandIndex]);
                });
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: SettingsGlobalValues.positiveColor,
              ),
              child: const Text(
                'Surrender',
                style: TextStyle(color: SettingsGlobalValues.neutralColor),
              ),
            ),
        ],
      );
    }
    if (GameValues.isGameEnded && GameValues.isGameStarted) {
      return Wrap(
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                GameLogic.restartGame();
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: SettingsGlobalValues.positiveColor,
            ),
            child: const Text(
              'Restart Game',
              style: TextStyle(color: SettingsGlobalValues.neutralColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                GameLogic.endGame();
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: SettingsGlobalValues.positiveColor,
            ),
            child: const Text(
              'End Game',
              style: TextStyle(color: SettingsGlobalValues.neutralColor),
            ),
          ),
        ],
      );
    }
  }
}
