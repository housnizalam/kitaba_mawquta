import 'package:hive_flutter/hive_flutter.dart';

import '../../models/daily_prayer_schedule.dart';
import '../hive_box_names.dart';
import '../storage_key_helpers.dart';

/// Persists and loads the current day schedule.
class TodayScheduleStorageService {
  Future<void> saveTodaySchedule(DailyPrayerSchedule schedule) async {
    final box = await Hive.openBox<Map>(HiveBoxNames.todaySchedule);
    await box.put(StorageKeyHelpers.singleRecordKey, schedule.toMap());
  }

  Future<DailyPrayerSchedule?> loadTodaySchedule() async {
    final box = await Hive.openBox<Map>(HiveBoxNames.todaySchedule);
    final raw = box.get(StorageKeyHelpers.singleRecordKey);
    if (raw == null) {
      return null;
    }

    return DailyPrayerSchedule.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> clearTodaySchedule() async {
    final box = await Hive.openBox<Map>(HiveBoxNames.todaySchedule);
    await box.clear();
  }
}
