import 'package:turbo_blackjack/Game/Data/History/history_hand.dart';

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
    }
    if (dealerValue == 21 && dealerHand.cards.length == 2) {
      dealerHand.victoryStatus = VictoryStatus.blackJack;
    }
    for (HistoryHand hand in playerHands) {
      if (hand.getValue() > 21) {
        hand.victoryStatus = VictoryStatus.bust;
      }
      if (hand.isSurrender) {
        hand.victoryStatus = VictoryStatus.surrender;
      }
      if (dealerHand.victoryStatus == VictoryStatus.bust &&
          hand.getValue() <= 21) {
        hand.victoryStatus = VictoryStatus.win;
      }
      if (dealerHand.victoryStatus == VictoryStatus.blackJack &&
          hand.getValue() == 21 &&
          hand.cards.length == 2) {
        hand.victoryStatus = VictoryStatus.draw;
      }
      if (dealerHand.victoryStatus == VictoryStatus.blackJack &&
          hand.getValue() <= 21) {
        hand.victoryStatus = VictoryStatus.lost;
      }
      if (dealerValue == hand.getValue()) {
        hand.victoryStatus = VictoryStatus.draw;
      }
      if (dealerValue < hand.getValue()) {
        hand.victoryStatus = VictoryStatus.win;
      }
      if (dealerValue > hand.getValue()) {
        hand.victoryStatus = VictoryStatus.lost;
      }
    }
  }
}
