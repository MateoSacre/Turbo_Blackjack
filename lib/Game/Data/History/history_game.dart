import 'package:turbo_blackjack/Game/Data/History/history_hand.dart';

import '../../Logic/game_logic.dart';

class HistoryGame {
  late HistoryHand dealerHand;
  late List<HistoryHand> playerHands;

  HistoryGame() {
    dealerHand = HistoryHand();
    playerHands = [];
  }

  void updateStats() {
    int dealerValue = dealerHand.getValue();
    if (dealerValue > 21) {
      dealerHand.victoryStatus = VictoryStatus.bust;
    } else if (dealerValue == 21 && dealerHand.cards.length == 2) {
      dealerHand.victoryStatus = VictoryStatus.blackJack;
    } else {
      dealerHand.victoryStatus = VictoryStatus.empty;
    }
    for (HistoryHand hand in playerHands) {
      hand.victoryStatus = GameLogic.getVictoryStatus(dealerHand, hand);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'dealerHand': dealerHand.toJson(),
      'playerHands': playerHands.map((e) => e.toJson()).toList(),
    };
  }

  static HistoryGame fromJson(Map<String, dynamic> json) {
    HistoryGame game = HistoryGame();
    game.dealerHand = HistoryHand.fromJson(json['dealerHand']);
    game.playerHands = (json['playerHands'] as List)
        .map((e) => HistoryHand.fromJson(e))
        .toList();
    return game;
  }
}
