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

  Widget _buildPosition() {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: SettingsGlobalValues.secondColor,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsGlobalValues.mainColor,
      appBar: AppBar(
        backgroundColor: SettingsGlobalValues.mainColor,
        iconTheme: const IconThemeData(color: SettingsGlobalValues.neutralColor),
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
                final center = Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.65);
                final radius = min(constraints.maxWidth, constraints.maxHeight) * 0.35;
                List<Widget> stackChildren = [];

                // Dealer position
                stackChildren.add(Positioned(
                  left: center.dx - 30,
                  top: center.dy - radius - 50,
                  child: _buildPosition(),
                ));

                // Player positions
                const startAngle = 7 * pi / 6; // 210 degrees
                const endAngle = 11 * pi / 6; // 330 degrees
                const step = (endAngle - startAngle) / 6;
                for (int i = 0; i < 7; i++) {
                  final angle = startAngle + step * i;
                  final offset = Offset.fromDirection(angle, radius);
                  stackChildren.add(Positioned(
                    left: center.dx + offset.dx - 30,
                    top: center.dy + offset.dy - 40,
                    child: _buildPosition(),
                  ));
                }

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
