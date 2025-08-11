import 'package:turbo_blackjack/Game/Data/History/history_hand.dart';
import 'package:turbo_blackjack/Settings/settings_global_values.dart';

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
      if (hand.getValue() > 21) {
        hand.victoryStatus = VictoryStatus.bust;
      } else if (hand.isSurrender) {
        hand.victoryStatus = VictoryStatus.surrender;
      } else if (dealerHand.victoryStatus == VictoryStatus.bust) {
        if (hand.getValue() == 21 && hand.cards.length == 2) {
          hand.victoryStatus = VictoryStatus.blackJack;
        } else {
          hand.victoryStatus = VictoryStatus.win;
        }
      } else if (dealerHand.victoryStatus == VictoryStatus.blackJack &&
          hand.getValue() == 21 &&
          hand.cards.length == 2) {
        hand.victoryStatus = VictoryStatus.draw;
      } else if (dealerHand.victoryStatus == VictoryStatus.blackJack &&
          hand.getValue() <= 21) {
        hand.victoryStatus = VictoryStatus.lost;
      } else if (hand.getValue() == 21 && hand.cards.length == 2) {
        hand.victoryStatus = VictoryStatus.blackJack;
      } else if (dealerValue == hand.getValue()) {
        hand.victoryStatus = VictoryStatus.draw;
      } else if (dealerValue < hand.getValue()) {
        hand.victoryStatus = VictoryStatus.win;
      } else if (dealerValue > hand.getValue()) {
        hand.victoryStatus = VictoryStatus.lost;
      } else {
        SettingsGlobalValues.logger.f(
            "Impossible victory status for dealerValue: [$dealerValue] and handValue: [${hand.getValue()}]");
      }
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
