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
    hand.victoryStatus =
        VictoryStatus.values.byName(json['victoryStatus'] as String);
    hand.isDealer = json['isDealer'] ?? false;
    return hand;
  }
}

enum VictoryStatus {
  surrender,
  lost,
  win,
  draw,
  blackJack,
  bust,
  empty,
}
