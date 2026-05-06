/// All supported prayer names used throughout the app.
enum PrayerType { fajr, dhuhr, asr, maghrib, isha }

/// Tracks whether a prayer is still pending, completed, or missed.
enum PrayerCompletionStatus { pending, prayed, missed }

/// Supported app languages.
enum AppLanguage { english, arabic, german }

/// Defines how the app gets location data.
enum LocationMode { auto, manual }

/// Supported prayer time calculation methods.
enum CalculationMethodType {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  northAmerica,
  kuwait,
  qatar,
  singapore,
  tehran,
  turkey,
  moonsightingCommittee,
  other,
}

/// Defines which Asr shadow ratio is used for Asr prayer time.
enum AsrMethod { standard, hanafi }

/// Map and string helpers for [PrayerType].
extension PrayerTypeMapX on PrayerType {
  String toMapValue() => name;

  static PrayerType fromMapValue(String value) {
    return PrayerType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => PrayerType.fajr,
    );
  }
}

/// Map and string helpers for [PrayerCompletionStatus].
extension PrayerCompletionStatusMapX on PrayerCompletionStatus {
  String toMapValue() => name;

  static PrayerCompletionStatus fromMapValue(String value) {
    return PrayerCompletionStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => PrayerCompletionStatus.pending,
    );
  }
}

/// Map and string helpers for [AppLanguage].
extension AppLanguageMapX on AppLanguage {
  String toMapValue() => name;

  static AppLanguage fromMapValue(String value) {
    return AppLanguage.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Map and string helpers for [LocationMode].
extension LocationModeMapX on LocationMode {
  String toMapValue() => name;

  static LocationMode fromMapValue(String value) {
    return LocationMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => LocationMode.auto,
    );
  }
}

/// Map and string helpers for [CalculationMethodType].
extension CalculationMethodTypeMapX on CalculationMethodType {
  String toMapValue() => name;

  static CalculationMethodType fromMapValue(String value) {
    return CalculationMethodType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => CalculationMethodType.muslimWorldLeague,
    );
  }
}

/// Map and string helpers for [AsrMethod].
extension AsrMethodMapX on AsrMethod {
  String toMapValue() => name;

  static AsrMethod fromMapValue(String value) {
    return AsrMethod.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AsrMethod.standard,
    );
  }
}
