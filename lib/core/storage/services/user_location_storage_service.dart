import 'package:hive_flutter/hive_flutter.dart';

import '../../models/user_location_data.dart';
import '../hive_box_names.dart';
import '../storage_key_helpers.dart';

/// Persists and loads [UserLocationData] using map-based Hive records.
class UserLocationStorageService {
  Future<void> saveLocation(UserLocationData location) async {
    final box = await Hive.openBox<Map>(HiveBoxNames.userLocation);
    await box.put(StorageKeyHelpers.singleRecordKey, location.toMap());
  }

  Future<UserLocationData?> loadLocation() async {
    final box = await Hive.openBox<Map>(HiveBoxNames.userLocation);
    final raw = box.get(StorageKeyHelpers.singleRecordKey);
    if (raw == null) {
      return null;
    }

    return UserLocationData.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> clearLocation() async {
    final box = await Hive.openBox<Map>(HiveBoxNames.userLocation);
    await box.clear();
  }
}
