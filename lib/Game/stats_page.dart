import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../Settings/settings_global_values.dart';
import 'Data/History/history_game.dart';
import 'Data/History/history_manager.dart';
import 'Logic/game_logic.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String selectedOption = '10';
  final TextEditingController customController = TextEditingController();

  @override
  void dispose() {
    customController.dispose();
    super.dispose();
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
    };
  }

  List<PieChartSectionData> _buildChartSections(
      BuildContext context, Map<String, dynamic> stats) {
    const textStyle =
        TextStyle(color: SettingsGlobalValues.neutralColor, fontSize: 12);
    final double radius =
        (MediaQuery.of(context).size.width >= MediaQuery.of(context).size.height
            ? MediaQuery.of(context).size.height
            : MediaQuery.of(context).size.width) / SettingsGlobalValues.statChartRadius ;
    SettingsGlobalValues.logger.i("Chart size = $radius");
    return [
      PieChartSectionData(
        color: SettingsGlobalValues.positiveColor,
        value: stats['win'],
        title: '${stats['win'].toStringAsFixed(1)}%',
        titleStyle: textStyle,
        radius: radius,
      ),
      PieChartSectionData(
        color: SettingsGlobalValues.goldColor,
        value: stats['blackjack'],
        title: '${stats['blackjack'].toStringAsFixed(1)}%',
        titleStyle: textStyle,
        radius: radius,
      ),
      PieChartSectionData(
        color: SettingsGlobalValues.activeColor,
        value: stats['draw'],
        title: '${stats['draw'].toStringAsFixed(1)}%',
        titleStyle: textStyle,
        radius: radius,
      ),
      PieChartSectionData(
        color: SettingsGlobalValues.negativeColor.withValues(alpha: .5),
        value: stats['bust'],
        title: '${stats['bust'].toStringAsFixed(1)}%',
        titleStyle: textStyle,
        radius: radius,
      ),
      PieChartSectionData(
        color: SettingsGlobalValues.negativeColor,
        value: stats['lost'],
        title: '${stats['lost'].toStringAsFixed(1)}%',
        titleStyle: textStyle,
        radius: radius,
      ),
      PieChartSectionData(
        color: SettingsGlobalValues.orangeColor,
        value: stats['surrender'],
        title: '${stats['surrender'].toStringAsFixed(1)}%',
        titleStyle: textStyle,
        radius: radius,
      ),
    ];
  }

  Widget _buildResponsiveChart(
      BuildContext context, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        SettingsGlobalValues.logger.i("Chart size = $size");

        return SizedBox(
          width: size,
          height: size,
          child: PieChart(
            PieChartData(
              sections: _buildChartSections(context, stats),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 0,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = _getGames();
    final stats = _calculateStats(games);

    final selector = Row(
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
        const SizedBox(width: 10),
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

    final chart = _buildResponsiveChart(context, stats);

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Player win: ${stats['playerWin'].toStringAsFixed(1)}%',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        Text('    Win: ${stats['win'].toStringAsFixed(1)}%',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        Text('    Blackjack: ${stats['blackjack'].toStringAsFixed(1)}%',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        Text('    Bust: ${stats['bust'].toStringAsFixed(1)}%',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        Text('    Lost: ${stats['lost'].toStringAsFixed(1)}%',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        Text('    Surrender: ${stats['surrender'].toStringAsFixed(1)}%',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        const SizedBox(height: 20),
        Text('Dealer win: ${stats['playerLost'].toStringAsFixed(1)}%',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        const SizedBox(height: 20),
        Text('Draw: ${stats['draw'].toStringAsFixed(1)}%',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        const SizedBox(height: 20),
        Text('Most winning card: ${stats['mostWinCard']}',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        Text('Least winning card: ${stats['leastWinCard']}',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        const SizedBox(height: 20),
        Text('Most frequent card: ${stats['mostCard']}',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
        Text('Least frequent card: ${stats['leastCard']}',
            style: const TextStyle(color: SettingsGlobalValues.neutralColor)),
      ],
    );

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              selector,
              const SizedBox(height: 20),
              chart,
              const SizedBox(height: 20),
              details,
            ],
          ),
        ),
      ),
    );
  }
}
