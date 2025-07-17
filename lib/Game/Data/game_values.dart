import 'Card.dart';

class GameValues {
  static Player player = Player();
  static Player dealer = Player();

  static bool isGameStarted = false;
  static bool isGameEnded = false;
}

class Player {
  List<Hand> hands = [];
}

class Hand {
  List<Card> cards = [];
  bool isPlayed = false;

  getValue() {
    int result = 0;
    for (Card card in cards) {
      if (result + card.value > 21 && card.value == 11) {
        result -= 10;
      }
      result += card.value;
    }
    return;
  }
}
