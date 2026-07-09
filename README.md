# turbo_blackjack

Time to train your BlackJack strats !

A Flutter blackjack trainer: play full hands against a dealer with real
betting, get live basic-strategy feedback on every decision, and review
your session history and stats afterwards.

## Features

- **Full blackjack rules**: hit, stand, double down, split, surrender,
  insurance (offered once, right after the deal, if the dealer shows an
  Ace — not "any time", matching real table rules).
- **Multiple simultaneous hands**: play 1 to several hands per round
  (configurable), including hands created by splitting.
- **Token betting**: place per-hand bets, double/split cost, insurance
  cost, and payouts (2:1, 3:2 blackjack, etc.) are all tracked as exact
  integer half-token units — no floating-point rounding drift. Running out
  of tokens triggers a bankruptcy refill and is tracked as a stat.
- **Basic strategy helper**: an optimal-play matrix (hard hands, soft
  hands, pairs) can be shown inline on each hand and/or as a popup after
  every action, telling you whether what you just did matched basic
  strategy.
- **Two real shuffling models**: see [Shuffler models](#shuffler-models)
  below.
- **Game history & stats**: every finished round is saved to disk; the
  Stats page charts win/loss/blackjack/bust/surrender rates and your
  current bankroll over a configurable number of recent games.
- **Responsive layout**: adapts card size, font size, and button/icon
  sizing to phone, tablet, and desktop-sized windows, in both portrait and
  landscape.

## Settings

| Setting | What it does |
|---|---|
| Deck Count | Number of 52-card decks in the shoe |
| Max Hands | Number of simultaneous player hands offered per round |
| Starting Tokens | Bankroll dealt at the start of a session |
| Show Best Option | Shows the basic-strategy recommendation on each hand |
| Show Best Option as Popup | Pops up a toast comparing your action to the recommendation |
| Use Shuffler | Switches between a batch shoe and a continuous shuffling machine — see below |

## Shuffler models

The "Use Shuffler" setting switches between two shuffling models, each based
on real, documented shuffling methods rather than an invented heuristic.
The implementation lives in [`lib/Game/Logic/deck_logic.dart`](lib/Game/Logic/deck_logic.dart).

### Off: batch shoe, Gilbert-Shannon-Reeds riffle

When the shoe runs out, every discarded card goes back in and gets riffled
using the **Gilbert-Shannon-Reeds (GSR) model** — the standard mathematical
model of a real riffle shuffle, developed by Edgar Gilbert and Claude
Shannon (1955) and J. Reeds (1981), and formally analyzed by Persi Diaconis
and Dave Bayer in *"Trailing the Dovetail Shuffle to its Lair"* (1992).

A single GSR riffle:

1. **Cut**: flip a fair coin for every card to decide whether it starts in
   the left or right packet. The size of the left packet therefore follows
   a Binomial(n, 1/2) distribution — an imperfect, realistic cut, not an
   exact half/half split.
2. **Interleave**: build the new deck one card at a time. At each step, the
   next card is dropped from whichever packet currently has more cards
   remaining, weighted by their sizes (`P(from left) = cards_left /
   (cards_left + cards_right)`). This weighting — cards are more likely to
   come from the bigger remaining packet — is the defining rule of the GSR
   model and is what actually produces (close to) uniformly random
   permutations, unlike a deterministic perfect interleave (a "faro"
   shuffle), which is fully predictable.

Bayer & Diaconis proved that a GSR-shuffled deck reaches statistical
randomness (total variation distance from uniform drops off sharply) after
about `(3/2) * log2(n)` riffles — the source of the famous "seven shuffles
for a 52-card deck" result. `DeckLogic.shuffleDeck()` uses that formula
(rounded up, with a small safety margin) so multi-deck shoes, which need
more riffles to mix than a single 52-card deck, automatically get them.

Sources:
- [Gilbert–Shannon–Reeds model — Wikipedia](https://en.wikipedia.org/wiki/Gilbert%E2%80%93Shannon%E2%80%93Reeds_model)
- Bayer, D. & Diaconis, P. (1992), *"Trailing the Dovetail Shuffle to its Lair"*, The Annals of Applied Probability — [PDF (Diaconis' site)](http://yaroslavvb.com/papers/diaconis-mathematical.pdf)

### On: Continuous Shuffling Machine (CSM)

Real casino blackjack tables often use a **Continuous Shuffling Machine**
instead of a batch shoe specifically to defeat card counting: discarded
cards are fed straight back into the machine and can reappear a few hands
later, so the deck composition never gets predictably depleted the way a
hand-dealt shoe does. This mode models Shuffle Master's patented design:

- US Patent 6,254,096 — *"Device and method for continuously shuffling cards"* — [Google Patents](https://patents.google.com/patent/US6254096B1/en)
- US Patent 7,137,627 — *"Device and method for continuously shuffling and monitoring cards"* (continuation, more detail on the selection algorithm) — [Google Patents](https://patents.google.com/patent/US7137627B2/en)

The patented machine holds a rack of physical card-receiving
**compartments** (13-19 of them, 17-19 "optimal" per the patent) and a
dealing shoe with a small buffer. `DeckLogic` mirrors this with
`GameValues.shufflerCompartments` (17 compartments) and the existing
`GameValues.deck` acting as the shoe:

- **Loading a discarded card**: the microprocessor "randomly select[s] the
  compartment which will receive each card", but skips any compartment
  already at its maximum load, to keep compartments from being packed
  unevenly.
- **Refilling the shoe**: when the shoe's buffer runs low, the machine
  "randomly selects the compartment to be unloaded" and empties it
  **whole** into the shoe in one action — not one card at a time — while
  skipping compartments holding 7 or fewer cards "to maintain reasonable
  shuffling speed" (quoted directly from the patent). The patent's own
  example targets keeping about 20 cards buffered in the shoe at all
  times; `DeckLogic.shoeBufferTarget` uses that same figure.
- **Recurrence rate**: the patent notes that a naively random 4-deck CSM
  would let a card reappear in the very next hand about 13.5% of the time;
  Shuffle Master's constrained design (the load/unload skip rules above)
  brings that down to about 4.3% — spreading discarded cards out more
  before they can come back into play. This app's compartment/threshold
  rules are the same shape of constraint, for the same reason.

The exact per-compartment maximum and buffer size aren't publicly specified
for every model (that level of detail is proprietary); this app uses
`compartmentMaxCapacity = 30`, chosen to comfortably hold the largest shoe
this app supports (7 decks, 364 cards) across 17 compartments with
headroom for random imbalance, and the patent's own "~20 cards" figure for
the shoe buffer target.

## Project structure

```
lib/
  main.dart                    App entry point, route table
  Game/
    home_page.dart             Home screen (Play / History / Stats)
    history_page.dart          Past-game history list
    stats_page.dart            Charts and bankroll summary
    Table/play_table.dart      Main game screen and controls
    Logic/
      game_logic.dart          Betting, turn flow, payouts, insurance phase
      deck_logic.dart          Shuffler models (see above)
      best_moves.dart          Basic strategy matrix and helper UI
    Data/
      card.dart                Card/Color model
      game_values.dart         Live game state (hands, tokens, deck, ...)
      History/                 Persisted per-game/per-hand history models
    Notifier/deck_notifier.dart
  Settings/
    settings_global_values.dart  Settings, theme constants, responsive sizing
    setting_page.dart            Settings screen
    settings_types.dart          Setting value types (bool/int) + JSON (de)serialization
```

## Getting started

Requires the Flutter SDK (Dart `>=3.4.3`). This project targets Windows and
Android primarily, but the standard `android/`, `ios/`, `linux/`, `macos/`,
`web/`, `windows/` platform folders are all present.

```bash
flutter pub get
flutter run -d windows   # or: android, chrome, etc.
```

> **Note**: `pubspec.yaml` currently points the `fluttertoast` dependency at
> a local sibling folder (`path: ../flutter_toast_update`) rather than a
> published package version. That folder needs to exist next to this repo
> for `flutter pub get` to succeed elsewhere.
