import 'package:flutter/material.dart';

import 'Game/Table/play_table.dart';
import 'Game/home_page.dart';
import 'Settings/setting_page.dart';
import 'Settings/settings_global_values.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsGlobalValues.loadSettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: const HomePage(),
      routes: {
        '/homePage': (context) => const HomePage(),
        '/playTable': (context) => const PlayTable(),
        '/settingPage': (context) => const SettingsPage(),
      },
    );
  }
}
