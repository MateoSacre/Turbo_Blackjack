import 'package:flutter/material.dart';

import 'Game/Table/play_table.dart';
import 'Game/home_page.dart';
import 'Settings/setting_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        '/playTable': (context) => const PlayTable(),
        '/settingPage': (context) => const SettingsPage(),
      },
    );
  }
}
