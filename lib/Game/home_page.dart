import 'package:flutter/material.dart';
import 'package:turbo_blackjack/Game/Data/game_values.dart';
import 'package:turbo_blackjack/Game/Logic/game_logic.dart';

import '../Settings/settings_global_values.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsGlobalValues.mainColor,
      appBar: AppBar(
        backgroundColor: SettingsGlobalValues.mainColor,
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/settingPage'),
            icon: const Icon(Icons.settings),
            color: SettingsGlobalValues.neutralColor,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => {
                      GameValues.isGameStarted = false,
                      GameValues.isGameEnded = false,
                      GameLogic.resetAll(),
                      Navigator.pushReplacementNamed(context, '/playTable')
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: SettingsGlobalValues.positiveColor,
                    ),
                    child: const Text(
                      'Play',
                      style: TextStyle(
                          color: SettingsGlobalValues.neutralColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/historyPage'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: SettingsGlobalValues.secondColor,
                          ),
                          child: const Text(
                            'History',
                            style: TextStyle(
                                color: SettingsGlobalValues.neutralColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/statsPage'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: SettingsGlobalValues.secondColor,
                          ),
                          child: const Text(
                            'Stats',
                            style: TextStyle(
                                color: SettingsGlobalValues.neutralColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
