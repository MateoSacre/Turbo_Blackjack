import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turbo_blackjack/Settings/settings_types.dart';

class SettingsGlobalValues {
  SettingsGlobalValues();

  static final logger = Logger();

  static IntegerSetting nbDecks = IntegerSetting(
      settingName: 'DECK_NUMBER', settingValue: 6, doesChangeNeedReload: true);
  static IntegerSetting maxHands = IntegerSetting(
      settingName: 'MAX_HANDS', settingValue: 3, doesChangeNeedReload: false);
  static BoolSetting showBestOptions = BoolSetting(
      settingName: "SHOW_BEST_OPTION",
      settingValue: false,
      doesChangeNeedReload: false);
  static BoolSetting showBestOptionAsPopup = BoolSetting(
      settingName: "SHOW_BEST_OPTION_AS_POPUP",
      settingValue: false,
      doesChangeNeedReload: false);
  static BoolSetting useShuffler = BoolSetting(
      settingName: "USE_SHUFFLER",
      settingValue: false,
      doesChangeNeedReload: true);

  static Map<String, dynamic> toJson() {
    return {
      'nbDecks': nbDecks.toJson(),
      'maxHands': maxHands.toJson(),
      'showBestOptions': showBestOptions.toJson(),
      'showBestOptionAsPopup': showBestOptionAsPopup.toJson(),
    };
  }

  factory SettingsGlobalValues.fromJson(Map<String, dynamic> json) {
    SettingsGlobalValues.nbDecks = IntegerSetting.fromJson(json['nbDecks']);
    SettingsGlobalValues.maxHands = IntegerSetting.fromJson(json['maxHands']);
    SettingsGlobalValues.showBestOptions =
        BoolSetting.fromJson(json['showBestOptions']);
    SettingsGlobalValues.showBestOptionAsPopup =
        BoolSetting.fromJson(json['showBestOptionAsPopup']);

    return SettingsGlobalValues();
  }

  static Future<void> saveSettings() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/settingsTurboBlackJack.json');
    final jsonSettings = jsonEncode(toJson());
    await file.writeAsString(jsonSettings);
  }

  static Future<void> loadSettings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/settingsTurboBlackJack.json');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString);

        nbDecks = IntegerSetting.fromJson(jsonData['nbDecks']);
        maxHands = IntegerSetting.fromJson(jsonData['maxHands']);
        showBestOptions = BoolSetting.fromJson(jsonData['showBestOptions']);
        showBestOptionAsPopup =
            BoolSetting.fromJson(jsonData['showBestOptionAsPopup']);
      }
    } catch (e) {
      logger.w("Erreur lors du chargement des paramètres: $e");
    }
  }

  static const Color mainColor = Color(0xFF251228);
  static const Color secondColor = Color(0xFF475B63);
  static const Color positiveColor = Color(0xFF339C29);
  static const Color negativeColor = Color(0xFFF42C04);
  static const Color neutralColor = Color(0xFFFFFFFF);
  static const Color goldColor = Color(0xffffd700);

  static const double globalEdgeInset = 10;
  static const double playerCardWidth = 100;
  static const double playerCardHeight = 150;
  static const double addHandButtonWidth = 100;
  static const double addHandButtonHeight = 40;
  static const SizedBox globalSizedBox = SizedBox(height: 20);
  static const SizedBox bigSizedBox = SizedBox(height: 70);

  static const double toastPosition = 50;

  static const double mainScreenFont = 100;
  static const double mainFont = 16;
  static const double smallFont = 12;
}
