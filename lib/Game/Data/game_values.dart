import '../../Settings/settings_global_values.dart';
import 'card.dart';

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
  static int nbSplitInGame = 0;

  static Map<String, String> matrix = {};

  static int playerTokens = SettingsGlobalValues.startingTokens.settingValue;
  static int bankruptcyCount = 0;
  static bool waitingForInsuranceDecision = false;

  static int get totalBet => player.hands.fold(0, (sum, hand) => sum + hand.bet);
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
  int bet = 0;
  int insuranceBet = 0;

  int getValue() {
    int result = 0;
    bool hasAce = false;
    bool wasAceUsed = false;

    for (Card card in cards) {
      if (card.getTrueValue() == 1) {
        hasAce = true;
        result += 11;
      } else {
        result += card.getTrueValue();
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

  void resetRoundState() {
    cards.clear();
    isSplitted = false;
    isSurrender = false;
    insuranceBet = 0;
  }
}
