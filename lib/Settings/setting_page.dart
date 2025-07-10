import 'package:flutter/material.dart';
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
      result.addAll(getOptionBooleanCoDependant(
          SettingsGlobalValues.showBestOptions,
          SettingsGlobalValues.showBestOptionAsPopup));
      result.addAll(getOptionBooleanCoDependant(
          SettingsGlobalValues.showBestOptionAsPopup,
          SettingsGlobalValues.showBestOptions));
      result.addAll(getOptionSlider(SettingsGlobalValues.nbDecks));
      result.addAll(getOptionSlider(SettingsGlobalValues.maxHands));
      result.addAll(getOptionBoolean(SettingsGlobalValues.useShuffler));
    });
    return result;
  }

  validateSettings() {
    SettingsGlobalValues.saveSettings();
    if (isReloadNeeded) {
      Decklogic.resetDeck();
    }
    Navigator.pushReplacementNamed(context, '/homePage');
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
              child: Column(children: [
            Wrap(
                alignment: WrapAlignment.center,
                children: generateSettingsWidgetList()),
            ElevatedButton(
              onPressed: validateSettings,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: SettingsGlobalValues.positiveColor,
                disabledBackgroundColor:
                    SettingsGlobalValues.negativeColor.withOpacity(.8),
              ),
              child: const Text(
                "Validate",
                style: TextStyle(color: SettingsGlobalValues.neutralColor),
              ),
            )
          ]))),
    );
  }

  List<Widget> getOptionSlider(IntegerSetting setting) {
    return getOptionSliderWithValues(setting, 1, 10, 9);
  }

  List<Widget> getOptionSliderWithValues(
      IntegerSetting setting, double min, double max, int divisions) {
    List<Widget> result = [];
    result.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          setting.settingName,
          style: const TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
      ),
    );
    result.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          setting.settingName,
          style: const TextStyle(color: SettingsGlobalValues.neutralColor),
        ),
      ),
    );
    result.add(Slider(
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
    ));
    result.add(SettingsGlobalValues.globalSizedBox);
    return result;
  }

  List<Widget> getOptionBoolean(BoolSetting setting) {
    List<Widget> result = [];
    result.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            setting.settingName,
            style: const TextStyle(color: SettingsGlobalValues.neutralColor),
          ),
        ),
        Switch(
          value: setting.settingValue,
          activeColor: SettingsGlobalValues.positiveColor,
          inactiveThumbColor: SettingsGlobalValues.negativeColor,
          onChanged: (value) {
            setState(() {
              setting.settingValue = value;
              isReloadNeeded = isReloadNeeded || setting.doesChangeNeedReload;
            });
          },
        ),
      ],
    ));
    result.add(SettingsGlobalValues.globalSizedBox);
    return result;
  }

  List<Widget> getOptionBooleanCoDependant(
      BoolSetting setting, BoolSetting dependantSetting) {
    List<Widget> result = [];
    result.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              setting.settingName,
              style: const TextStyle(color: SettingsGlobalValues.neutralColor),
            ),
          ),
          Switch(
            value: setting.settingValue,
            activeColor: SettingsGlobalValues.positiveColor,
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
      ),
    );
    result.add(SettingsGlobalValues.globalSizedBox);
    return result;
  }
}
