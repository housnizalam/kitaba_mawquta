import '../models/models.dart';

/// Provides safe default values used when no persisted data exists yet.
abstract final class AppStateDefaults {
  static AppSettings defaultSettings() {
    return const AppSettings(
      language: AppLanguage.english,
      reminderIntervalMinutes: 15,
      notificationsEnabled: true,
      adhanEnabled: true,
      vibrationEnabled: true,
      adhanSoundName: 'default_adhan',
      calculationMethod: CalculationMethodType.muslimWorldLeague,
      asrMethod: AsrMethod.standard,
      locationMode: LocationMode.auto,
    );
  }

  static UserLocationData defaultLocation() {
    return UserLocationData(
      latitude: 0,
      longitude: 0,
      cityName: '',
      countryName: '',
      timeZoneId: 'UTC',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static DailyPrayerSchedule defaultTodaySchedule({DateTime? now}) {
    final date = now ?? DateTime.now();
    final safeDate = DateTime(date.year, date.month, date.day);
    return DailyPrayerSchedule(date: safeDate, prayers: const []);
  }

  static PrayerTrackingState defaultTrackingState() {
    return const PrayerTrackingState(
      currentPrayerType: null,
      isReminderActive: false,
      nextReminderAt: null,
      countdownEndsAt: null,
    );
  }

  static AppState initialAppState({DateTime? now}) {
    return AppState(
      settings: defaultSettings(),
      location: defaultLocation(),
      todaySchedule: defaultTodaySchedule(now: now),
      tracking: defaultTrackingState(),
      history: const [],
    );
  }
}
