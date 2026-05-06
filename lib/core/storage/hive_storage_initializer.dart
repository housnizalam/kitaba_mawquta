import 'package:hive_flutter/hive_flutter.dart';

import 'hive_box_names.dart';

/// Initializes Hive and opens all boxes used by the storage layer.
class HiveStorageInitializer {
  /// Call this once during app startup in a future setup step.
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await openRequiredBoxes();
  }

  /// Opens all application boxes if they are not open yet.
  static Future<void> openRequiredBoxes() async {
    await _openBoxIfNeeded(HiveBoxNames.appSettings);
    await _openBoxIfNeeded(HiveBoxNames.userLocation);
    await _openBoxIfNeeded(HiveBoxNames.todaySchedule);
    await _openBoxIfNeeded(HiveBoxNames.dailyPrayerHistory);
  }

  /// Closes all Hive boxes.
  static Future<void> closeAllBoxes() async {
    await Hive.close();
  }

  static Future<void> _openBoxIfNeeded(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return;
    }

    await Hive.openBox<Map>(boxName);
  }
}
