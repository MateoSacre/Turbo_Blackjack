import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'history_game.dart';

class HistoryManager {
  static List<HistoryGame> history = [];
  static File? _file;

  static Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/history.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content);
          history = jsonList.map((e) => HistoryGame.fromJson(e)).toList();
        }
      } else {
        await file.create(recursive: true);
        await file.writeAsString('[]');
      }
      _file = file;
    } catch (e) {
      // No filesystem access on this platform (e.g. web): keep history
      // in-memory for the session instead of crashing on startup.
      _file = null;
    }
  }

  static Future<void> _save() async {
    final file = _file;
    if (file == null) {
      return;
    }
    final data = jsonEncode(history.map((e) => e.toJson()).toList());
    await file.writeAsString(data);
  }

  static Future<void> addGame(HistoryGame game) async {
    history.add(game);
    await _save();
  }
}
