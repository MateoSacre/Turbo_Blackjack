import 'dart:math';

import '../../Settings/settings_global_values.dart';
import '../Data/Card.dart';
import '../Data/game_values.dart';
import '../Notifier/deck_notifier.dart';

class DeckLogic {
  static final random = Random();

  static checkForDeckShuffle() {
    if (SettingsGlobalValues.useShuffler.settingValue) {
      if (GameValues.discardPile.length >= 10) {
        shuffleWithShuffler();
      }
    } else {
      if (GameValues.deck.isEmpty) {
        resetDeck();
      }
    }
  }

  static resetDeck() {
    GameValues.deck.addAll(GameValues.discardPile);
    GameValues.discardPile.clear();
    shuffleDeck();
  }

  static void shuffleDeck() {
    int shuffleCount = 5 + random.nextInt(6); // [5,10]
    print("Number of shuffles to perform: $shuffleCount");
    shuffleDeckXTimes(shuffleCount);
  }

  static void shuffleDeckXTimes(int shuffleCount) {
    List<Card> deck = List.from(GameValues.deck);
    if (!GameValues.isGameStarted &&
        deck.isNotEmpty &&
        deck.length != SettingsGlobalValues.deckCount.settingValue * 52) {
      print("Error in deck size while shuffling");
    }
    print("Start - Initial deck: ${deck.map((c) => c.toString()).join(', ')}");

    if (deck.isEmpty) {
      print("Deck empty, shuffle cancelled.");
      GameValues.deck.addAll(GameValues.discardPile);
      GameValues.discardPile.clear();
    }

    for (int round = 1; round <= shuffleCount; round++) {
      print("\n--- Shuffle #$round ---");

      if (deck.length < 8) {
        print(
            "Deck too small to cut, using simple shuffle (Fisher-Yates).");
        deck = _basicShuffle(deck, random);
        continue;
      }

      List<List<Card>> subDecks = _splitDeckIntoSubDecks(deck, 4);
      List<List<Card>> mixedSubDecks = _mixSubDecks(subDecks);
      deck = _interlaceSubDecks(mixedSubDecks);
    }

    print(
        "\nFinal deck of [${deck.length}] cards after $shuffleCount shuffles: ${deck.map((c) => c.toString()).join(', ')}");
    GameValues.deck = deck;
  }

  static List<Card> _basicShuffle(List<Card> deck, Random random) {
    for (int i = deck.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      Card temp = deck[i];
      deck[i] = deck[j];
      deck[j] = temp;
    }
    print(
        "Shuffled deck (simple): ${deck.map((c) => c.toString()).join(', ')}");
    return deck;
  }

  static List<List<Card>> _splitDeckIntoSubDecks(
      List<Card> deck, int numSubDecks) {
    List<List<Card>> subDecks = [];
    int baseSize = (deck.length / numSubDecks).floor();
    int remainder = deck.length % numSubDecks;
    int currentIndex = 0;

    for (int i = 0; i < numSubDecks; i++) {
      int currentSize = baseSize + (i < remainder ? 1 : 0);
      int end = currentIndex + currentSize;
      subDecks.add(deck.sublist(currentIndex, end));
      print(
          "SubDeck $i : ${deck.sublist(currentIndex, end).map((c) => c.toString()).join(', ')}");
      currentIndex = end;
    }

    return subDecks;
  }

  static List<List<Card>> _mixSubDecks(List<List<Card>> subDecks) {
    List<List<Card>> mixedSubDecks = [];

    for (int d = 0; d < subDecks.length; d++) {
      List<Card> subDeck = subDecks[d];
      if (subDeck.length < 2) {
        mixedSubDecks.add(List<Card>.from(subDeck));
        print("SubDeck $d too small to split, unchanged.");
        continue;
      }

      int middle = (subDeck.length / 2).ceil();
      List<Card> firstHalf = subDeck.sublist(0, middle);
      List<Card> secondHalf = subDeck.sublist(middle);

      print("SubDeck $d split into:");
      print("- First half: ${firstHalf.map((c) => c.toString()).join(', ')}");
      print("- Second half: ${secondHalf.map((c) => c.toString()).join(', ')}");

      List<Card> mixed = [];
      int i = 0, j = 0;
      while (i < firstHalf.length || j < secondHalf.length) {
        if (i < firstHalf.length) mixed.add(firstHalf[i++]);
        if (j < secondHalf.length) mixed.add(secondHalf[j++]);
      }

      print(
          "SubDeck $d shuffled: ${mixed.map((c) => c.toString()).join(', ')}");
      mixedSubDecks.add(mixed);
    }

    return mixedSubDecks;
  }

  static List<Card> _interlaceSubDecks(List<List<Card>> subDecks) {
    List<Card> finalDeck = [];
    List<int> indices = List.filled(subDecks.length, 0);
    bool hasCards = true;

    while (hasCards) {
      hasCards = false;
      for (int i = 0; i < subDecks.length; i++) {
        if (indices[i] < subDecks[i].length) {
          finalDeck.add(subDecks[i][indices[i]++]);
          hasCards = true;
        }
      }
    }

    finalDeck.sort((a, b) => a.value.compareTo(b.value));
    print(
        "Deck of [${finalDeck.length}] cards rebuilt after interlacing: ${finalDeck.map((c) => c.toString()).join(', ')}");
    return finalDeck;
  }

  static Future<Card> drawCard() async {
    checkForDeckShuffle();
    Card card = GameValues.deck.removeLast();
    print(
        "\nDeck of [${GameValues.deck.length}] cards after draw: ${GameValues.deck.map((c) => c.toString()).join(', ')}");
    await waitForDraw();

    // Notify the application globally
    DeckNotifier.instance.notifyCardDrawn();

    return card;
  }

  static waitForDraw() async {
    await Future.delayed(
        const Duration(milliseconds: SettingsGlobalValues.timeBetweenDrawsMS));
  }

  static void shuffleWithShuffler() {
    if (GameValues.discardPile.length < 10) return; // Should be impossible

    // Step 1: split the deck into as many piles as there are cards in the discard pile
    final pileCount = GameValues.discardPile.length;
    List<List<Card>> piles = List.generate(pileCount, (_) => []);
    for (int i = 0; i < GameValues.deck.length; i++) {
      piles[i % pileCount].add(GameValues.deck[i]);
    }

    // Step 2: sort the discard pile by cards most favorable to the dealer (countValue descending)
    GameValues.discardPile
        .sort((a, b) => b.getCountValue().compareTo(a.getCountValue()));

    // Initial state logs
    for (int i = 0; i < piles.length; i++) {
      print(
          "\nPile [${i}] of [${piles[i].length}] cards at start of shuffle: ${piles[i].map((c) => c.toString()).join(', ')}");
    }
    print(
        "\nDeck of [${GameValues.deck.length}] cards at start of shuffle: ${GameValues.deck.map((c) => c.toString()).join(', ')}");
    print(
        "\nDiscard pile of [${GameValues.discardPile.length}] cards at start of shuffle: ${GameValues.discardPile.map((c) => c.toString()).join(', ')}");

    // Step 3: compute the local running count of each pile
    List<int> pileLocalCounts = List<int>.generate(piles.length, (i) {
      int local = 0;
      for (final c in piles[i]) local += c.getCountValue();
      return local;
    });

    // Build a list of pile indices sorted by localCount descending
    List<int> pileIndices = List<int>.generate(piles.length, (i) => i);
    pileIndices
        .sort((i, j) => pileLocalCounts[j].compareTo(pileLocalCounts[i]));

    // Cards sorted by countValue descending (already sorted above)
    final int n = min(GameValues.discardPile.length, piles.length);

    // Step 4: optimal one-to-one pairing (card[k] -> pileIndices[k])
    for (int k = 0; k < n; k++) {
      final card = GameValues.discardPile[k];
      final int targetPileIndex = pileIndices[k];

      // Defensive recomputation of beforeCount if you want the exact log at time t
      int beforeCount = 0;
      for (final c in piles[targetPileIndex]) beforeCount += c.getCountValue();

      // Log avant insertion
      print(
          "shuffleWithShuffler[card=${card.getCardValue()},value=${card.value},countValue=${card.getCountValue()},"
          "pileIndex=${targetPileIndex},pileCountBefore=${beforeCount},pileCountAfter=${beforeCount + card.getCountValue()}]");

      // Insertion: here in the middle of the pile (kept)
      piles[targetPileIndex]
          .insert((piles[targetPileIndex].length / 2).floor(), card);
    }

    // Step 5: merge the piles into a new deck
    GameValues.deck = piles.expand((pile) => pile).toList();

    // Empty the discard pile (cards have been reassigned)
    GameValues.discardPile.clear();

    // Final state logs
    for (int i = 0; i < piles.length; i++) {
      print(
          "\nPile [${i}] of [${piles[i].length}] cards at end of shuffle: ${piles[i].map((c) => c.toString()).join(', ')}");
    }
    print(
        "\nDeck of [${GameValues.deck.length}] cards at end of shuffle: ${GameValues.deck.map((c) => c.toString()).join(', ')}");
    print(
        "\nDiscard pile of [${GameValues.discardPile.length}] cards at end of shuffle: ${GameValues.discardPile.map((c) => c.toString()).join(', ')}");
  }

  static int getSum(int i, int j) {
    return i + j;
  }

  static addCardsToDeck() {
    for (int i = 0; i < SettingsGlobalValues.deckCount.settingValue; i++) {
      for (Color color in Color.values) {
        for (int value = 1; value <= 13; value++) {
          GameValues.deck.add(Card(value, color));
        }
      }
    }
    shuffleDeckXTimes(50 + random.nextInt(950));
  }
}
