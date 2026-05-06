import '../models/models.dart';
import '../schedule/schedule.dart';

/// Temporary development-only demo data generator.
///
/// This helper is intended for local UI testing before real prayer-time
/// calculation and location integrations are connected.
class DevDemoDataService {
  /// Returns a realistic demo location for home page testing.
  UserLocationData buildDemoLocation({DateTime? now}) {
    return UserLocationData(
      latitude: 52.5200,
      longitude: 13.4050,
      cityName: 'Berlin',
      countryName: 'Germany',
      timeZoneId: 'Europe/Berlin',
      updatedAt: now ?? DateTime.now(),
    );
  }

  /// Returns demo prayer start times for today.
  ///
  /// The times are generated relative to [now] so one prayer is usually active,
  /// some are earlier, and some are upcoming.
  RawDailyPrayerTimes buildDemoRawDailyPrayerTimes({DateTime? now}) {
    final current = now ?? DateTime.now();
    final date = DateTime(current.year, current.month, current.day);

    return RawDailyPrayerTimes(
      date: date,
      fajr: current.subtract(const Duration(hours: 6)),
      dhuhr: current.subtract(const Duration(hours: 3)),
      asr: current.subtract(const Duration(minutes: 30)),
      maghrib: current.add(const Duration(hours: 1, minutes: 30)),
      isha: current.add(const Duration(hours: 4)),
    );
  }

  /// Builds a fully-formed demo schedule using the existing builder service.
  DailyPrayerSchedule buildDemoSchedule(
    PrayerScheduleBuilderService builder, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final raw = buildDemoRawDailyPrayerTimes(now: current);
    return builder.buildSchedule(raw, now: current);
  }

  /// True when location data is not meaningfully set yet.
  bool isLocationMissing(UserLocationData location) {
    return location.cityName.trim().isEmpty;
  }

  /// True when today's schedule is not meaningfully available yet.
  bool isScheduleMissing(DailyPrayerSchedule schedule) {
    return schedule.prayers.isEmpty;
  }
}
