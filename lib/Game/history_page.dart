import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
        iconTheme: const IconThemeData(color: SettingsGlobalValues.neutralColor),
        title: Text(
          'History',
          style: TextStyle(
            color: SettingsGlobalValues.neutralColor,
            fontSize: SettingsGlobalValues.getFontSize(context),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: MasonryGridView.count(
          crossAxisCount: SettingsGlobalValues.isLandscape(context) ? 3 : 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: HistoryManager.history.length,
          itemBuilder: (context, index) {
            int reverseIndex = HistoryManager.history.length - index;
            final game = HistoryManager.history[reverseIndex - 1];
            final String dealerValue =
            game.dealerHand.victoryStatus.name == VictoryStatus.empty.name
                ? ""
                : "(${game.dealerHand.victoryStatus.name})";

            return Card(
              color: SettingsGlobalValues.neutralColor,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game $reverseIndex',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: SettingsGlobalValues.getFontSize(context),
                      ),
                    ),
                    Text(
                      'Dealer $dealerValue: ${game.dealerHand.getValue()} - ${game.dealerHand.getCardsValues().join(', ')}',
                      style: TextStyle(
                        fontSize: SettingsGlobalValues.getFontSize(context),
                      ),
                    ),
                    for (int i = 0; i < game.playerHands.length; i++)
                      Text(
                        'Hand ${i + 1} (${game.playerHands[i].victoryStatus.name}): ${game.playerHands[i].getValue()} - ${game.playerHands[i].getCardsValues().join(', ')}',
                        style: TextStyle(
                          fontSize: SettingsGlobalValues.getFontSize(context),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}
