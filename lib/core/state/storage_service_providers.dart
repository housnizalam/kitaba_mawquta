import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage.dart';

/// Provides app settings storage access.
final appSettingsStorageServiceProvider = Provider<AppSettingsStorageService>(
  (ref) => AppSettingsStorageService(),
);

/// Provides user location storage access.
final userLocationStorageServiceProvider = Provider<UserLocationStorageService>(
  (ref) => UserLocationStorageService(),
);

/// Provides today schedule storage access.
final todayScheduleStorageServiceProvider =
    Provider<TodayScheduleStorageService>(
      (ref) => TodayScheduleStorageService(),
    );

/// Provides historical daily log storage access.
final dailyPrayerHistoryStorageServiceProvider =
    Provider<DailyPrayerHistoryStorageService>(
      (ref) => DailyPrayerHistoryStorageService(),
    );
