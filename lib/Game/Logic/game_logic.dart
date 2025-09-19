import 'package:turbo_blackjack/Game/Data/History/history_game.dart';
import 'package:turbo_blackjack/Game/Data/History/history_manager.dart';

import '../../Settings/settings_global_values.dart';
import '../Data/card.dart';
import '../Data/History/history_hand.dart';
import '../Data/game_values.dart';
import 'deck_logic.dart';

enum VictoryStatus {
  surrender,
  lost,
  win,
  draw,
  blackJack,
  bust,
  empty,
}

class GameLogic {
  static Future<void> startNewGame() async {
    if (GameValues.player.hands.isEmpty) {
      SettingsGlobalValues.logger
          .w('Attempted to start a game without any active hands.');
      return;
    }

    final totalBet = GameValues.totalBet;
    if (totalBet <= 0) {
      SettingsGlobalValues.logger
          .w('Cannot start a game without placing at least one bet.');
      return;
    }

    if (totalBet > GameValues.playerTokens) {
      SettingsGlobalValues.logger
          .w('Not enough tokens to cover the current bets.');
      return;
    }

    if (GameValues.player.hands.any((hand) => hand.bet <= 0)) {
      SettingsGlobalValues.logger
          .w('Each active hand must have a bet before starting the game.');
      return;
    }

    GameValues.isGameStarted = true;
    GameValues.isGameEnded = false;
    GameValues.waitingForInsuranceDecision = false;
    GameValues.nbSplitInGame = 0;
    GameValues.currentHandIndex = -1;

    GameValues.dealerHand.resetRoundState();
    for (Hand hand in GameValues.player.hands) {
      hand.resetRoundState();
    }

    GameValues.playerTokens -= totalBet;

    for (Hand hand in GameValues.player.hands) {
      hand.cards.add(await DeckLogic.drawCard());
    }
    GameValues.dealerHand.cards.add(await DeckLogic.drawCard());
    for (Hand hand in GameValues.player.hands) {
      hand.cards.add(await DeckLogic.drawCard());
    }

    if (GameValues.dealerHand.cards.isNotEmpty &&
        GameValues.dealerHand.cards.first.getTrueValue() == 1) {
      GameValues.waitingForInsuranceDecision = true;
      SettingsGlobalValues.logger.d(
          'Dealer shows an Ace. Waiting for insurance decisions.');
      return;
    }

    await nextHandOrEnd();
  }

  static Future<void> endGame() async {
    GameValues.isGameStarted = false;
    GameValues.isGameEnded = false;
    GameValues.waitingForInsuranceDecision = false;
    GameValues.currentHandIndex = -1;
    for (Card card in GameValues.dealerHand.cards) {
      GameValues.discardPile.add(card);
    }
    GameValues.dealerHand.resetRoundState();
    for (Hand hand in GameValues.player.hands) {
      for (Card card in hand.cards) {
        GameValues.discardPile.add(card);
      }
      hand.resetRoundState();
    }
    for (int i = 0; i < GameValues.nbSplitInGame; i++) {
      GameValues.player.hands.removeLast();
    }
    GameValues.nbSplitInGame = 0;
    SettingsGlobalValues.logger.d(
        "\nDeck of [${GameValues.deck.length}] cards at end of game: ${GameValues.deck.map((c) => c.toString()).join(', ')}");
    SettingsGlobalValues.logger.d(
        "\nDiscard pile of [${GameValues.discardPile.length}] cards at end of game: ${GameValues.discardPile.map((c) => c.toString()).join(', ')}");
  }

  static Future<void> restartGame() async {
    await endGame();
    await startNewGame();
  }

  static Future<void> nextHandOrEnd() async {
    if (GameValues.waitingForInsuranceDecision) {
      SettingsGlobalValues.logger.d(
          'Awaiting insurance decisions before moving to the next hand.');
      return;
    }
    SettingsGlobalValues.logger.d(
        "Changing from hand [${GameValues.currentHandIndex}] to [${GameValues.currentHandIndex + 1}]");
    GameValues.currentHandIndex++;
    if (GameValues.currentHandIndex < GameValues.player.hands.length) {
      if (GameValues.player.hands[GameValues.currentHandIndex].isSplitted) {
        GameValues.nbSplitInGame++;
        SettingsGlobalValues.logger
            .d("Splitted hand ${GameValues.currentHandIndex}, hitting");
        hit(GameValues.player.hands[GameValues.currentHandIndex]);
      } else if (isBlackjack()) {
        SettingsGlobalValues.logger
            .d("BlackJack for hand ${GameValues.currentHandIndex}");
        return await nextHandOrEnd();
      }
    } else {
      SettingsGlobalValues.logger.d("Hand not in index, playing for dealer");
      await playForDealer();
      GameValues.isGameEnded = true;
      SettingsGlobalValues.logger
          .d("Changing from hand [${GameValues.currentHandIndex}] to [-1]");
      GameValues.currentHandIndex = -1;
    }
  }

  static hit(Hand hand) async {
    hand.cards.add(await DeckLogic.drawCard());
    int handValue = hand.getValue();
    if (handValue > 21) {
      SettingsGlobalValues.logger
          .d("Bust at $handValue for hand ${GameValues.currentHandIndex}");
      return await nextHandOrEnd();
    }
    if (handValue == 21 && hand.cards.length == 2) {
      return await nextHandOrEnd();
    }
    if (handValue == 21) {
      SettingsGlobalValues.logger
          .d("21 for hand ${GameValues.currentHandIndex}");
      return await nextHandOrEnd();
    }
    SettingsGlobalValues.logger
        .d("$handValue for hand ${GameValues.currentHandIndex}");
    return;
  }

  static stand(Hand hand) async {
    if (GameValues.currentHandIndex == -1) {
      throw Exception("Current hand is -1 but should exist to stand !");
    } else {
      SettingsGlobalValues.logger
          .d("${hand.getValue()} for hand ${GameValues.currentHandIndex}");
      return await nextHandOrEnd();
    }
  }

  static bool isFirstTurnForHand() {
    return GameValues.currentHandIndex >= 0 &&
        GameValues.currentHandIndex < GameValues.player.hands.length &&
        GameValues.player.hands[GameValues.currentHandIndex].cards.length <= 2;
  }

  static bool canDoubleCurrentHand() {
    if (!isFirstTurnForHand()) {
      return false;
    }
    final Hand hand = GameValues.player.hands[GameValues.currentHandIndex];
    if (hand.cards.length != 2) {
      return false;
    }
    if (hand.bet <= 0) {
      return false;
    }
    return GameValues.playerTokens >= hand.bet;
  }

  static Future<void> double(Hand hand) async {
    if (!canDoubleCurrentHand()) {
      SettingsGlobalValues.logger
          .d('Double down refused: requirements are not met.');
      return;
    }
    GameValues.playerTokens -= hand.bet;
    hand.bet *= 2;
    hand.cards.add(await DeckLogic.drawCard());
    int handValue = hand.getValue();
    if (handValue > 21) {
      SettingsGlobalValues.logger
          .d("Bust at $handValue for hand ${GameValues.currentHandIndex}");
      return await nextHandOrEnd();
    }
    if (handValue == 21) {
      SettingsGlobalValues.logger
          .d("21 for hand ${GameValues.currentHandIndex}");
      return await nextHandOrEnd();
    }
    SettingsGlobalValues.logger
        .d("$handValue for hand ${GameValues.currentHandIndex}");
    return await nextHandOrEnd();
  }

  static surrender(Hand hand) async {
    SettingsGlobalValues.logger.d(
        "Surrendering hand ${GameValues.currentHandIndex} with ${hand.getValue()}");
    hand.isSurrender = true;
    return await nextHandOrEnd();
  }

  static bool canSplit() {
    if (!isFirstTurnForHand()) {
      return false;
    }
    final Hand hand = GameValues.player.hands[GameValues.currentHandIndex];
    if (hand.cards.length != 2) {
      return false;
    }
    if (!hand.cards.every((card) => card.value == hand.cards.first.value)) {
      return false;
    }
    if (hand.bet <= 0) {
      return false;
    }
    return GameValues.playerTokens >= hand.bet;
  }

  static split(Hand hand) {
    if (GameValues.currentHandIndex == -1) {
      throw Exception("Current hand is -1 but should exist to split !");
    } else {
      if (GameValues.playerTokens < hand.bet) {
        SettingsGlobalValues.logger
            .d('Split refused: not enough tokens remaining.');
        return;
      }
      GameValues.playerTokens -= hand.bet;
      Hand splittedHand = Hand();
      splittedHand.isSplitted = true;
      splittedHand.isPlayed = true;
      splittedHand.cards.add(hand.cards.removeAt(1));
      splittedHand.bet = hand.bet;
      SettingsGlobalValues.logger.d(
          "Adding one hand from split at index [${GameValues.currentHandIndex + 1}]");
      GameValues.player.hands
          .insert(GameValues.currentHandIndex + 1, splittedHand);
      return hit(hand);
    }
  }

  static Future<void> resolveInsurancePhase() async {
    if (!GameValues.waitingForInsuranceDecision) {
      return;
    }
    GameValues.waitingForInsuranceDecision = false;
    await nextHandOrEnd();
  }

  static createHands() {
    GameValues.handsToPlay.clear();
    for (int i = 0; i < SettingsGlobalValues.maxHands.settingValue; i++) {
      GameValues.handsToPlay.add(Hand());
    }
    SettingsGlobalValues.logger
        .d("Changing from hand [${GameValues.currentHandIndex}] to [-1]");
    GameValues.currentHandIndex = -1;
  }

  static bool isBlackjack() {
    return GameValues.player.hands[GameValues.currentHandIndex].getValue() ==
        21;
  }

  static Future<void> playForDealer() async {
    while (GameValues.dealerHand.getValue() < 17) {
      await hit(GameValues.dealerHand);
    }
    HistoryGame historyGame = HistoryGame();
    for (Card card in GameValues.dealerHand.cards) {
      historyGame.dealerHand.cards.add(card);
    }
    historyGame.dealerHand.isDealer = true;
    for (Hand hand in GameValues.player.hands) {
      HistoryHand historyHand = HistoryHand();
      for (Card card in hand.cards) {
        historyHand.cards.add(card);
      }
      historyHand.isSurrender = hand.isSurrender;
      historyHand.bet = hand.bet;
      historyHand.insuranceBet = hand.insuranceBet;
      historyGame.playerHands.add(historyHand);
    }
    historyGame.updateStats();
    settleBets(historyGame);
    await HistoryManager.addGame(historyGame);
  }

  static VictoryStatus getVictoryStatus(Hand dealerHand, Hand hand) {
    int handValue = hand.getValue();
    int dealerValue = dealerHand.getValue();
    if (handValue > 21) {
      return VictoryStatus.bust;
    } else if (hand.isSurrender) {
      return VictoryStatus.surrender;
    } else if (dealerValue > 21) {
      if (handValue == 21 && hand.cards.length == 2) {
        return VictoryStatus.blackJack;
      } else {
        return VictoryStatus.win;
      }
    } else if (dealerValue == 21 &&
        dealerHand.cards.length == 2 &&
        handValue == 21 &&
        hand.cards.length == 2) {
      return VictoryStatus.draw;
    } else if (dealerValue == 21 &&
        dealerHand.cards.length == 2 &&
        handValue <= 21) {
      return VictoryStatus.lost;
    } else if (handValue == 21 && hand.cards.length == 2) {
      return VictoryStatus.blackJack;
    } else if (dealerValue == handValue) {
      return VictoryStatus.draw;
    } else if (dealerValue < handValue) {
      return VictoryStatus.win;
    } else if (dealerValue > handValue) {
      return VictoryStatus.lost;
    } else {
      SettingsGlobalValues.logger.f(
          "Impossible victory status for dealerValue: [${dealerHand.getCardsValues()}] and handValue: [${hand.getCardsValues()}]");
      return VictoryStatus.empty;
    }
  }

  static void settleBets(HistoryGame historyGame) {
    final bool dealerBlackjack = GameValues.dealerHand.getValue() == 21 &&
        GameValues.dealerHand.cards.length == 2;

    for (int i = 0; i < historyGame.playerHands.length; i++) {
      final HistoryHand historyHand = historyGame.playerHands[i];
      final Hand hand = GameValues.player.hands[i];

      int payout = 0;
      switch (historyHand.victoryStatus) {
        case VictoryStatus.win:
          payout = hand.bet * 2;
          break;
        case VictoryStatus.blackJack:
          payout = hand.bet + (hand.bet * 3 ~/ 2);
          break;
        case VictoryStatus.draw:
          payout = hand.bet;
          break;
        case VictoryStatus.surrender:
          payout = hand.bet ~/ 2;
          break;
        case VictoryStatus.lost:
        case VictoryStatus.bust:
        case VictoryStatus.empty:
          payout = 0;
          break;
      }

      historyHand.payout = payout;
      GameValues.playerTokens += payout;

      int insurancePayout = 0;
      if (hand.insuranceBet > 0) {
        if (dealerBlackjack) {
          insurancePayout = hand.insuranceBet * 3;
        }
      }
      historyHand.insurancePayout = insurancePayout;
      GameValues.playerTokens += insurancePayout;

      hand.insuranceBet = 0;
    }

    if (GameValues.playerTokens <= 0) {
      GameValues.bankruptcyCount++;
      GameValues.playerTokens = SettingsGlobalValues.bankruptcyResetTokens;
    }
  }

  static resetAll() {
    DeckLogic.resetDeck();
    GameValues.player.hands.clear();
    GameValues.dealerHand.cards.clear();
    GameValues.handsToPlay.clear();
    GameValues.waitingForInsuranceDecision = false;
    GameValues.currentHandIndex = -1;
  }
}
