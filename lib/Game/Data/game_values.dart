import 'card.dart';

class GameValues {
  static List<Hand> handsToPlay = [];
  static Player player = Player();
  static Player dealer = Player(Hand());
  static Hand dealerHand = dealer.hands[0];

  // Tokens are tracked internally in half-token units (e.g. 200 == 100
  // tokens) so bets, insurance and payouts stay integers and comparisons
  // never need floating-point epsilons. Divide by 2 for display.
  static const int initialTokens = 200;
  static const int bankruptcyRefillTokens = 20;

  static int tokens = initialTokens;
  static int bankruptcyCount = 0;

  static List<Card> deck = [];
  static List<Card> discardPile = [];

  // Continuous Shuffling Machine state (used when the "Use Shuffler"
  // setting is on). See DeckLogic for the algorithm and README.md for the
  // documented model this is based on.
  static List<List<Card>> shufflerCompartments = [];

  static bool isGameStarted = false;
  static bool isGameEnded = false;
  static bool waitingForInsuranceDecision = false;
  // Gates the reveal of hidden double-down cards behind an explicit player
  // action once the round ends, instead of auto-revealing immediately.
  static bool doubleCardsRevealed = false;

  static int currentHandIndex = -1;
  static int nbSplitInGame = 0;

  static Map<String, String> matrix = {};

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
  bool isDoubled = false;
  int bet = 0;
  // Half-token units, see GameValues.tokens.
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

  void resetForNextRound({bool keepBet = true}) {
    cards.clear();
    isSplitted = false;
    isSurrender = false;
    isDoubled = false;
    insuranceBet = 0;
    if (!keepBet) {
      bet = 0;
    }
  }
}
