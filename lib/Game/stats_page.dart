import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../Settings/settings_global_values.dart';
import 'Data/History/history_game.dart';
import 'Data/History/history_manager.dart';
import 'Data/game_values.dart';
import 'Logic/game_logic.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String selectedOption = '10';
  int fullStatChartTouchedIndex = -1;
  int summaryChartTouchedIndex = -1;
  final TextEditingController customController = TextEditingController();

  @override
  void dispose() {
    customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final games = _getGames();
    final stats = _calculateStats(games);

    final bankrollSummary = _buildBankrollSummary(context);
    final selector = _buildSelector();
    final statSummaryChart = _buildSummaryChart(context, stats);
    final fullStatChart = _buildResponsiveChart(context, stats);

    return Scaffold(
      backgroundColor: SettingsGlobalValues.mainColor,
      appBar: AppBar(
        backgroundColor: SettingsGlobalValues.mainColor,
        iconTheme:
            const IconThemeData(color: SettingsGlobalValues.neutralColor),
        title: const Text('Stats',
            style: TextStyle(color: SettingsGlobalValues.neutralColor)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Center(
            // <-- Centre tout le Wrap dans l'espace dispo
            child: Wrap(
              alignment: WrapAlignment.center,
              // Centre les enfants dans la ligne
              runAlignment: WrapAlignment.center,
              // Centre les lignes elles-mêmes
              crossAxisAlignment: WrapCrossAlignment.center,
              // Aligne sur l'axe secondaire
              direction: SettingsGlobalValues.isLandscape(context)
                  ? Axis.horizontal
                  : Axis.vertical,
              spacing: SettingsGlobalValues.statChartSpacing,
              runSpacing: SettingsGlobalValues.statChartSpacing,
              children: [
                bankrollSummary,
                selector,
                statSummaryChart,
                fullStatChart,
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  Map<String, dynamic> _calculateStats(List<HistoryGame> games) {
    int win = 0, blackjack = 0, draw = 0, bust = 0, lost = 0, surrender = 0;
    int totalHands = 0;
    Map<int, int> cardWinCount = {for (var i = 1; i <= 13; i++) i: 0};
    Map<int, int> cardCount = {for (var i = 1; i <= 13; i++) i: 0};

    for (final game in games) {
      for (final card in game.dealerHand.cards) {
        cardCount[card.value] = cardCount[card.value]! + 1;
      }
      for (final hand in game.playerHands) {
        totalHands++;
        for (final card in hand.cards) {
          cardCount[card.value] = cardCount[card.value]! + 1;
        }
        switch (hand.victoryStatus) {
          case VictoryStatus.win:
          case VictoryStatus.blackJack:
            if (hand.victoryStatus == VictoryStatus.win) win++;
            if (hand.victoryStatus == VictoryStatus.blackJack) blackjack++;
            for (final card in hand.cards) {
              cardWinCount[card.value] = cardWinCount[card.value]! + 1;
            }
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
      }
    }

    double toPct(int value) => totalHands == 0 ? 0 : (value / totalHands * 100);

    String valueToString(int v) => switch (v) {
          1 => 'A',
          11 => 'J',
          12 => 'Q',
          13 => 'K',
          _ => v.toString()
        };

    String mostWinCard = 'N/A';
    String leastWinCard = 'N/A';
    if (cardWinCount.values.any((v) => v > 0)) {
      final maxEntry =
          cardWinCount.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final minEntry =
          cardWinCount.entries.reduce((a, b) => a.value <= b.value ? a : b);
      mostWinCard = valueToString(maxEntry.key);
      leastWinCard = valueToString(minEntry.key);
    }

    String mostCard = 'N/A';
    String leastCard = 'N/A';
    if (cardCount.values.any((v) => v > 0)) {
      final maxEntry =
          cardCount.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final minEntry =
          cardCount.entries.reduce((a, b) => a.value <= b.value ? a : b);
      mostCard = valueToString(maxEntry.key);
      leastCard = valueToString(minEntry.key);
    }

    return {
      'win': toPct(win),
      'blackjack': toPct(blackjack),
      'draw': toPct(draw),
      'bust': toPct(bust),
      'lost': toPct(lost),
      'surrender': toPct(surrender),
      'playerWin': toPct(win + blackjack),
      'playerLost': toPct(surrender + lost + bust),
      'mostWinCard': mostWinCard,
      'leastWinCard': leastWinCard,
      'mostCard': mostCard,
      'leastCard': leastCard,
      'cardWinCount': cardWinCount,
      'cardCount': cardCount,
    };
  }

  List<PieChartSectionData> _buildFullStatsChartSections(
      double size, Map<String, dynamic> stats) {
    return List.generate(5, (i) {
      final isFullStatChartQuarterTouched = i == fullStatChartTouchedIndex;
      final textStyle = TextStyle(
          color: SettingsGlobalValues.neutralColor,
          fontSize: (isFullStatChartQuarterTouched ? 20.0 : 12.0),
          backgroundColor: isFullStatChartQuarterTouched ? Colors.black : null);
      final radius = size * (isFullStatChartQuarterTouched ? 1.1 : 1);
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: SettingsGlobalValues.goldColor,
            value: stats['blackjack'],
            title:
                '${isFullStatChartQuarterTouched ? 'BlackJack :\n' : ''}${stats['blackjack'].toStringAsFixed(1)}%',
            titleStyle: textStyle,
            radius: radius,
          );
        case 1:
          return PieChartSectionData(
            color: SettingsGlobalValues.positiveColor,
            value: stats['win'],
            title:
                '${isFullStatChartQuarterTouched ? 'Win :\n' : ''}${stats['win'].toStringAsFixed(1)}%',
            titleStyle: textStyle,
            radius: radius,
          );
        case 2:
          return PieChartSectionData(
            color: SettingsGlobalValues.activeColor,
            value: stats['draw'],
            title:
                '${isFullStatChartQuarterTouched ? 'Draw :\n' : ''}${stats['draw'].toStringAsFixed(1)}%',
            titleStyle: textStyle,
            radius: radius,
          );
        case 3:
          return PieChartSectionData(
            color: SettingsGlobalValues.negativeColor.withValues(alpha: .5),
            value: stats['bust'],
            title:
                '${isFullStatChartQuarterTouched ? 'Bust :\n' : ''}${stats['bust'].toStringAsFixed(1)}%',
            titleStyle: textStyle,
            radius: radius,
          );
        case 4:
          return PieChartSectionData(
            color: SettingsGlobalValues.negativeColor,
            value: stats['lost'],
            title:
                '${isFullStatChartQuarterTouched ? 'Lost :\n' : ''}${stats['lost'].toStringAsFixed(1)}%',
            titleStyle: textStyle,
            radius: radius,
          );
        case 5:
          return PieChartSectionData(
            color: SettingsGlobalValues.orangeColor,
            value: stats['surrender'],
            title:
                '${isFullStatChartQuarterTouched ? 'Surrender :\n' : ''}${stats['surrender'].toStringAsFixed(1)}%',
            titleStyle: textStyle,
            radius: radius,
          );
        default:
          throw Error();
      }
    });
  }

  List<PieChartSectionData> _buildSummaryChartSections(
      double size, Map<String, dynamic> stats) {
    return List.generate(3, (i) {
      final isSummaryChartTouched = i == summaryChartTouchedIndex;
      final textStyle = TextStyle(
          color: SettingsGlobalValues.neutralColor,
          fontSize: (isSummaryChartTouched ? 20.0 : 12.0),
          backgroundColor: isSummaryChartTouched ? Colors.black : null);
      final radius = size * (isSummaryChartTouched ? 1.1 : 1);
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: SettingsGlobalValues.positiveColor,
            value: stats['playerWin'],
            title:
                '${isSummaryChartTouched ? 'Win :\n' : ''}${stats['win'].toStringAsFixed(1)}%',
            titleStyle: textStyle,
            radius: radius,
          );
        case 1:
          return PieChartSectionData(
            color: SettingsGlobalValues.negativeColor,
            value: stats['playerLost'],
            title:
                '${isSummaryChartTouched ? 'Draw :\n' : ''}${stats['draw'].toStringAsFixed(1)}%',
            titleStyle: textStyle,
            radius: radius,
          );
        case 2:
          return PieChartSectionData(
            color: SettingsGlobalValues.activeColor,
            value: stats['draw'],
            title:
                '${isSummaryChartTouched ? 'Lost :\n' : ''}${stats['lost'].toStringAsFixed(1)}%',
            titleStyle: textStyle,
            radius: radius,
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildResponsiveChart(
      BuildContext context, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (MediaQuery.of(context).size.width >=
                    MediaQuery.of(context).size.height
                ? MediaQuery.of(context).size.height
                : MediaQuery.of(context).size.width) /
            SettingsGlobalValues.statChartRadius;
        return SizedBox(
          width: size,
          height: size,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      fullStatChartTouchedIndex = -1;
                      return;
                    }
                    fullStatChartTouchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: _buildFullStatsChartSections(size / 2, stats),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 0,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryChart(BuildContext context, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (MediaQuery.of(context).size.width >=
                    MediaQuery.of(context).size.height
                ? MediaQuery.of(context).size.height
                : MediaQuery.of(context).size.width) /
            SettingsGlobalValues.statChartRadius;
        return SizedBox(
          width: size,
          height: size,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      summaryChartTouchedIndex = -1;
                      return;
                    }
                    summaryChartTouchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: _buildSummaryChartSections(size / 2, stats),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 0,
            ),
          ),
        );
      },
    );
  }

  String _formatTokens(num halfUnits) {
    final double tokens = halfUnits / 2;
    return tokens == tokens.roundToDouble()
        ? tokens.toStringAsFixed(0)
        : tokens.toStringAsFixed(1);
  }

  Widget _buildBankrollSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SettingsGlobalValues.secondColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current tokens: ${_formatTokens(GameValues.tokens)}',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
          Text(
            'Bankruptcies: ${GameValues.bankruptcyCount}',
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ],
      ),
    );
  }

  _buildSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Games:',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: selectedOption,
          dropdownColor: SettingsGlobalValues.secondColor,
          items: const [
            DropdownMenuItem(
              value: '10',
              child: Text('10',
                  style: TextStyle(color: SettingsGlobalValues.neutralColor)),
            ),
            DropdownMenuItem(
              value: '50',
              child: Text('50',
                  style: TextStyle(color: SettingsGlobalValues.neutralColor)),
            ),
            DropdownMenuItem(
              value: '100',
              child: Text('100',
                  style: TextStyle(color: SettingsGlobalValues.neutralColor)),
            ),
            DropdownMenuItem(
              value: '500',
              child: Text('500',
                  style: TextStyle(color: SettingsGlobalValues.neutralColor)),
            ),
            DropdownMenuItem(
              value: 'All',
              child: Text('All',
                  style: TextStyle(color: SettingsGlobalValues.neutralColor)),
            ),
            DropdownMenuItem(
              value: 'Custom',
              child: Text('Custom',
                  style: TextStyle(color: SettingsGlobalValues.neutralColor)),
            ),
          ],
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
              style: const TextStyle(color: SettingsGlobalValues.neutralColor),
              decoration: const InputDecoration(
                hintText: '10',
                hintStyle: TextStyle(color: SettingsGlobalValues.neutralColor),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
      ],
    );
  }
}
