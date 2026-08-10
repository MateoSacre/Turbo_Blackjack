import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../Settings/settings_global_values.dart';
import 'Data/History/history_game.dart';
import 'Data/History/history_hand.dart';
import 'Data/History/history_manager.dart';
import 'Data/game_values.dart';
import 'Logic/game_logic.dart';

/// All stats for a selected period of games. Computed once per build from
/// [HistoryManager.history] so the page always reflects the latest data.
class _PeriodStats {
  final int totalGames;
  final int totalHands;

  final int win, blackjack, draw, bust, lost, surrender;
  final double winPct, blackjackPct, drawPct, bustPct, lostPct, surrenderPct;

  // Win = win + blackjack, Lost = lost + bust + surrender.
  final double playerWinPct, playerLostPct;

  final double netProfitTokens;
  final double avgProfitPerHandTokens;

  // Cumulative net profit (in tokens) after each hand played, in
  // chronological order. Used to draw the bankroll evolution curve.
  final List<FlSpot> cumulativeSpots;

  final int bestWinStreak;
  final int worstLossStreak;
  final int currentStreakLength;
  final String? currentStreakType; // 'W', 'L' or null (no active streak)

  // Win rate for hands containing a given card value (1=A .. 13=K). Null
  // when the card never appeared in the period.
  final Map<int, double?> winRateByCard;
  final int? bestCardValue;
  final int? worstCardValue;

  const _PeriodStats({
    required this.totalGames,
    required this.totalHands,
    required this.win,
    required this.blackjack,
    required this.draw,
    required this.bust,
    required this.lost,
    required this.surrender,
    required this.winPct,
    required this.blackjackPct,
    required this.drawPct,
    required this.bustPct,
    required this.lostPct,
    required this.surrenderPct,
    required this.playerWinPct,
    required this.playerLostPct,
    required this.netProfitTokens,
    required this.avgProfitPerHandTokens,
    required this.cumulativeSpots,
    required this.bestWinStreak,
    required this.worstLossStreak,
    required this.currentStreakLength,
    required this.currentStreakType,
    required this.winRateByCard,
    required this.bestCardValue,
    required this.worstCardValue,
  });
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String selectedOption = '10';
  int outcomeTouchedIndex = -1;
  final TextEditingController customController = TextEditingController();

  static const double _maxContentWidth = 640;

  @override
  void dispose() {
    customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final games = _getGames();
    final stats = _computeStats(games);

    return Scaffold(
      backgroundColor: SettingsGlobalValues.mainColor,
      appBar: AppBar(
        backgroundColor: SettingsGlobalValues.mainColor,
        iconTheme:
            const IconThemeData(color: SettingsGlobalValues.neutralColor),
        title: const Text('Stats',
            style: TextStyle(color: SettingsGlobalValues.neutralColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLiveStatusCard(context),
                const SizedBox(height: 16),
                _buildSelectorCard(context, stats),
                const SizedBox(height: 16),
                if (stats.totalHands == 0)
                  _buildEmptyState(context)
                else ...[
                  _buildHeadlineStats(context, stats),
                  const SizedBox(height: 16),
                  _buildOutcomeDonutSection(context, stats),
                  const SizedBox(height: 16),
                  _buildDetailedBreakdownSection(context, stats),
                  const SizedBox(height: 16),
                  _buildBankrollEvolutionSection(context, stats),
                  const SizedBox(height: 16),
                  _buildCardPerformanceSection(context, stats),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------

  List<HistoryGame> _getGames() {
    final history = HistoryManager.history;
    int count;
    if (selectedOption == 'All') {
      count = history.length;
    } else if (selectedOption == 'Custom') {
      count = int.tryParse(customController.text) ?? 0;
    } else {
      count = int.parse(selectedOption);
    }
    if (count > history.length) count = history.length;
    int start = history.length - count;
    if (start < 0) start = 0;
    return history.sublist(start);
  }

  String? _outcomeClass(VictoryStatus status) {
    switch (status) {
      case VictoryStatus.win:
      case VictoryStatus.blackJack:
        return 'W';
      case VictoryStatus.lost:
      case VictoryStatus.bust:
      case VictoryStatus.surrender:
        return 'L';
      case VictoryStatus.draw:
      case VictoryStatus.empty:
        return null;
    }
  }

  /// Net profit of a single hand, in half-token units (same unit as
  /// [GameValues.tokens]). Mirrors the payout multipliers used by
  /// `GameLogic.settleBets` exactly, minus the original stake, so this stays
  /// correct if the payout rules ever change there.
  int _handProfitHalfUnits(HistoryHand hand, bool dealerHasBlackjack) {
    int profit;
    switch (hand.victoryStatus) {
      case VictoryStatus.blackJack:
        profit = hand.bet * 3; // payout 5x stake, stake 2x -> +3x
        break;
      case VictoryStatus.win:
        profit = hand.bet * 2; // payout 4x stake, stake 2x -> +2x
        break;
      case VictoryStatus.draw:
        profit = 0;
        break;
      case VictoryStatus.surrender:
        profit = -hand.bet; // payout 1x stake, stake 2x -> -1x
        break;
      case VictoryStatus.bust:
      case VictoryStatus.lost:
      case VictoryStatus.empty:
        profit = -hand.bet * 2;
        break;
    }
    if (hand.insuranceBet > 0) {
      if (dealerHasBlackjack) {
        profit += hand.insuranceBet * 2; // 2:1 payout on the insurance stake
      } else {
        profit -= hand.insuranceBet;
      }
    }
    return profit;
  }

  _PeriodStats _computeStats(List<HistoryGame> games) {
    int win = 0, blackjack = 0, draw = 0, bust = 0, lost = 0, surrender = 0;
    int totalHands = 0;
    int netProfitHalf = 0;

    final cumulativeSpots = <FlSpot>[const FlSpot(0, 0)];

    String? runType;
    int runLength = 0;
    int bestWinStreak = 0;
    int worstLossStreak = 0;

    final playerCardCount = {for (var i = 1; i <= 13; i++) i: 0};
    final playerCardWinCount = {for (var i = 1; i <= 13; i++) i: 0};

    for (final game in games) {
      final dealerHasBlackjack =
          game.dealerHand.victoryStatus == VictoryStatus.blackJack;
      for (final hand in game.playerHands) {
        totalHands++;

        for (final card in hand.cards) {
          playerCardCount[card.value] = playerCardCount[card.value]! + 1;
        }

        final isWin = hand.victoryStatus == VictoryStatus.win ||
            hand.victoryStatus == VictoryStatus.blackJack;
        if (isWin) {
          for (final card in hand.cards) {
            playerCardWinCount[card.value] =
                playerCardWinCount[card.value]! + 1;
          }
        }

        switch (hand.victoryStatus) {
          case VictoryStatus.win:
            win++;
            break;
          case VictoryStatus.blackJack:
            blackjack++;
            break;
          case VictoryStatus.draw:
            draw++;
            break;
          case VictoryStatus.bust:
            bust++;
            break;
          case VictoryStatus.lost:
            lost++;
            break;
          case VictoryStatus.surrender:
            surrender++;
            break;
          case VictoryStatus.empty:
            break;
        }

        netProfitHalf += _handProfitHalfUnits(hand, dealerHasBlackjack);
        cumulativeSpots
            .add(FlSpot(totalHands.toDouble(), netProfitHalf / 2));

        final outcomeClass = _outcomeClass(hand.victoryStatus);
        if (outcomeClass == null) {
          runType = null;
          runLength = 0;
        } else if (outcomeClass == runType) {
          runLength++;
        } else {
          runType = outcomeClass;
          runLength = 1;
        }
        if (runType == 'W') bestWinStreak = max(bestWinStreak, runLength);
        if (runType == 'L') worstLossStreak = max(worstLossStreak, runLength);
      }
    }

    double toPct(int value) => totalHands == 0 ? 0 : (value / totalHands * 100);

    final winRateByCard = <int, double?>{};
    int? bestCardValue;
    int? worstCardValue;
    double bestRate = -1;
    double worstRate = 101;
    for (var v = 1; v <= 13; v++) {
      final appearances = playerCardCount[v]!;
      if (appearances == 0) {
        winRateByCard[v] = null;
        continue;
      }
      final rate = playerCardWinCount[v]! / appearances * 100;
      winRateByCard[v] = rate;
      if (rate > bestRate) {
        bestRate = rate;
        bestCardValue = v;
      }
      if (rate < worstRate) {
        worstRate = rate;
        worstCardValue = v;
      }
    }

    return _PeriodStats(
      totalGames: games.length,
      totalHands: totalHands,
      win: win,
      blackjack: blackjack,
      draw: draw,
      bust: bust,
      lost: lost,
      surrender: surrender,
      winPct: toPct(win),
      blackjackPct: toPct(blackjack),
      drawPct: toPct(draw),
      bustPct: toPct(bust),
      lostPct: toPct(lost),
      surrenderPct: toPct(surrender),
      playerWinPct: toPct(win + blackjack),
      playerLostPct: toPct(surrender + lost + bust),
      netProfitTokens: netProfitHalf / 2,
      avgProfitPerHandTokens:
          totalHands == 0 ? 0 : (netProfitHalf / 2) / totalHands,
      cumulativeSpots: cumulativeSpots,
      bestWinStreak: bestWinStreak,
      worstLossStreak: worstLossStreak,
      currentStreakLength: runType == null ? 0 : runLength,
      currentStreakType: runType,
      winRateByCard: winRateByCard,
      bestCardValue: bestCardValue,
      worstCardValue: worstCardValue,
    );
  }

  String _cardLabel(int v) => switch (v) {
        1 => 'A',
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        _ => v.toString(),
      };

  String _formatTokens(num halfUnits) {
    final double tokens = halfUnits / 2;
    return tokens == tokens.roundToDouble()
        ? tokens.toStringAsFixed(0)
        : tokens.toStringAsFixed(1);
  }

  String _formatSignedTokens(double tokens) {
    final sign = tokens > 0 ? '+' : (tokens < 0 ? '-' : '');
    final abs = tokens.abs();
    final formatted = abs == abs.roundToDouble()
        ? abs.toStringAsFixed(0)
        : abs.toStringAsFixed(1);
    return '$sign$formatted';
  }

  // ---------------------------------------------------------------------
  // Shared building blocks
  // ---------------------------------------------------------------------

  Widget _sectionCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SettingsGlobalValues.secondColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: SettingsGlobalValues.neutralColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(
                color: SettingsGlobalValues.neutralColor.withValues(alpha: .6),
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------

  Widget _buildLiveStatusCard(BuildContext context) {
    return _sectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current tokens',
                  style: TextStyle(
                      color:
                          SettingsGlobalValues.neutralColor.withValues(alpha: .7),
                      fontSize: 12),
                ),
                Text(
                  _formatTokens(GameValues.tokens),
                  style: const TextStyle(
                      color: SettingsGlobalValues.neutralColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Bankruptcies',
                style: TextStyle(
                    color:
                        SettingsGlobalValues.neutralColor.withValues(alpha: .7),
                    fontSize: 12),
              ),
              Text(
                '${GameValues.bankruptcyCount}',
                style: const TextStyle(
                    color: SettingsGlobalValues.neutralColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorCard(BuildContext context, _PeriodStats stats) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Period:',
                style: TextStyle(color: SettingsGlobalValues.neutralColor),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedOption,
                dropdownColor: SettingsGlobalValues.secondColor,
                items: const [
                  DropdownMenuItem(value: '10', child: Text('Last 10 games')),
                  DropdownMenuItem(value: '50', child: Text('Last 50 games')),
                  DropdownMenuItem(
                      value: '100', child: Text('Last 100 games')),
                  DropdownMenuItem(
                      value: '500', child: Text('Last 500 games')),
                  DropdownMenuItem(value: 'All', child: Text('All games')),
                  DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                ].map((item) {
                  return DropdownMenuItem<String>(
                    value: item.value,
                    child: DefaultTextStyle(
                      style: const TextStyle(
                          color: SettingsGlobalValues.neutralColor),
                      child: item.child,
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  selectedOption = value ?? '10';
                }),
              ),
              if (selectedOption == 'Custom') const SizedBox(width: 10),
              if (selectedOption == 'Custom')
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    style:
                        const TextStyle(color: SettingsGlobalValues.neutralColor),
                    decoration: const InputDecoration(
                      hintText: '# games',
                      hintStyle:
                          TextStyle(color: SettingsGlobalValues.neutralColor),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stats.totalHands == 0
                ? 'No hands played in this period yet.'
                : '${stats.totalHands} hand${stats.totalHands == 1 ? '' : 's'} '
                    'across ${stats.totalGames} game${stats.totalGames == 1 ? '' : 's'} '
                    '(a game can contain several hands after a split).',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor.withValues(alpha: .6),
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return _sectionCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.bar_chart,
              color: SettingsGlobalValues.neutralColor.withValues(alpha: .4),
              size: 48),
          const SizedBox(height: 12),
          Text(
            'No data for this period yet',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor.withValues(alpha: .8),
                fontSize: 16,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Play a few hands, then come back to see your stats.',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor.withValues(alpha: .6),
                fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeadlineStats(BuildContext context, _PeriodStats stats) {
    final profitColor = stats.netProfitTokens > 0
        ? SettingsGlobalValues.positiveColor
        : (stats.netProfitTokens < 0
            ? SettingsGlobalValues.negativeColor
            : SettingsGlobalValues.neutralColor);
    final streakColor = stats.currentStreakType == 'W'
        ? SettingsGlobalValues.positiveColor
        : (stats.currentStreakType == 'L'
            ? SettingsGlobalValues.negativeColor
            : SettingsGlobalValues.neutralColor);
    final streakText = stats.currentStreakType == null
        ? '—'
        : '${stats.currentStreakLength}${stats.currentStreakType}';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _statTile('Win Rate', '${stats.playerWinPct.toStringAsFixed(1)}%',
            SettingsGlobalValues.positiveColor),
        _statTile('Net Profit', _formatSignedTokens(stats.netProfitTokens),
            profitColor),
        _statTile('Hands Played', '${stats.totalHands}',
            SettingsGlobalValues.neutralColor),
        _statTile('Current Streak', streakText, streakColor),
      ],
    );
  }

  Widget _statTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SettingsGlobalValues.secondColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor.withValues(alpha: .7),
                fontSize: 12),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeDonutSection(BuildContext context, _PeriodStats stats) {
    final legendData = [
      ('Win', stats.playerWinPct, SettingsGlobalValues.positiveColor),
      ('Draw', stats.drawPct, SettingsGlobalValues.activeColor),
      ('Lost', stats.playerLostPct, SettingsGlobalValues.negativeColor),
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Outcome overview'),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = min(constraints.maxWidth, 260.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      response == null ||
                                      response.touchedSection == null) {
                                    outcomeTouchedIndex = -1;
                                    return;
                                  }
                                  outcomeTouchedIndex = response
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            sections: List.generate(3, (i) {
                              final (label, value, color) = legendData[i];
                              final touched = i == outcomeTouchedIndex;
                              return PieChartSectionData(
                                color: color,
                                value: value <= 0 ? 0.0001 : value,
                                title: touched
                                    ? '$label\n${value.toStringAsFixed(1)}%'
                                    : '',
                                titleStyle: const TextStyle(
                                    color: SettingsGlobalValues.neutralColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                                radius: touched ? size / 4.5 : size / 5,
                              );
                            }),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: size / 4,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${stats.playerWinPct.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  color: SettingsGlobalValues.positiveColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'win rate',
                              style: TextStyle(
                                  color: SettingsGlobalValues.neutralColor
                                      .withValues(alpha: .6),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ...legendData.map((entry) {
            final (label, value, color) = entry;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                          color: SettingsGlobalValues.neutralColor),
                    ),
                  ),
                  Text(
                    '${value.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: SettingsGlobalValues.neutralColor,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailedBreakdownSection(
      BuildContext context, _PeriodStats stats) {
    final rows = [
      ('BlackJack', stats.blackjackPct, SettingsGlobalValues.goldColor),
      ('Win', stats.winPct, SettingsGlobalValues.positiveColor),
      ('Draw', stats.drawPct, SettingsGlobalValues.activeColor),
      (
        'Bust',
        stats.bustPct,
        SettingsGlobalValues.negativeColor.withValues(alpha: .5)
      ),
      ('Lost', stats.lostPct, SettingsGlobalValues.negativeColor),
      ('Surrender', stats.surrenderPct, SettingsGlobalValues.orangeColor),
    ];
    final maxPct = rows.fold<double>(
        0, (acc, r) => r.$2 > acc ? r.$2 : acc);

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Detailed outcomes',
              subtitle: 'Share of all hands played in this period'),
          ...rows.map((row) {
            final (label, value, color) = row;
            final fraction = maxPct <= 0 ? 0.0 : (value / maxPct);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      label,
                      style: const TextStyle(
                          color: SettingsGlobalValues.neutralColor,
                          fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: SettingsGlobalValues.mainColor,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            Container(
                              width: constraints.maxWidth * fraction,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${value.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: SettingsGlobalValues.neutralColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBankrollEvolutionSection(
      BuildContext context, _PeriodStats stats) {
    final spots = stats.cumulativeSpots;
    final ys = spots.map((s) => s.y);
    final minY = ys.reduce(min);
    final maxY = ys.reduce(max);
    final padding = max((maxY - minY) * 0.15, 1.0);
    final lineColor = stats.netProfitTokens >= 0
        ? SettingsGlobalValues.positiveColor
        : SettingsGlobalValues.negativeColor;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Bankroll evolution',
              subtitle: 'Cumulative net profit (tokens) over this period'),
          SizedBox(
            height: 200,
            child: spots.length < 2
                ? Center(
                    child: Text(
                      'Not enough hands yet to draw a curve.',
                      style: TextStyle(
                          color: SettingsGlobalValues.neutralColor
                              .withValues(alpha: .6)),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: minY - padding,
                      maxY: maxY + padding,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color:
                              SettingsGlobalValues.neutralColor.withValues(alpha: .1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(
                                  color: SettingsGlobalValues.neutralColor
                                      .withValues(alpha: .6),
                                  fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => SettingsGlobalValues.mainColor,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((s) {
                              return LineTooltipItem(
                                _formatSignedTokens(s.y),
                                const TextStyle(
                                    color: SettingsGlobalValues.neutralColor,
                                    fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: false,
                          color: lineColor,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withValues(alpha: .15),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPerformanceSection(BuildContext context, _PeriodStats stats) {
    final hasData = stats.bestCardValue != null;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Performance by card value',
              subtitle:
                  'Win rate of hands containing each card value (Ace to King)'),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: 100,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: SettingsGlobalValues.neutralColor.withValues(alpha: .1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _cardLabel(value.toInt()),
                          style: TextStyle(
                              color: SettingsGlobalValues.neutralColor
                                  .withValues(alpha: .7),
                              fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => SettingsGlobalValues.mainColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final v = group.x;
                      final rate = stats.winRateByCard[v];
                      return BarTooltipItem(
                        '${_cardLabel(v)}: ${rate == null ? 'n/a' : '${rate.toStringAsFixed(1)}%'}',
                        const TextStyle(
                            color: SettingsGlobalValues.neutralColor,
                            fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                barGroups: List.generate(13, (i) {
                  final v = i + 1;
                  final rate = stats.winRateByCard[v];
                  Color color = SettingsGlobalValues.activeColor;
                  if (v == stats.bestCardValue) {
                    color = SettingsGlobalValues.positiveColor;
                  } else if (v == stats.worstCardValue) {
                    color = SettingsGlobalValues.negativeColor;
                  } else if (rate == null) {
                    color = SettingsGlobalValues.neutralColor.withValues(alpha: .15);
                  }
                  return BarChartGroupData(
                    x: v,
                    barRods: [
                      BarChartRodData(
                        toY: rate ?? 0,
                        color: color,
                        width: 12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? 'Best: ${_cardLabel(stats.bestCardValue!)} '
                    '(${stats.winRateByCard[stats.bestCardValue]!.toStringAsFixed(1)}%) '
                    '· Worst: ${_cardLabel(stats.worstCardValue!)} '
                    '(${stats.winRateByCard[stats.worstCardValue]!.toStringAsFixed(1)}%)'
                : 'Not enough data yet.',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor.withValues(alpha: .6),
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}
