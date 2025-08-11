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
                      'Jouer',
                      style: TextStyle(
                          color: SettingsGlobalValues.neutralColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/settingPage'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: SettingsGlobalValues.secondColor,
                    ),
                    child: const Text(
                      'Reglages',
                      style: TextStyle(
                          color: SettingsGlobalValues.neutralColor,
                          fontWeight: FontWeight.bold),
                    ),
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
