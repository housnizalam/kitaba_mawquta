import 'enums.dart';

/// Stores user-configurable app preferences.
class AppSettings {
  final AppLanguage language;
  final int reminderIntervalMinutes;
  final bool notificationsEnabled;
  final bool adhanEnabled;
  final bool vibrationEnabled;
  final String adhanSoundName;
  final CalculationMethodType calculationMethod;
  final AsrMethod asrMethod;
  final LocationMode locationMode;

  const AppSettings({
    required this.language,
    required this.reminderIntervalMinutes,
    required this.notificationsEnabled,
    required this.adhanEnabled,
    required this.vibrationEnabled,
    required this.adhanSoundName,
    required this.calculationMethod,
    required this.asrMethod,
    required this.locationMode,
  });

  AppSettings copyWith({
    AppLanguage? language,
    int? reminderIntervalMinutes,
    bool? notificationsEnabled,
    bool? adhanEnabled,
    bool? vibrationEnabled,
    String? adhanSoundName,
    CalculationMethodType? calculationMethod,
    AsrMethod? asrMethod,
    LocationMode? locationMode,
  }) {
    return AppSettings(
      language: language ?? this.language,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      adhanEnabled: adhanEnabled ?? this.adhanEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      adhanSoundName: adhanSoundName ?? this.adhanSoundName,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
      locationMode: locationMode ?? this.locationMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language.toMapValue(),
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'notificationsEnabled': notificationsEnabled,
      'adhanEnabled': adhanEnabled,
      'vibrationEnabled': vibrationEnabled,
      'adhanSoundName': adhanSoundName,
      'calculationMethod': calculationMethod.toMapValue(),
      'asrMethod': asrMethod.toMapValue(),
      'locationMode': locationMode.toMapValue(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      language: AppLanguageMapX.fromMapValue(
        map['language'] as String? ?? AppLanguage.english.name,
      ),
      reminderIntervalMinutes: map['reminderIntervalMinutes'] as int? ?? 15,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      adhanEnabled: map['adhanEnabled'] as bool? ?? true,
      vibrationEnabled: map['vibrationEnabled'] as bool? ?? true,
      adhanSoundName: map['adhanSoundName'] as String? ?? 'default_adhan',
      calculationMethod: CalculationMethodTypeMapX.fromMapValue(
        map['calculationMethod'] as String? ??
            CalculationMethodType.muslimWorldLeague.name,
      ),
      asrMethod: AsrMethodMapX.fromMapValue(
        map['asrMethod'] as String? ?? AsrMethod.standard.name,
      ),
      locationMode: LocationModeMapX.fromMapValue(
        map['locationMode'] as String? ?? LocationMode.auto.name,
      ),
    );
  }
}
