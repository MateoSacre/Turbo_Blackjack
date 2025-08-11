import 'package:flutter/material.dart';

import '../Settings/settings_global_values.dart';
import 'Data/History/history_manager.dart';
import 'Logic/game_logic.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsGlobalValues.mainColor,
      appBar: AppBar(
        backgroundColor: SettingsGlobalValues.mainColor,
        iconTheme:
            const IconThemeData(color: SettingsGlobalValues.neutralColor),
        title: const Text(
          'History',
          style: TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
      ),
      body: ListView.builder(
        itemCount: HistoryManager.history.length,
        itemBuilder: (context, index) {
          int reverseIndex = HistoryManager.history.length - index;
          final game = HistoryManager.history[reverseIndex - 1];
          final String dealerValue =
              game.dealerHand.victoryStatus.name == VictoryStatus.empty.name
                  ? ""
                  : "(${game.dealerHand.victoryStatus.name.toString()})";
          return Card(
            color: SettingsGlobalValues.neutralColor,
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Game $reverseIndex',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      'Dealer $dealerValue: ${game.dealerHand.getValue()} - ${game.dealerHand.getCardsValues().join(', ')}'),
                  for (int i = 0; i < game.playerHands.length; i++)
                    Text(
                        'Hand ${i + 1} (${game.playerHands[i].victoryStatus.name}): ${game.playerHands[i].getValue()} - ${game.playerHands[i].getCardsValues().join(', ')}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
