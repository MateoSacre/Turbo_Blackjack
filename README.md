# 🃏 Turbo Blackjack

**A cross-platform Flutter blackjack trainer built to be *correct*, not just playable —
exact-integer bankroll math, textbook basic strategy, and two shuffling engines each
modeled after a real, documented shuffling method (an academic riffle-shuffle model and
a patented casino machine) instead of `Random().shuffle()`.**

![Flutter](https://img.shields.io/badge/Flutter-3.4%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.4%2B-0175C2?logo=dart&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-informational)
![Version](https://img.shields.io/badge/version-0.5.7-blue)

---

## What it is

Turbo Blackjack is a single-player blackjack trainer: play full hands against a dealer
with real betting, get live basic-strategy feedback on every decision, and review your
session history and stats afterwards. It's built as a portfolio-grade Flutter app —
one codebase, six platform targets (Windows, Android, iOS, macOS, Linux, Web), with an
emphasis on getting the *domain logic* right: the parts of a casino game that are easy
to fake and hard to get precisely correct.

## Why it's interesting, technically

- **Exact-integer money math.** Every bet, double/split cost, insurance premium and
  payout (2:1, 3:2 blackjack, etc.) is tracked in half-token integer units — no
  floating-point drift ever creeps into the bankroll.
- **Two shuffling engines, both traceable to a primary source** — not an "arbitrary
  shuffle," but two independently modeled, sourced implementations:
  - A **Gilbert–Shannon–Reeds riffle-shuffle model** (Gilbert & Shannon 1955, Reeds
    1981), including the Bayer–Diaconis `(3/2)·log2(n)` mixing-time result to decide
    how many riffles a shoe needs.
  - A **Continuous Shuffling Machine** modeled directly on Shuffle Master's own patents
    (US 6,254,096 and US 7,137,627), reproducing its compartment-based load/unload
    algorithm and its documented card-recurrence behavior.
  
  See [Shuffler models](#shuffler-models) below for the full breakdown — it's the
  part of this project I'm most proud of.
- **A full basic-strategy engine** (hard hands, soft hands, pairs) driving both an
  inline hint and a post-action "did you play that right?" comparison.
- **One codebase, six targets.** Windows, Android, iOS, macOS, Linux and Web all build
  from the same Dart source, with a responsive layout that adapts card size, fonts and
  controls across phone, tablet and desktop, portrait or landscape.
- **Persisted history and analytics.** Every round is saved to disk; the stats screen
  charts win/loss/blackjack/bust/surrender rates and bankroll trend with `fl_chart`.

## Feature overview

- **Full blackjack rules**: hit, stand, double down, split, surrender, insurance
  (offered once, right after the deal, if the dealer shows an Ace — matching real
  table rules, not "any time").
- **Multiple simultaneous hands**: play 1 to several hands per round (configurable),
  including hands created by splitting.
- **Token betting** with exact accounting and bankruptcy-refill tracking.
- **Basic strategy helper**, inline and/or as a popup.
- **Two real shuffling models** — see below.
- **Game history & stats**, charted over a configurable window of recent games.
- **Responsive layout** across phone, tablet and desktop, portrait and landscape.

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

The "Use Shuffler" setting switches between two shuffling models, each based on real,
documented shuffling methods rather than an invented heuristic. The implementation
lives in [`lib/Game/Logic/deck_logic.dart`](lib/Game/Logic/deck_logic.dart).

### Off: batch shoe, Gilbert–Shannon–Reeds riffle

When the shoe runs out, every discarded card goes back in and gets riffled using the
**Gilbert–Shannon–Reeds (GSR) model** — the standard mathematical model of a real
riffle shuffle, developed by Edgar Gilbert and Claude Shannon (1955) and J. Reeds
(1981), and formally analyzed by Persi Diaconis and Dave Bayer in *"Trailing the
Dovetail Shuffle to its Lair"* (1992).

A single GSR riffle:

1. **Cut**: flip a fair coin for every card to decide whether it starts in the left or
   right packet. The size of the left packet follows a Binomial(n, 1/2) distribution —
   an imperfect, realistic cut, not an exact half/half split.
2. **Interleave**: build the new deck one card at a time. At each step, the next card
   is dropped from whichever packet currently has more cards remaining, weighted by
   their sizes (`P(from left) = cards_left / (cards_left + cards_right)`). This
   weighting is the defining rule of the GSR model and is what actually produces
   (close to) uniformly random permutations, unlike a deterministic perfect
   interleave (a "faro" shuffle), which is fully predictable.

Bayer & Diaconis proved that a GSR-shuffled deck reaches statistical randomness after
about `(3/2) * log2(n)` riffles — the source of the famous "seven shuffles for a
52-card deck" result. `DeckLogic.shuffleDeck()` uses that formula (rounded up, with a
small safety margin) so multi-deck shoes, which need more riffles to mix than a single
52-card deck, automatically get them.

Sources:
- [Gilbert–Shannon–Reeds model — Wikipedia](https://en.wikipedia.org/wiki/Gilbert%E2%80%93Shannon%E2%80%93Reeds_model)
- Bayer, D. & Diaconis, P. (1992), *"Trailing the Dovetail Shuffle to its Lair"*, The Annals of Applied Probability — [PDF (Diaconis' site)](http://yaroslavvb.com/papers/diaconis-mathematical.pdf)

### On: Continuous Shuffling Machine (CSM)

Real casino blackjack tables often use a **Continuous Shuffling Machine** instead of a
batch shoe specifically to defeat card counting: discarded cards are fed straight back
into the machine and can reappear a few hands later, so the deck composition never
gets predictably depleted the way a hand-dealt shoe does. This mode models Shuffle
Master's patented design:

- US Patent 6,254,096 — *"Device and method for continuously shuffling cards"* — [Google Patents](https://patents.google.com/patent/US6254096B1/en)
- US Patent 7,137,627 — *"Device and method for continuously shuffling and monitoring cards"* (continuation, more detail on the selection algorithm) — [Google Patents](https://patents.google.com/patent/US7137627B2/en)

The patented machine holds a rack of physical card-receiving **compartments** (13-19
of them, 17-19 "optimal" per the patent) and a dealing shoe with a small buffer.
`DeckLogic` mirrors this with `GameValues.shufflerCompartments` (17 compartments) and
the existing `GameValues.deck` acting as the shoe:

- **Loading a discarded card**: the microprocessor "randomly select[s] the compartment
  which will receive each card", but skips any compartment already at its maximum
  load, to keep compartments from being packed unevenly.
- **Refilling the shoe**: when the shoe's buffer runs low, the machine "randomly
  selects the compartment to be unloaded" and empties it **whole** into the shoe in
  one action — not one card at a time — while skipping compartments holding 7 or
  fewer cards "to maintain reasonable shuffling speed" (quoted directly from the
  patent). The patent's own example targets keeping about 20 cards buffered in the
  shoe at all times; `DeckLogic.shoeBufferTarget` uses that same figure.
- **Recurrence rate**: the patent notes that a naively random 4-deck CSM would let a
  card reappear in the very next hand about 13.5% of the time; Shuffle Master's
  constrained design (the load/unload skip rules above) brings that down to about
  4.3% — spreading discarded cards out more before they can come back into play. This
  app's compartment/threshold rules are the same shape of constraint, for the same
  reason.

The exact per-compartment maximum and buffer size aren't publicly specified for every
model (that level of detail is proprietary); this app uses `compartmentMaxCapacity =
30`, chosen to comfortably hold the largest shoe this app supports (7 decks, 364
cards) across 17 compartments with headroom for random imbalance, and the patent's own
"~20 cards" figure for the shoe buffer target.

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter / Dart (SDK `>=3.4.3`) |
| Charts | `fl_chart` |
| Persistence | `path_provider` (on-disk JSON history) |
| Logging | `logger` |
| UI | Material, custom responsive layout (`flutter_staggered_grid_view`) |
| Targets | Windows, Android, iOS, macOS, Linux, Web |

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

## Roadmap

Actively evolving. Next up:

- [ ] **Card-counting trainer mode** — running-count / true-count overlay and drills,
      building on the existing shuffler and stats infrastructure.
- [ ] **Deviation plays** — strategy-chart extensions beyond basic strategy for
      count-based deviations.
- [ ] **Cloud sync** for history and stats across devices.
- [ ] **Store releases** for Android and iOS.
- [ ] **Localization** (starting with French).
- [ ] **Expanded automated test coverage** across the game and shuffler logic.
- [ ] **CI pipeline** for build and test on every push.

## Getting started

Requires the Flutter SDK (Dart `>=3.4.3`).

```bash
flutter pub get
flutter run -d windows   # or: android, chrome, etc.
```
