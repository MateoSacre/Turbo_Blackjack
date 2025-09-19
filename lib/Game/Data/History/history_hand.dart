import '../../Logic/game_logic.dart';
import '../card.dart';
import '../game_values.dart';

class HistoryHand extends Hand {
  VictoryStatus victoryStatus = VictoryStatus.lost;
  bool isDealer = false;
  int payout = 0;
  int insurancePayout = 0;

  Map<String, dynamic> toJson() {
    return {
      'cards': cards.map((c) => c.toJson()).toList(),
      'isPlayed': isPlayed,
      'isSplitted': isSplitted,
      'isSurrender': isSurrender,
      'victoryStatus': victoryStatus.name,
      'isDealer': isDealer,
      'bet': bet,
      'insuranceBet': insuranceBet,
      'payout': payout,
      'insurancePayout': insurancePayout,
    };
  }

  static HistoryHand fromJson(Map<String, dynamic> json) {
    HistoryHand hand = HistoryHand();
    hand.cards = (json['cards'] as List).map((e) => Card.fromJson(e)).toList();
    hand.isPlayed = json['isPlayed'] ?? false;
    hand.isSplitted = json['isSplitted'] ?? false;
    hand.isSurrender = json['isSurrender'] ?? false;
    hand.victoryStatus =
        VictoryStatus.values.byName(json['victoryStatus'] as String);
    hand.isDealer = json['isDealer'] ?? false;
    hand.bet = json['bet'] ?? 0;
    hand.insuranceBet = json['insuranceBet'] ?? 0;
    hand.payout = json['payout'] ?? 0;
    hand.insurancePayout = json['insurancePayout'] ?? 0;
    return hand;
  }
}
