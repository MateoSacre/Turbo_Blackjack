import 'package:turbo_blackjack/Game/Data/History/history_game.dart';
import 'package:turbo_blackjack/Game/Data/History/history_manager.dart';

import '../../Settings/settings_global_values.dart';
import '../Data/Card.dart';
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
  static startNewGame() async {
    GameValues.isGameStarted = true;
    for (Hand hand in GameValues.player.hands) {
      hand.cards.add(await DeckLogic.drawCard());
    }
    GameValues.dealerHand.cards.add(await DeckLogic.drawCard());
    for (Hand hand in GameValues.player.hands) {
      hand.cards.add(await DeckLogic.drawCard());
    }
    nextHandOrEnd();
  }

  static Future<void> endGame() async {
    GameValues.isGameStarted = false;
    GameValues.isGameEnded = false;
    for (Card card in GameValues.dealerHand.cards) {
      GameValues.discardPile.add(card);
    }
    GameValues.dealerHand.cards.clear();
    for (Hand hand in GameValues.player.hands) {
      for (Card card in hand.cards) {
        GameValues.discardPile.add(card);
      }
      hand.cards.clear();
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

  static double(Hand hand) async {
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
    return isFirstTurnForHand() &&
        GameValues.player.hands[GameValues.currentHandIndex].cards.every(
            (card) =>
                card.value ==
                GameValues.player.hands[GameValues.currentHandIndex].cards.first
                    .value);
  }

  static split(Hand hand) {
    if (GameValues.currentHandIndex == -1) {
      throw Exception("Current hand is -1 but should exist to split !");
    } else {
      Hand splittedHand = Hand();
      splittedHand.isSplitted = true;
      splittedHand.isPlayed = true;
      splittedHand.cards.add(hand.cards.removeAt(1));
      SettingsGlobalValues.logger.d(
          "Adding one hand from split at index [${GameValues.currentHandIndex + 1}]");
      GameValues.player.hands
          .insert(GameValues.currentHandIndex + 1, splittedHand);
      return hit(hand);
    }
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
      historyGame.playerHands.add(historyHand);
    }
    historyGame.updateStats();
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

  static resetAll() {
    DeckLogic.resetDeck();
    GameValues.player.hands.clear();
    GameValues.dealerHand.cards.clear();
    GameValues.handsToPlay.clear();
  }
}
