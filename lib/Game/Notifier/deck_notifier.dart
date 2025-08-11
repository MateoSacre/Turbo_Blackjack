import 'package:flutter/material.dart';

class DeckNotifier extends ChangeNotifier {
  static final DeckNotifier instance = DeckNotifier._internal();
  DeckNotifier._internal();

  void notifyCardDrawn() {
    notifyListeners();
  }
}
