import 'dart:math';

import '../../Settings/settings_global_values.dart';
import '../Data/card.dart';
import '../Data/game_values.dart';
import '../Notifier/deck_notifier.dart';

/// Two real, documented shuffling models, selected by the "Use Shuffler"
/// setting. See README.md ("Shuffler models") for the full write-up and
/// sources.
///
/// - Off: a batch shoe. When it runs out, discards are riffled back in
///   using the Gilbert-Shannon-Reeds (GSR) model, the standard mathematical
///   model of a real riffle shuffle.
/// - On: a Continuous Shuffling Machine (CSM), modelled after Shuffle
///   Master's patented design (US 6,254,096 / US 7,137,627): cards are fed
///   one at a time into randomly chosen compartments and the shoe is
///   refilled by emptying a randomly chosen compartment whenever it runs
///   low.
class DeckLogic {
  static final random = Random();

  static void checkForDeckShuffle() {
    if (SettingsGlobalValues.useShuffler.settingValue) {
      _feedDiscardIntoShuffler();
      _refillShoeFromShuffler();
    } else {
      if (GameValues.deck.isEmpty) {
        resetDeck();
      }
    }
  }

  static void resetDeck() {
    GameValues.deck.addAll(GameValues.discardPile);
    GameValues.discardPile.clear();
    shuffleDeck();
  }

  // --- Batch shoe: Gilbert-Shannon-Reeds riffle shuffle -------------------
  // Model: Gilbert (1955) / Reeds (1981), analyzed by Bayer & Diaconis,
  // "Trailing the Dovetail Shuffle to its Lair" (1992).
  // https://en.wikipedia.org/wiki/Gilbert%E2%80%93Shannon%E2%80%93Reeds_model

  /// Riffles the shoe enough times to be well mixed. Bayer & Diaconis show
  /// that a GSR riffle shuffle reaches total-variation mixing after
  /// ~(3/2)*log2(n) riffles (the famous "7 shuffles for 52 cards" result);
  /// we round up and add a small safety margin since our shoe can hold
  /// several decks (n > 52), which need proportionally more riffles.
  static void shuffleDeck() {
    final int n = GameValues.deck.length;
    if (n < 2) return;
    final int riffleCount = (1.5 * (log(n) / log(2))).ceil() + 2;
    SettingsGlobalValues.logger.d(
        "Riffling $n-card shoe $riffleCount times (Gilbert-Shannon-Reeds model).");
    for (int round = 1; round <= riffleCount; round++) {
      GameValues.deck = gsrRiffle(GameValues.deck, random);
      SettingsGlobalValues.logger.t(
          "Riffle #$round: ${GameValues.deck.map((c) => c.toString()).join(', ')}");
    }
  }

  /// A single Gilbert-Shannon-Reeds riffle: cut the deck into two packets
  /// at a binomially-distributed point (a fair coin flip per card decides
  /// which packet it starts in - an imperfect cut, not an exact half/half
  /// split), then interleave the two packets by dropping the next card
  /// from whichever packet has more cards remaining, weighted by their
  /// current sizes. That weighting is the defining rule of the GSR model.
  static List<Card> gsrRiffle(List<Card> deck, Random random) {
    final int n = deck.length;
    int cut = 0;
    for (int i = 0; i < n; i++) {
      if (random.nextBool()) cut++;
    }
    final List<Card> left = deck.sublist(0, cut);
    final List<Card> right = deck.sublist(cut);
    final List<Card> result = [];
    int i = left.length;
    int j = right.length;
    while (i > 0 || j > 0) {
      final bool takeFromLeft;
      if (i == 0) {
        takeFromLeft = false;
      } else if (j == 0) {
        takeFromLeft = true;
      } else {
        takeFromLeft = random.nextDouble() < i / (i + j);
      }
      if (takeFromLeft) {
        result.add(left[left.length - i]);
        i--;
      } else {
        result.add(right[right.length - j]);
        j--;
      }
    }
    return result;
  }

  static List<Card> _basicShuffle(List<Card> deck, Random random) {
    for (int i = deck.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      Card temp = deck[i];
      deck[i] = deck[j];
      deck[j] = temp;
    }
    return deck;
  }

  // --- Continuous Shuffling Machine (CSM) ---------------------------------
  // Model: Shuffle Master's continuous shuffler, US Patent 6,254,096
  // ("Device and method for continuously shuffling cards") and its
  // continuation US Patent 7,137,627 ("...and monitoring cards").
  // https://patents.google.com/patent/US6254096B1/en
  // https://patents.google.com/patent/US7137627B2/en
  //
  // The real machine holds 13-19 card compartments (17-19 "optimal" per the
  // patent). Discarded cards are pushed one at a time into a randomly
  // selected compartment, skipping any compartment already at its maximum
  // load. When the dealing shoe's buffer drops low, the machine randomly
  // selects one compartment and empties it whole into the shoe, skipping
  // compartments holding 7 or fewer cards "to maintain reasonable shuffling
  // speed". The patent doesn't publish the exact per-compartment maximum or
  // the shoe's exact buffer size across all models; we use the patent's own
  // "for example, 20 cards" buffer figure, and a fixed cap sized to
  // comfortably hold this app's largest supported shoe (7 decks = 364
  // cards) across 17 compartments with headroom for uneven distribution.

  static const int compartmentCount = 17;
  static const int compartmentMaxCapacity = 30;
  static const int compartmentUnloadPreferenceThreshold = 7;
  static const int shoeBufferTarget = 20;

  static void _feedDiscardIntoShuffler() {
    while (GameValues.discardPile.isNotEmpty) {
      _loadCardIntoCompartment(GameValues.discardPile.removeLast());
    }
  }

  /// Randomly assigns [card] to a compartment, skipping any compartment
  /// already at [compartmentMaxCapacity]. Falls back to any compartment if
  /// every one of them is full (should not happen in practice).
  static void _loadCardIntoCompartment(Card card) {
    final compartments = GameValues.shufflerCompartments;
    final eligible = [
      for (int i = 0; i < compartments.length; i++)
        if (compartments[i].length < compartmentMaxCapacity) i
    ];
    final candidates =
        eligible.isNotEmpty ? eligible : List.generate(compartments.length, (i) => i);
    final chosen = candidates[random.nextInt(candidates.length)];
    compartments[chosen].add(card);
    SettingsGlobalValues.logger
        .t("Shuffler: loaded ${card.toString()} into compartment $chosen.");
  }

  /// Tops the shoe back up to [shoeBufferTarget] by randomly picking a
  /// well-loaded compartment (more than [compartmentUnloadPreferenceThreshold]
  /// cards, per the patent) and dumping its whole contents into the shoe.
  /// Falls back to any non-empty compartment when nothing is well-loaded
  /// yet (e.g. right after the machine is first loaded with a fresh shoe).
  static void _refillShoeFromShuffler() {
    while (GameValues.deck.length < shoeBufferTarget) {
      final compartments = GameValues.shufflerCompartments;
      final wellLoaded = <int>[];
      final anyNonEmpty = <int>[];
      for (int i = 0; i < compartments.length; i++) {
        if (compartments[i].isEmpty) continue;
        anyNonEmpty.add(i);
        if (compartments[i].length > compartmentUnloadPreferenceThreshold) {
          wellLoaded.add(i);
        }
      }
      final candidates = wellLoaded.isNotEmpty ? wellLoaded : anyNonEmpty;
      if (candidates.isEmpty) {
        break; // Nothing left in the machine yet.
      }
      final chosen = candidates[random.nextInt(candidates.length)];
      final cards = compartments[chosen];
      _basicShuffle(cards, random);
      SettingsGlobalValues.logger.d(
          "Shuffler: emptying compartment $chosen (${cards.length} cards) into the shoe.");
      GameValues.deck.addAll(cards);
      cards.clear();
    }
  }

  static Future<Card> drawCard() async {
    checkForDeckShuffle();
    Card card = GameValues.deck.removeLast();
    SettingsGlobalValues.logger.t(
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

  static void addCardsToDeck() {
    final freshCards = <Card>[];
    for (int i = 0; i < SettingsGlobalValues.deckCount.settingValue; i++) {
      for (Color color in Color.values) {
        for (int value = 1; value <= 13; value++) {
          freshCards.add(Card(value, color));
        }
      }
    }

    if (SettingsGlobalValues.useShuffler.settingValue) {
      // Mirrors an attendant loading fresh decks into the machine: cards go
      // straight into random compartments and the shoe starts empty, then
      // primes itself from the compartments (see _refillShoeFromShuffler).
      GameValues.shufflerCompartments =
          List.generate(compartmentCount, (_) => []);
      for (final card in freshCards) {
        _loadCardIntoCompartment(card);
      }
      _refillShoeFromShuffler();
    } else {
      GameValues.deck.addAll(freshCards);
      shuffleDeck();
    }
  }
}
