import 'app_settings.dart';
import 'daily_prayer_log.dart';
import 'daily_prayer_schedule.dart';
import 'prayer_tracking_state.dart';
import 'user_location_data.dart';

/// Root app state that combines all persisted and runtime model sections.
class AppState {
  final AppSettings settings;
  final UserLocationData location;
  final DailyPrayerSchedule todaySchedule;
  final PrayerTrackingState tracking;
  final List<DailyPrayerLog> history;
  final DateTime selectedDate;

  const AppState({
    required this.settings,
    required this.location,
    required this.todaySchedule,
    required this.tracking,
    required this.history,
    required this.selectedDate,
  });

  AppState copyWith({
    AppSettings? settings,
    UserLocationData? location,
    DailyPrayerSchedule? todaySchedule,
    PrayerTrackingState? tracking,
    List<DailyPrayerLog>? history,
    DateTime? selectedDate,
  }) {
    return AppState(
      settings: settings ?? this.settings,
      location: location ?? this.location,
      todaySchedule: todaySchedule ?? this.todaySchedule,
      tracking: tracking ?? this.tracking,
      history: history ?? this.history,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'settings': settings.toMap(),
      'location': location.toMap(),
      'todaySchedule': todaySchedule.toMap(),
      'tracking': tracking.toMap(),
      'history': history.map((item) => item.toMap()).toList(),
      'selectedDate': selectedDate.toIso8601String(),
    };
  }

  factory AppState.fromMap(Map<String, dynamic> map) {
    final rawHistory = map['history'] as List<dynamic>? ?? const [];

    return AppState(
      settings: AppSettings.fromMap(
        Map<String, dynamic>.from(map['settings'] as Map? ?? const {}),
      ),
      location: UserLocationData.fromMap(
        Map<String, dynamic>.from(map['location'] as Map? ?? const {}),
      ),
      todaySchedule: DailyPrayerSchedule.fromMap(
        Map<String, dynamic>.from(map['todaySchedule'] as Map? ?? const {}),
      ),
      tracking: PrayerTrackingState.fromMap(
        Map<String, dynamic>.from(map['tracking'] as Map? ?? const {}),
      ),
      history: rawHistory
          .map(
            (item) =>
                DailyPrayerLog.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      selectedDate:
          DateTime.tryParse(map['selectedDate'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
