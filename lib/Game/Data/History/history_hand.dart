import '../../Logic/game_logic.dart';
import '../Card.dart';
import '../game_values.dart';

class HistoryHand extends Hand {
  VictoryStatus victoryStatus = VictoryStatus.lost;
  bool isDealer = false;

  Map<String, dynamic> toJson() {
    return {
      'cards': cards.map((c) => c.toJson()).toList(),
      'isPlayed': isPlayed,
      'isSplitted': isSplitted,
      'isSurrender': isSurrender,
      'bet': bet,
      'insuranceBet': insuranceBet,
      'victoryStatus': victoryStatus.name,
      'isDealer': isDealer,
    };
  }

  static HistoryHand fromJson(Map<String, dynamic> json) {
    HistoryHand hand = HistoryHand();
    hand.cards = (json['cards'] as List).map((e) => Card.fromJson(e)).toList();
    hand.isPlayed = json['isPlayed'] ?? false;
    hand.isSplitted = json['isSplitted'] ?? false;
    hand.isSurrender = json['isSurrender'] ?? false;
    hand.bet = json['bet'] ?? 0;
    hand.insuranceBet =
        json['insuranceBet'] == null ? 0 : (json['insuranceBet'] as num).toDouble();
    hand.victoryStatus =
        VictoryStatus.values.byName(json['victoryStatus'] as String);
    hand.isDealer = json['isDealer'] ?? false;
    return hand;
  }
}
