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
  static IntegerSetting startingTokens = IntegerSetting(
      settingName: 'Starting Tokens',
      settingValue: 100,
      doesChangeNeedReload: false);
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
      'startingTokens': startingTokens.toJson(),
      'showBestOption': showBestOption.toJson(),
      'showBestOptionAsPopup': showBestOptionAsPopup.toJson(),
      'useShuffler': useShuffler.toJson(),
    };
  }

  factory SettingsGlobalValues.fromJson(Map<String, dynamic> json) {
    SettingsGlobalValues.deckCount = IntegerSetting.fromJson(json['deckCount']);
    SettingsGlobalValues.maxHands = IntegerSetting.fromJson(json['maxHands']);
    if (json.containsKey('startingTokens')) {
      SettingsGlobalValues.startingTokens =
          IntegerSetting.fromJson(json['startingTokens']);
    }
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
        if (jsonData.containsKey('startingTokens')) {
          startingTokens = IntegerSetting.fromJson(jsonData['startingTokens']);
        }
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

  static int SMALL = 0;
  static int MEDIUM = 1;
  static int BIG = 2;

  // Classified by the shortest side of the window, not width/height
  // independently: checking each axis on its own (the old logic) means a
  // window that's narrow-but-tall or wide-but-short gets misclassified by
  // whichever single dimension happens to cross a threshold, and a phone
  // rotated to landscape can flip classification even though its usable
  // (shortest-side) space didn't change. Using the shortest side is
  // orientation-stable and reflects the dimension that actually
  // constrains how many cards/buttons fit.
  static getScreenSize(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double shortestSide = size.width < size.height ? size.width : size.height;
    if (shortestSide >= bigScreenShortestSide) return BIG;
    if (shortestSide <= smallScreenShortestSide) return SMALL;
    return MEDIUM;
  }

  static getCardHeight(BuildContext context) {
    switch(getScreenSize(context)){
      case 0 :
        return playerCardHeightSmall;
      case 1 :
        return playerCardHeightMedium;
      case 2 :
        return playerCardHeightBig;
    }
  }

  static getCardWidth(BuildContext context) {
    switch(getScreenSize(context)){
      case 0 :
        return playerCardWidthSmall;
      case 1 :
        return playerCardWidthMedium;
      case 2 :
        return playerCardWidthBig;
    }
  }

  static getFontSize(BuildContext context) {
    switch(getScreenSize(context)){
      case 0 :
        return smallFont;
      case 1 :
        return mediumFont;
      case 2 :
        return bigFont;
    }
  }

  static getIconSize(BuildContext context) {
    switch(getScreenSize(context)){
      case 0 :
        return smallIconSize;
      case 1 :
        return mediumIconSize;
      case 2 :
        return bigIconSize;
    }
  }

  static double getHomePageButtonHeight(BuildContext context) {
    switch(getScreenSize(context)){
      case 0 :
        return homePageButtonHeightSmall;
      case 1 :
        return homePageButtonHeightMedium;
      case 2 :
        return homePageButtonHeightBig;
      default:
        return homePageButtonHeightMedium;
    }
  }

  static const Color mainColor = Color(0xFF251228);
  static const Color secondColor = Color(0xFF475B63);
  static const Color positiveColor = Color(0xFF339C29);
  static const Color negativeColor = Color(0xFFF42C04);
  static const Color orangeColor = Color(0xFFF4900C);
  static const Color neutralColor = Color(0xFFFFFFFF);
  static const Color goldColor = Color(0xffffd700);
  static const Color activeColor = Color(0xff2873b0);
  static const Color darkColor = Color(0xff000000);

  // Shortest-side breakpoints for getScreenSize(), tuned so phones (~360-430
  // logical px wide) land in SMALL in either orientation and tablets/desktop
  // windows (~768+ shortest side) land in BIG in either orientation.
  static const double bigScreenShortestSide = 700;
  static const double smallScreenShortestSide = 420;

  static const double globalEdgeInset = 10;
  static const double playerCardWidthSmall = 75;
  static const double playerCardHeightSmall = 110;
  static const double playerCardWidthMedium = 120;
  static const double playerCardHeightMedium = 176;
  static const double playerCardWidthBig = 200;
  static const double playerCardHeightBig = 293;
  static const double bigIconSize = 75;
  static const double mediumIconSize = 50;
  static const double smallIconSize = 25;
  static const double addHandButtonWidth = 100;
  static const double addHandButtonHeight = 40;
  static const double homePageButtonHeightSmall = 50;
  static const double homePageButtonHeightMedium = 75;
  static const double homePageButtonHeightBig = 100;
  static const double cardBorderWidth = 4;
  static const SizedBox smallSizedBox = SizedBox(height: 20);
  static const SizedBox mediumSizedBox = SizedBox(height: 40);
  static const SizedBox bigSizedBox = SizedBox(height: 70);

  static const double toastPosition = 50;

  static const double mainScreenFont = 100;
  static const double bigFont = 28;
  static const double mediumFont = 20;
  static const double smallFont = 12;

  static const int timeBetweenDrawsMS = 500;
  static const int tableRefreshTimeMS = 50;

  static const int statChartRadius = 2;
  static const double statChartSpacing = 50;
}
