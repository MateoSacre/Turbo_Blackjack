import 'package:flutter/material.dart';

import '../Settings/settings_global_values.dart';
import 'Data/History/history_manager.dart';

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
          final game = HistoryManager.history[index];
          return Card(
            color: SettingsGlobalValues.neutralColor,
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Game ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      'Dealer (${game.dealerHand.victoryStatus.name}): ${game.dealerHand.getCardsValues().join(', ')}'),
                  for (int i = 0; i < game.playerHands.length; i++)
                    Text(
                        'Hand ${i + 1} (${game.playerHands[i].victoryStatus.name}): ${game.playerHands[i].getCardsValues().join(', ')}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
