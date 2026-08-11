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
  static int getTotalBet() {
    int total = 0;
    for (final hand in GameValues.player.hands) {
      total += hand.bet;
    }
    return total;
  }

  static bool canStartGame() {
    if (GameValues.player.hands.isEmpty) {
      return false;
    }
    if (GameValues.player.hands.any((hand) => hand.bet <= 0)) {
      return false;
    }
    return getTotalBet() * 2 <= GameValues.tokens;
  }

  static bool canIncreaseBet(Hand hand) {
    if (GameValues.isGameStarted || GameValues.isGameEnded) {
      return false;
    }
    if (!GameValues.player.hands.contains(hand)) {
      return false;
    }
    return (getTotalBet() + 1) * 2 <= GameValues.tokens;
  }

  static bool canDecreaseBet(Hand hand) {
    if (GameValues.isGameStarted || GameValues.isGameEnded) {
      return false;
    }
    return hand.bet > 0;
  }

  // Step size grows by a power of 10 every time the bet crosses one:
  // 1-by-1 below 10, 10-by-10 below 100, 100-by-100 below 1000, etc.
  // This lets a press-and-hold on the bet buttons place large bets quickly.
  static int _stepForValue(int value) {
    int step = 1;
    while (step * 10 <= value) {
      step *= 10;
    }
    return step;
  }

  static int getBetIncreaseStep(Hand hand) {
    if (!canIncreaseBet(hand)) {
      return 0;
    }
    final int step = _stepForValue(hand.bet);
    final int maxTotal = GameValues.tokens ~/ 2;
    final int remaining = maxTotal - getTotalBet();
    return step > remaining ? remaining : step;
  }

  static int getBetDecreaseStep(Hand hand) {
    if (!canDecreaseBet(hand)) {
      return 0;
    }
    final int step = _stepForValue(hand.bet - 1);
    return step > hand.bet ? hand.bet : step;
  }

  // In half-token units: bet/2 tokens == bet half-tokens.
  static int getInsuranceCost(Hand hand) {
    return hand.bet;
  }

  static bool canTakeInsurance(Hand hand) {
    // Real blackjack rules only offer insurance once, right after the
    // deal, before any hand acts - not "any time during a hand's first
    // turn" like this used to allow.
    if (!GameValues.waitingForInsuranceDecision) {
      return false;
    }
    if (!GameValues.player.hands.contains(hand)) {
      return false;
    }
    if (hand.insuranceBet > 0 || hand.bet <= 0) {
      return false;
    }
    if (GameValues.dealerHand.cards.isEmpty ||
        GameValues.dealerHand.cards.first.getTrueValue() != 1) {
      return false;
    }
    return GameValues.tokens >= getInsuranceCost(hand);
  }

  static void takeInsurance(Hand hand) {
    if (!canTakeInsurance(hand)) {
      return;
    }
    final insuranceCost = getInsuranceCost(hand);
    GameValues.tokens -= insuranceCost;
    hand.insuranceBet = insuranceCost;
    SettingsGlobalValues.logger.d(
        "Insurance of $insuranceCost taken for hand ${GameValues.currentHandIndex}");
  }

  // The card drawn on a double (and the hand's running total) stay hidden
  // from the player until the round is fully resolved AND the player has
  // explicitly hit "Reveal", so doubling carries the same suspense as a
  // real "double down blind" table rule right up to that final moment.
  static bool shouldHideDoubleCard(Hand hand) {
    if (!SettingsGlobalValues.hideDoubleDownCard.settingValue ||
        !hand.isDoubled) {
      return false;
    }
    return !GameValues.isGameEnded || !GameValues.doubleCardsRevealed;
  }

  static bool hasHiddenDoubledHands() {
    if (!SettingsGlobalValues.hideDoubleDownCard.settingValue) {
      return false;
    }
    return GameValues.player.hands.any((hand) => hand.isDoubled);
  }

  static bool canDoubleCurrentHand() {
    if (!isFirstTurnForHand()) {
      return false;
    }
    final hand = GameValues.player.hands[GameValues.currentHandIndex];
    if (hand.isSurrender) {
      return false;
    }
    return GameValues.tokens >= hand.bet * 2;
  }

  static startNewGame() async {
    if (!canStartGame()) {
      SettingsGlobalValues.logger
          .w('Attempted to start a game without valid bets or tokens.');
      return;
    }

    GameValues.isGameStarted = true;
    GameValues.doubleCardsRevealed = false;
    final int totalBet = getTotalBet();
    GameValues.tokens -= totalBet * 2;

    for (Hand hand in GameValues.player.hands) {
      hand.cards.add(await DeckLogic.drawCard());
    }
    GameValues.dealerHand.cards.add(await DeckLogic.drawCard());
    for (Hand hand in GameValues.player.hands) {
      hand.cards.add(await DeckLogic.drawCard());
    }

    if (GameValues.dealerHand.cards.first.getTrueValue() == 1) {
      GameValues.waitingForInsuranceDecision = true;
      SettingsGlobalValues.logger
          .d("Dealer shows an Ace. Waiting for insurance decisions.");
      return;
    }

    await nextHandOrEnd();
  }

  static Future<void> resolveInsurancePhase() async {
    if (!GameValues.waitingForInsuranceDecision) {
      return;
    }
    GameValues.waitingForInsuranceDecision = false;
    await nextHandOrEnd();
  }

  static Future<void> endGame() async {
    GameValues.isGameStarted = false;
    GameValues.isGameEnded = false;
    GameValues.waitingForInsuranceDecision = false;
    GameValues.doubleCardsRevealed = false;
    for (Card card in GameValues.dealerHand.cards) {
      GameValues.discardPile.add(card);
    }
    GameValues.dealerHand.resetForNextRound();
    for (Hand hand in GameValues.player.hands) {
      for (Card card in hand.cards) {
        GameValues.discardPile.add(card);
      }
      hand.resetForNextRound();
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
          "Awaiting insurance decisions before moving to the next hand.");
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
        await hit(GameValues.player.hands[GameValues.currentHandIndex]);
      } else if (isBlackjack()) {
        SettingsGlobalValues.logger
            .d("BlackJack for hand ${GameValues.currentHandIndex}");
        return await nextHandOrEnd();
      }
    } else {
      SettingsGlobalValues.logger.d("Hand not in index, playing for dealer");
      await playForDealer();
      settleBets();
      GameValues.isGameEnded = true;
      SettingsGlobalValues.logger
          .d("Changing from hand [${GameValues.currentHandIndex}] to [-1]");
      GameValues.currentHandIndex = -1;
    }
  }

  static hit(Hand hand) async {
    hand.cards.add(await DeckLogic.drawCard());
    int handValue = hand.getValue();
    bool isDealerHand = hand == GameValues.dealerHand;
    if (handValue > 21) {
      SettingsGlobalValues.logger
          .d("Bust at $handValue for hand ${GameValues.currentHandIndex}");
      if (!isDealerHand) {
        return await nextHandOrEnd();
      }
      return;
    }
    if (handValue == 21 && hand.cards.length == 2) {
      if (!isDealerHand) {
        return await nextHandOrEnd();
      }
      return;
    }
    if (handValue == 21) {
      SettingsGlobalValues.logger
          .d("21 for hand ${GameValues.currentHandIndex}");
      if (!isDealerHand) {
        return await nextHandOrEnd();
      }
      return;
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

  static doubleOnHand(Hand hand) async {
    if (!canDoubleCurrentHand()) {
      SettingsGlobalValues.logger.d(
          "Cannot double hand ${GameValues.currentHandIndex} due to conditions");
      return;
    }
    GameValues.tokens -= hand.bet * 2;
    hand.bet *= 2;
    hand.isDoubled = true;
    SettingsGlobalValues.logger
        .d("Doubling hand ${GameValues.currentHandIndex} to bet ${hand.bet}");
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
    Hand hand = GameValues.player.hands[GameValues.currentHandIndex];
    if (GameValues.tokens < hand.bet * 2) {
      return false;
    }
    return hand.cards.every((card) => card.value == hand.cards.first.value);
  }

  static split(Hand hand) {
    if (GameValues.currentHandIndex == -1) {
      throw Exception("Current hand is -1 but should exist to split !");
    } else {
      if (!canSplit()) {
        SettingsGlobalValues.logger.d(
            "Cannot split hand ${GameValues.currentHandIndex} due to conditions");
        return;
      }
      GameValues.tokens -= hand.bet * 2;
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
      historyHand.isSplitted = hand.isSplitted;
      historyHand.bet = hand.bet;
      historyHand.insuranceBet = hand.insuranceBet;
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
    GameValues.player = Player();
    GameValues.dealer = Player(Hand());
    GameValues.dealerHand = GameValues.dealer.hands[0];
    GameValues.tokens = SettingsGlobalValues.startingTokens.settingValue * 2;
    GameValues.bankruptcyCount = 0;
    GameValues.player.hands.clear();
    GameValues.dealerHand.cards.clear();
    GameValues.handsToPlay.clear();
    GameValues.shufflerCompartments = [];
    GameValues.isGameStarted = false;
    GameValues.isGameEnded = false;
    GameValues.waitingForInsuranceDecision = false;
    GameValues.currentHandIndex = -1;
    GameValues.nbSplitInGame = 0;
  }

  static void settleBets() {
    final bool dealerHasBlackJack = GameValues.dealerHand.getValue() == 21 &&
        GameValues.dealerHand.cards.length == 2;

    for (final hand in GameValues.player.hands) {
      if (hand.bet <= 0) {
        hand.insuranceBet = 0;
        continue;
      }

      // Payouts below are expressed in half-token units: pay = bet(tokens)
      // * multiplier * 2, e.g. a 3:2 blackjack payout is hand.bet * 5.
      final status = getVictoryStatus(GameValues.dealerHand, hand);
      switch (status) {
        case VictoryStatus.blackJack:
          GameValues.tokens += hand.bet * 5;
          break;
        case VictoryStatus.win:
          GameValues.tokens += hand.bet * 4;
          break;
        case VictoryStatus.draw:
          GameValues.tokens += hand.bet * 2;
          break;
        case VictoryStatus.surrender:
          GameValues.tokens += hand.bet;
          break;
        case VictoryStatus.bust:
        case VictoryStatus.lost:
        case VictoryStatus.empty:
          break;
      }

      if (dealerHasBlackJack && hand.insuranceBet > 0) {
        GameValues.tokens += hand.insuranceBet * 3;
      }

      hand.insuranceBet = 0;
    }

    if (GameValues.tokens <= 0) {
      GameValues.tokens += GameValues.bankruptcyRefillTokens;
      GameValues.bankruptcyCount++;
    }
  }
}
