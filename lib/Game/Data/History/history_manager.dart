import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'history_game.dart';

class HistoryManager {
  static List<HistoryGame> history = [];
  static late File _file;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/history.json');
    if (await _file.exists()) {
      final content = await _file.readAsString();
      if (content.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(content);
        history = jsonList.map((e) => HistoryGame.fromJson(e)).toList();
      }
    } else {
      await _file.create(recursive: true);
      await _file.writeAsString('[]');
    }
  }

  static Future<void> _save() async {
    final data = jsonEncode(history.map((e) => e.toJson()).toList());
    await _file.writeAsString(data);
  }

  static Future<void> addGame(HistoryGame game) async {
    history.add(game);
    await _save();
  }
}
