import 'Card.dart';

class GameValues {
  static List<Hand> handsToPlay = [];
  static Player player = Player();
  static Player dealer = Player(Hand());
  static Hand dealerHand = dealer.hands[0];

  static List<Card> deck = [];
  static List<Card> discardPile = [];

  static bool isGameStarted = false;
  static bool isGameEnded = false;

  static int currentHandIndex = -1;
}

class Player {
  List<Hand> hands = [];

  Player([Hand? hand]) {
    if (hand != null) {
      hands.add(hand);
    }
  }
}

class Hand {
  List<Card> cards = [];
  bool isPlayed = false;
  bool isSplitted = false;
  bool isSurrender = false;

  int getValue() {
    int result = 0;
    bool hasAce = false;
    bool wasAceUsed = false;

    for (Card card in cards) {
      if (card.value == 1) {
        hasAce = true;
        result += 11;
      } else {
        result += (card.value >= 10 ? 10 : card.value);
      }
    }

    while (result > 21 && hasAce && !wasAceUsed) {
      result -= 10;
      wasAceUsed = true;
    }

    return result;
  }

  getCardsValues() {
    return cards.map((card) => card.toString()).toList();
  }
}
