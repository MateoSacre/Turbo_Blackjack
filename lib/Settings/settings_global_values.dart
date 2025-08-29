import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turbo_blackjack/Settings/settings_types.dart';

class SettingsGlobalValues {
  SettingsGlobalValues();

  static final logger = Logger(level: Level.debug);

  static IntegerSetting deckCount = IntegerSetting(
      settingName: 'Deck Count', settingValue: 1, doesChangeNeedReload: true);
  static IntegerSetting maxHands = IntegerSetting(
      settingName: 'Max Hands', settingValue: 3, doesChangeNeedReload: false);
  static BoolSetting showBestOption = BoolSetting(
      settingName: "Show Best Option",
      settingValue: false,
      doesChangeNeedReload: false);
  static BoolSetting showBestOptionAsPopup = BoolSetting(
      settingName: "Show Best Option as Popup",
      settingValue: false,
      doesChangeNeedReload: false);
  static BoolSetting useShuffler = BoolSetting(
      settingName: "Use Shuffler",
      settingValue: false,
      doesChangeNeedReload: true);

  static Map<String, dynamic> toJson() {
    return {
      'deckCount': deckCount.toJson(),
      'maxHands': maxHands.toJson(),
      'showBestOption': showBestOption.toJson(),
      'showBestOptionAsPopup': showBestOptionAsPopup.toJson(),
      'useShuffler': useShuffler.toJson(),
    };
  }

  factory SettingsGlobalValues.fromJson(Map<String, dynamic> json) {
    SettingsGlobalValues.deckCount = IntegerSetting.fromJson(json['deckCount']);
    SettingsGlobalValues.maxHands = IntegerSetting.fromJson(json['maxHands']);
    SettingsGlobalValues.showBestOption =
        BoolSetting.fromJson(json['showBestOption']);
    SettingsGlobalValues.showBestOptionAsPopup =
        BoolSetting.fromJson(json['showBestOptionAsPopup']);
    SettingsGlobalValues.useShuffler =
        BoolSetting.fromJson(json['useShuffler']);

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

        deckCount = IntegerSetting.fromJson(jsonData['deckCount']);
        maxHands = IntegerSetting.fromJson(jsonData['maxHands']);
        showBestOption = BoolSetting.fromJson(jsonData['showBestOption']);
        showBestOptionAsPopup =
            BoolSetting.fromJson(jsonData['showBestOptionAsPopup']);
        useShuffler = BoolSetting.fromJson(jsonData['useShuffler']);
      }
    } catch (e) {
      logger.w("Error while loading settings: $e");
    }
  }

  static isLandscape(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height;
    return width > height;
  }

  static const Color mainColor = Color(0xFF251228);
  static const Color secondColor = Color(0xFF475B63);
  static const Color positiveColor = Color(0xFF339C29);
  static const Color negativeColor = Color(0xFFF42C04);
  static const Color orangeColor = Color(0xFFF42C04);
  static const Color neutralColor = Color(0xFFFFFFFF);
  static const Color goldColor = Color(0xffffd700);
  static const Color activeColor = Color(0xff2873b0);
  static const Color darkColor = Color(0xff000000);

  static const double globalEdgeInset = 10;
  static const double playerCardWidth = 75;
  static const double playerCardHeight = 110;
  static const double addHandButtonWidth = 100;
  static const double addHandButtonHeight = 40;
  static const double cardBorderWidth = 4;
  static const SizedBox globalSizedBox = SizedBox(height: 20);
  static const SizedBox bigSizedBox = SizedBox(height: 70);

  static const double toastPosition = 50;

  static const double mainScreenFont = 100;
  static const double mainFont = 16;
  static const double smallFont = 12;

  static const int timeBetweenDrawsMS = 500;
  static const int tableRefreshTimeMS = 50;

  static const int statChartRadius = 3;
}
