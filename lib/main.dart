import 'package:flutter/material.dart';
import 'package:turbo_blackjack/Game/Data/game_values.dart';
import 'package:turbo_blackjack/Game/Logic/best_moves.dart';

import 'Game/Table/play_table.dart';
import 'Game/home_page.dart';
import 'Settings/setting_page.dart';
import 'Settings/settings_global_values.dart';
import 'Game/Data/History/history_manager.dart';
import 'Game/history_page.dart';
import 'Game/stats_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsGlobalValues.loadSettings();
  GameValues.playerTokens = SettingsGlobalValues.startingTokens.settingValue;
  GameValues.bankruptcyCount = 0;
  await HistoryManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    BestMoves.generateMatrix();

    return MaterialApp(
      title: 'Flutter Demo',
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/homePage': (context) => const HomePage(),
        '/playTable': (context) => const PlayTable(),
        '/settingPage': (context) => const SettingsPage(),
        '/historyPage': (context) => const HistoryPage(),
        '/statsPage': (context) => const StatsPage(),
      },
    );
  }
}
