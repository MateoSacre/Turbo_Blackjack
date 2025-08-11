import '../../Settings/settings_global_values.dart';
import '../Data/Card.dart';
import '../Data/game_values.dart';
import 'deck_logic.dart';

class GameLogic {
  static startNewGame() async {
    GameValues.isGameStarted = true;
    GameValues.isDrawing = true;
    for (Hand hand in GameValues.player.hands) {
      hand.cards.add(await DeckLogic.drawCard());
    }
    GameValues.dealerHand.cards.add(await DeckLogic.drawCard());
    for (Hand hand in GameValues.player.hands) {
      hand.cards.add(await DeckLogic.drawCard());
    }
    GameValues.isDrawing = false;
    nextHandOrEnd();
  }

  static void endGame() {
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
    SettingsGlobalValues.logger.d(
        "\nDeck of [${GameValues.deck.length}] cards at end of game: ${GameValues.deck.map((c) => c.toString()).join(', ')}");
    SettingsGlobalValues.logger.d(
        "\nDiscard pile of [${GameValues.discardPile.length}] cards at end of game: ${GameValues.discardPile.map((c) => c.toString()).join(', ')}");
  }

  static Future<void> restartGame() async {
    endGame();
    await startNewGame();
  }

  static Future<void> nextHandOrEnd() async {
    SettingsGlobalValues.logger.d(
        "Changing from hand [${GameValues.currentHandIndex}] to [${GameValues.currentHandIndex + 1}]");
    GameValues.currentHandIndex++;
    if (GameValues.currentHandIndex < GameValues.player.hands.length) {
      if (GameValues.player.hands[GameValues.currentHandIndex].isSplitted) {
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
      GameValues.currentHandIndex = -1;
      await playForDealer();
      GameValues.isGameEnded = true;
    }
  }

  static hit(Hand hand) async {
    GameValues.isDrawing = true;
    hand.cards.add(await DeckLogic.drawCard());
    GameValues.isDrawing = false;
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
  }

  static resetAll() {
    DeckLogic.resetDeck();
    GameValues.player.hands.clear();
    GameValues.dealerHand.cards.clear();
    GameValues.handsToPlay.clear();
  }
}
