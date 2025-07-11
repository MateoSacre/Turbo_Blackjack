import 'package:flutter/cupertino.dart';

import '../../Settings/settings_global_values.dart';

class Card {
  final int value;
  final Color color;

  Card(this.value, this.color);

  Widget toWidget(String text) {
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
}

enum Color { heart, diamond, spade, clubs }
