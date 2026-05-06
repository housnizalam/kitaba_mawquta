import 'package:hive_flutter/hive_flutter.dart';

import '../../models/daily_prayer_log.dart';
import '../hive_box_names.dart';
import '../storage_key_helpers.dart';

/// Persists historical prayer logs with one Hive record per day.
class DailyPrayerHistoryStorageService {
  Future<void> saveOrReplaceDailyLog(DailyPrayerLog log) async {
    final box = await Hive.openBox<Map>(HiveBoxNames.dailyPrayerHistory);
    final key = StorageKeyHelpers.dayKey(log.date);
    await box.put(key, log.toMap());
  }

  Future<void> saveDailyLog(DailyPrayerLog log) async {
    await saveOrReplaceDailyLog(log);
  }

  Future<List<DailyPrayerLog>> loadAllDailyLogs() async {
    final box = await Hive.openBox<Map>(HiveBoxNames.dailyPrayerHistory);

    final logs = box.values
        .map((item) => DailyPrayerLog.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    logs.sort((a, b) => a.date.compareTo(b.date));
    return logs;
  }

  Future<DailyPrayerLog?> loadDailyLogByDate(DateTime date) async {
    final box = await Hive.openBox<Map>(HiveBoxNames.dailyPrayerHistory);
    final key = StorageKeyHelpers.dayKey(date);
    final raw = box.get(key);
    if (raw == null) {
      return null;
    }

    return DailyPrayerLog.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> deleteDailyLogByDate(DateTime date) async {
    final box = await Hive.openBox<Map>(HiveBoxNames.dailyPrayerHistory);
    final key = StorageKeyHelpers.dayKey(date);
    await box.delete(key);
  }

  Future<void> clearHistory() async {
    final box = await Hive.openBox<Map>(HiveBoxNames.dailyPrayerHistory);
    await box.clear();
  }
}
