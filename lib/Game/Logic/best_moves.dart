import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:turbo_blackjack/Settings/settings_global_values.dart';

import '../Data/History/hand_value.dart';
import '../Data/game_values.dart';

class BestMoves {
  final logger = Logger();

  static GlobalKey toastContainerKey = GlobalKey();
  static late FToast fToast;

  static void displayToast(Widget text) {
    displayToastWithColor(text, Colors.blueGrey);
  }

  static void displayToastWithColor(Widget textWidget, MaterialColor color) {
    fToast.showToast(
      child: Container(
        key: toastContainerKey,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color,
        ),
        child: textWidget,
      ),
      positionedToastBuilder:
          (BuildContext context, Widget child, ToastGravity? gravity) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final renderBox =
              toastContainerKey.currentContext!.findRenderObject() as RenderBox;
          final containerWidth = renderBox.size.width;

          fToast.removeCustomToast();
          fToast.showToast(
            child: child,
            positionedToastBuilder:
                (BuildContext context, Widget child, ToastGravity? gravity) {
              return Positioned(
                top: SettingsGlobalValues.toastPosition,
                left: (MediaQuery.of(context).size.width - containerWidth) / 2,
                child: child,
              );
            },
          );
        });

        return Positioned(
          top: SettingsGlobalValues.toastPosition,
          left: 0,
          child: child,
        );
      },
    );
  }

  static Widget getBestOptionTextWidget(String actionChoosed) {
    String actionChoosedShort = getActionShort(actionChoosed);
    String actionBest = getBestOptionForHand(
        GameValues.player.hands[GameValues.currentHandIndex]);
    MaterialColor color =
        (actionBest == actionChoosedShort) ? Colors.blue : Colors.red;
    RichText bestOptionText = RichText(
      text: TextSpan(
          text: "Best option was ",
          style: const TextStyle(color: Colors.black),
          children: <TextSpan>[
            TextSpan(
              text: getActionLong(actionBest),
              style: TextStyle(
                color: color,
              ),
            )
          ]),
    );
    return bestOptionText;
  }

  static void generateMatrix() {
    // Matrice avec une clé unique sous forme de chaîne pour chaque entrée
    Map<String, String> matrix = {};

    // Valeurs possibles pour la carte du dealer (2 à 11)
    List<int> dealerValues = List.generate(10, (index) => index + 2); // 2 à 11

    // Valeurs possibles pour les mains du joueur
    List<HandValue> playerHands = [];

    // Générer les mains "hard" (de 4 à 21)
    for (int i = 4; i <= 20; i++) {
      playerHands.add(HandValue(value: i, isWithAce: false, isPair: false));
    }

    // Générer les mains "soft" (valeur avec un As, de 13 à 21)
    for (int i = 13; i <= 21; i++) {
      playerHands.add(HandValue(value: i, isWithAce: true, isPair: false));
    }

    // Générer les paires (valeurs de 2 à 10, As considéré comme 11)
    for (int i = 2; i <= 10; i++) {
      playerHands.add(HandValue(value: i * 2, isWithAce: false, isPair: true));
    }

    // Remplir la matrice avec les meilleures actions
    for (int dealerCard in dealerValues) {
      for (HandValue playerHand in playerHands) {
        // Détermine la meilleure action en fonction du type de main
        String action;
        if (playerHand.isPair) {
          action = bestActionPair(playerHand.value, dealerCard);
        } else if (playerHand.isWithAce) {
          action = bestActionSoft(playerHand.value, dealerCard);
        } else {
          action = bestActionHard(playerHand.value, dealerCard);
        }

        // Crée une clé unique sous forme de chaîne pour cette combinaison
        String key =
            "$dealerCard-${playerHand.value}-${playerHand.isWithAce}-${playerHand.isPair}";
        matrix[key] = action;
      }
    }

    // Stocke la matrice dans l'instance GameDataValues
    GameValues.matrix = matrix;
  }

  static void showMatrix(BuildContext context) {
    List<int> dealerValues = List.generate(10, (index) => index + 2); // 2 à 11
    List<HandValue> playerHands = [];

    for (int i = 16; i >= 4; i--) {
      playerHands.add(HandValue(value: i, isWithAce: false, isPair: false));
    }
    for (int i = 21; i >= 13; i--) {
      playerHands.add(HandValue(value: i, isWithAce: true, isPair: false));
    }
    for (int i = 10; i >= 2; i--) {
      playerHands.add(HandValue(value: i * 2, isWithAce: false, isPair: true));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(30), // Très compact
              border: TableBorder.all(width: 0.5, color: Colors.black26),
              children: [
                // En-tête
                TableRow(
                  children: [
                    const _Cell(text: '\\', bold: true),
                    ...dealerValues.map((v) => _Cell(text: v.toString(), bold: true)),
                  ],
                ),
                // Données
                ...playerHands.map((playerHand) {
                  return TableRow(
                    children: [
                      _Cell(text: playerHand.toString()),
                      ...dealerValues.map((dealerCard) {
                        final key =
                            "$dealerCard-${playerHand.value}-${playerHand.isWithAce}-${playerHand.isPair}";
                        final action = GameValues.matrix[key] ?? 'N/A';
                        return _ColoredCell(text: action, color: getColorForAction(action));
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('CLOSE'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }





// Stratégie pour les mains "hard"
  static String bestActionHard(int playerHand, int dealerCard) {
    if (playerHand >= 17) {
      return 'S';
    }
    if (playerHand < 17 && playerHand >= 13) {
      if (dealerCard <= 6) {
        return 'S';
      }
      return 'H';
    }
    if (playerHand == 12) {
      if (dealerCard >= 4 && dealerCard <= 6) {
        return 'S';
      }
      return 'H';
    }
    if (playerHand == 11) {
      return 'D';
    }
    if (playerHand == 10) {
      if (dealerCard <= 9) {
        return 'D';
      }
      return 'H';
    }
    if (playerHand == 9) {
      if (dealerCard >= 3 && dealerCard <= 6) {
        return 'D';
      }
      return 'H';
    }
    if (playerHand <= 8) {
      return 'H';
    }
    return 'N/A';
  }

// Stratégie pour les mains "soft"
  static String bestActionSoft(int playerHand, int dealerCard) {
    if (playerHand >= 19) return 'S';
    if (playerHand == 18) {
      return dealerCard <= 6
          ? 'D'
          : dealerCard >= 9
              ? 'H'
              : 'S';
    }
    if (playerHand == 17) return dealerCard == 2 || dealerCard >= 7 ? 'H' : 'D';
    if (playerHand == 15 || playerHand == 16) {
      return dealerCard <= 3 || dealerCard >= 7 ? 'H' : 'D';
    }
    return dealerCard <= 4 || dealerCard >= 7 ? 'H' : 'D';
  }

// Stratégie pour les paires
  static String bestActionPair(int pairValue, int dealerCard) {
    pairValue = pairValue ~/ 2;
    if (pairValue == 11 || pairValue == 8) return 'Sp';
    if (pairValue == 10) return 'S';
    if (pairValue == 9) return dealerCard == 8 || dealerCard >= 10 ? 'S' : 'Sp';
    if (pairValue == 7) return dealerCard <= 7 ? 'Sp' : 'H';
    if (pairValue == 6) return dealerCard <= 6 ? 'Sp' : 'H';
    if (pairValue == 5) return dealerCard >= 10 ? 'H' : 'D';
    if (pairValue == 4) return dealerCard == 5 || dealerCard == 6 ? 'Sp' : 'H';
    return dealerCard <= 8 ? 'Sp' : 'H';
  }

  static getBestOptionForHand(Hand hand) {
    if ((GameValues.isGameStarted || GameValues.isGameEnded) &&
        hand.cards.length >= 2) {
      HandValue handValue = HandValue.fromHand(hand);
      int dealerCard = GameValues.dealerHand.cards[0].getTrueValue();
      String keyToFind =
          "$dealerCard-${handValue.value}-${handValue.isWithAce}-${handValue.isPair}";
      return GameValues.matrix[keyToFind] ?? 'N/A';
    }
    return 'N/A';
  }

  static getColorForAction(String action) {
    switch (action) {
      case 'H':
        return Colors.green;
      case 'S':
        return Colors.red;
      case 'D':
        return Colors.blue;
      case 'Sp':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  static String getActionShort(String actionChoosed) {
    switch (actionChoosed) {
      case 'HIT':
        return 'H';
      case 'STAND':
        return 'S';
      case 'SPLIT':
        return 'Sp';
      case 'DOUBLE':
        return 'D';
      case 'SURRENDER':
        return 'Su';
      default:
        return 'N/A';
    }
  }

  static getActionLong(String actionChoosed) {
    switch (actionChoosed) {
      case 'H':
        return 'HIT';
      case 'S':
        return 'STAND';
      case 'Sp':
        return 'SPLIT';
      case 'D':
        return 'DOUBLE';
      case 'Su':
        return 'SURRENDER';
      default:
        return 'N/A';
    }
  }

  isHandBlackjack(Hand hand) {
    return hand.cards.length == 2 &&
        (hand.cards[0].getTrueValue() == 11 &&
                hand.cards[1].getTrueValue() == 10 ||
            hand.cards[0].getTrueValue() == 10 &&
                hand.cards[1].getTrueValue() == 11);
  }

  isHandWinner(Hand hand, Hand dealerHand) {
    int dealerValue = dealerHand.getValue();
    int handValue = hand.getValue();
    if (isHandBlackjack(dealerHand)) {
      return -1;
    }
    if (isHandBlackjack(hand) && !isHandBlackjack(dealerHand)) {
      return 2;
    }
    if (handValue > 21) {
      return -1;
    }
    if (dealerValue == 21) {
      if (handValue == 21) {
        return 0;
      }
      return -1;
    }
    if (handValue == 21) {
      return 1;
    }
    if (dealerValue > 21) {
      if (handValue < 21) {
        return 1;
      }
      return -1;
    }
    if (handValue == dealerValue) {
      return 0;
    }
    if (handValue > dealerValue) {
      return 1;
    }
    return -1;
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;

  const _Cell({required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ColoredCell extends StatelessWidget {
  final String text;
  final Color color;

  const _ColoredCell({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }
}
