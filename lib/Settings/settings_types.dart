class Setting {
  final String settingName;
  final bool doesChangeNeedReload;

  Setting({required this.settingName, required this.doesChangeNeedReload});

  Map<String, dynamic> toJson() {
    return {
      'settingName': settingName,
      'doesChangeNeedReload': doesChangeNeedReload
    };
  }
}

class BoolSetting extends Setting {
  bool settingValue;

  BoolSetting(
      {required super.settingName,
      required this.settingValue,
      required super.doesChangeNeedReload});

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'settingValue': settingValue,
    };
  }

  factory BoolSetting.fromJson(Map<String, dynamic> json) {
    return BoolSetting(
      settingName: json['settingName'],
      settingValue: json['settingValue'],
      doesChangeNeedReload: json['doesChangeNeedReload'],
    );
  }
}

class IntegerSetting extends Setting {
  int settingValue;

  IntegerSetting(
      {required super.settingName,
      required this.settingValue,
      required super.doesChangeNeedReload});

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'settingValue': settingValue,
    };
  }

  factory IntegerSetting.fromJson(Map<String, dynamic> json) {
    return IntegerSetting(
      settingName: json['settingName'],
      settingValue: json['settingValue'],
      doesChangeNeedReload: json['doesChangeNeedReload'],
    );
  }
}
