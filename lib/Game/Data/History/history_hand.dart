import '../game_values.dart';

class HistoryHand extends Hand {
  late VictoryStatus victoryStatus;
  late bool isDealer;
}

enum VictoryStatus {
  surrender,
  lost,
  win,
  draw,
  blackJack,
  bust,
}
