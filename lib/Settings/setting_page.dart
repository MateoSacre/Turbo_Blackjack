import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:turbo_blackjack/Settings/settings_global_values.dart';
import 'package:turbo_blackjack/Settings/settings_types.dart';

import '../Game/Logic/deck_logic.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool isReloadNeeded = false;

  List<Widget> generateSettingsWidgetList() {
    List<Widget> result = [];
    setState(() {
      result.add(getOptionBooleanCoDependant(
          SettingsGlobalValues.showBestOption,
          SettingsGlobalValues.showBestOptionAsPopup));
      result.add(getOptionBooleanCoDependant(
          SettingsGlobalValues.showBestOptionAsPopup,
          SettingsGlobalValues.showBestOption));
      result.add(getOptionSlider(SettingsGlobalValues.deckCount));
      result.add(getOptionSlider(SettingsGlobalValues.maxHands));
      result.add(getOptionSliderWithValues(
          SettingsGlobalValues.startingTokens, 10, 500, 49));
      result.add(getOptionBoolean(SettingsGlobalValues.useShuffler));
    });
    return result;
  }

  validateSettings() {
    SettingsGlobalValues.saveSettings();
    if (isReloadNeeded) {
      DeckLogic.resetDeck();
    }
    Navigator.pushReplacementNamed(context, '/homePage');
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> settingsList = generateSettingsWidgetList();
    return Scaffold(
      backgroundColor: SettingsGlobalValues.mainColor,
      appBar: AppBar(
        iconTheme:
            const IconThemeData(color: SettingsGlobalValues.neutralColor),
        backgroundColor: SettingsGlobalValues.mainColor,
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(SettingsGlobalValues.globalEdgeInset),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: MasonryGridView.count(
              crossAxisCount: SettingsGlobalValues.isLandscape(context) ? 3 : 2,
              mainAxisSpacing: 50,
              crossAxisSpacing: 50,
              itemCount: settingsList.length,
              itemBuilder: (context, index) {
                return settingsList[index];
              }),
        ),
      ),
      bottomNavigationBar: ElevatedButton(
        onPressed: validateSettings,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity,
              SettingsGlobalValues.getHomePageButtonHeight(context)),
          backgroundColor: SettingsGlobalValues.positiveColor,
          disabledBackgroundColor:
              SettingsGlobalValues.negativeColor.withValues(alpha: .8),
        ),
        child: Text(
          "Validate",
          style: TextStyle(
              color: SettingsGlobalValues.neutralColor,
              fontSize:
                  SettingsGlobalValues.getFontSize(context)),
        ),
      ),
    );
  }

  Widget getOptionSlider(IntegerSetting setting) {
    return getOptionSliderWithValues(setting, 1, 7, 6);
  }

  Widget getOptionSliderWithValues(
      IntegerSetting setting, double min, double max, int divisions) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            setting.settingName,
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            setting.settingValue.toString(),
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
        Slider(
          value: setting.settingValue.toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: setting.settingValue.toString(),
          onChanged: (value) {
            setState(() {
              setting.settingValue = value.toInt();
              isReloadNeeded = isReloadNeeded || setting.doesChangeNeedReload;
            });
          },
        ),
        SettingsGlobalValues.smallSizedBox
      ],
    );
  }

  Widget getOptionBoolean(BoolSetting setting) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            setting.settingName,
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
        Switch(
          value: setting.settingValue,
          activeThumbColor: SettingsGlobalValues.positiveColor,
          inactiveThumbColor: SettingsGlobalValues.negativeColor,
          onChanged: (value) {
            setState(() {
              setting.settingValue = value;
              isReloadNeeded = isReloadNeeded || setting.doesChangeNeedReload;
            });
          },
        ),
      ],
    );
  }

  Widget getOptionBooleanCoDependant(
      BoolSetting setting, BoolSetting dependantSetting) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            setting.settingName,
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor,
                fontSize: SettingsGlobalValues.getFontSize(context)),
          ),
        ),
        Switch(
          value: setting.settingValue,
          activeThumbColor: SettingsGlobalValues.positiveColor,
          inactiveThumbColor: SettingsGlobalValues.negativeColor,
          onChanged: (value) {
            setState(() {
              setting.settingValue = value;
              if (setting.settingValue && dependantSetting.settingValue) {
                dependantSetting.settingValue = false;
              }
              isReloadNeeded = isReloadNeeded || setting.doesChangeNeedReload;
            });
          },
        ),
      ],
    );
  }
}
