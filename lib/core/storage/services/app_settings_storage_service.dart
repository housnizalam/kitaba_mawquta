import 'package:hive_flutter/hive_flutter.dart';

import '../../models/app_settings.dart';
import '../hive_box_names.dart';
import '../storage_key_helpers.dart';

/// Persists and loads [AppSettings] using map-based Hive records.
class AppSettingsStorageService {
  Future<void> saveSettings(AppSettings settings) async {
    final box = await Hive.openBox<Map>(HiveBoxNames.appSettings);
    await box.put(StorageKeyHelpers.singleRecordKey, settings.toMap());
  }

  Future<AppSettings?> loadSettings() async {
    final box = await Hive.openBox<Map>(HiveBoxNames.appSettings);
    final raw = box.get(StorageKeyHelpers.singleRecordKey);
    if (raw == null) {
      return null;
    }

    return AppSettings.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> clearSettings() async {
    final box = await Hive.openBox<Map>(HiveBoxNames.appSettings);
    await box.clear();
  }
}
