import 'dart:math';

import 'package:flutter/material.dart';
import 'package:turbo_blackjack/Game/Logic/deck_logic.dart';
import 'package:turbo_blackjack/Settings/settings_global_values.dart';

class PlayTable extends StatefulWidget {
  const PlayTable({super.key});

  @override
  PlayTableState createState() => PlayTableState();
}

class PlayTableState extends State<PlayTable> {
  PlayTableState() {
    Decklogic.resetDeck();
  }

  Widget _buildPosition(String text) {
    return Container(
      width: SettingsGlobalValues.playerCardWidth,
      height: SettingsGlobalValues.playerCardHeight,
      decoration: BoxDecoration(
        color: SettingsGlobalValues.neutralColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsGlobalValues.mainColor,
      appBar: AppBar(
        backgroundColor: SettingsGlobalValues.mainColor,
        iconTheme:
            const IconThemeData(color: SettingsGlobalValues.neutralColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/homePage'),
        ),
        title: const Text('Turbo Blackjack'),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final center = Offset(
                    constraints.maxWidth / 2, constraints.maxHeight * .35);
                final radius =
                    min(constraints.maxWidth, constraints.maxHeight) * 0.40;
                List<Widget> stackChildren = [];
                // Player positions
                int test = 5;
                double offset = 0;
                double startAngle = pi + offset;
                double endAngle = startAngle + (pi - 2 * offset);
                double step = (endAngle - startAngle) / (test + 1);
                for (int i = 0; i < test; i++) {
                  final angle = startAngle + step * (i + 1);
                  final offsetForCard = Offset.fromDirection(angle, radius);
                  stackChildren.add(Positioned(
                    left: center.dx -
                        offsetForCard.dx -
                        SettingsGlobalValues.playerCardWidth / 2,
                    top: center.dy -
                        offsetForCard.dy -
                        SettingsGlobalValues.playerCardHeight / 2,
                    child: _buildPosition(""),
                  ));
                }

                // Dealer position
                stackChildren.add(Positioned(
                  left: center.dx - SettingsGlobalValues.playerCardWidth / 2,
                  top: center.dy * .5 -
                      SettingsGlobalValues.playerCardHeight / 2,
                  child: _buildPosition("D"),
                ));

                return Stack(children: stackChildren);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: SettingsGlobalValues.positiveColor,
              ),
              child: const Text(
                'Lancer la partie',
                style: TextStyle(color: SettingsGlobalValues.neutralColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
