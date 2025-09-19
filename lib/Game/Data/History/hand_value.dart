import 'package:turbo_blackjack/Game/Data/card.dart';

import '../game_values.dart';

class HandValue {
  int value;
  bool isWithAce;
  bool isPair;

  HandValue(
      {required this.value, required this.isWithAce, required this.isPair});

  HandValue.fromHand(Hand hand)
      : value = 0,
        isWithAce = false,
        isPair = false {
    for (Card card in hand.cards) {
      value += card.getTrueValue();
    }
    if (hand.cards.any((c) => c.getTrueValue() == 1)) {
      if(value + 10 <= 21){
        value += 10;
      }
      isWithAce = true;
    }
    if (hand.cards.length == 2 && hand.cards[0].getTrueValue() == hand.cards[1].getTrueValue()) {
      isPair = true;
    }
  }

  @override
  String toString() {
    if (isPair) {
      int cardValue = value ~/ 2;
      return '$cardValue,$cardValue';
    } else if (isWithAce) {
      return 'A,${value - 11}';
    } else {
      return '$value';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! HandValue) return false;

    return value == other.value &&
        isWithAce == other.isWithAce &&
        isPair == other.isPair;
  }

  @override
  int get hashCode => value.hashCode ^ isWithAce.hashCode ^ isPair.hashCode;
}