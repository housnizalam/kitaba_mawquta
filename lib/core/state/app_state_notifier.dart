import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'app_state_defaults.dart';
import 'storage_service_providers.dart';

/// Central state manager that orchestrates app state and persistence.
class AppStateNotifier extends AsyncNotifier<AppState> {
  @override
  Future<AppState> build() async {
    final settingsService = ref.read(appSettingsStorageServiceProvider);
    final locationService = ref.read(userLocationStorageServiceProvider);
    final scheduleService = ref.read(todayScheduleStorageServiceProvider);
    final historyService = ref.read(dailyPrayerHistoryStorageServiceProvider);

    final now = DateTime.now();

    final settings =
        await settingsService.loadSettings() ??
        AppStateDefaults.defaultSettings();
    final location =
        await locationService.loadLocation() ??
        AppStateDefaults.defaultLocation();
    final todaySchedule =
        await scheduleService.loadTodaySchedule() ??
        AppStateDefaults.defaultTodaySchedule(now: now);
    final history = await historyService.loadAllDailyLogs();

    return AppState(
      settings: settings,
      location: location,
      todaySchedule: todaySchedule,
      tracking: AppStateDefaults.defaultTrackingState(),
      history: history,
    );
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    final current = await _currentState();
    await ref.read(appSettingsStorageServiceProvider).saveSettings(newSettings);
    state = AsyncValue.data(current.copyWith(settings: newSettings));
  }

  Future<void> clearSettings() async {
    final current = await _currentState();
    await ref.read(appSettingsStorageServiceProvider).clearSettings();
    state = AsyncValue.data(
      current.copyWith(settings: AppStateDefaults.defaultSettings()),
    );
  }

  Future<void> updateLocation(UserLocationData newLocation) async {
    final current = await _currentState();
    await ref
        .read(userLocationStorageServiceProvider)
        .saveLocation(newLocation);
    state = AsyncValue.data(current.copyWith(location: newLocation));
  }

  Future<void> clearLocation() async {
    final current = await _currentState();
    await ref.read(userLocationStorageServiceProvider).clearLocation();
    state = AsyncValue.data(
      current.copyWith(location: AppStateDefaults.defaultLocation()),
    );
  }

  Future<void> saveTodaySchedule(DailyPrayerSchedule schedule) async {
    final current = await _currentState();
    await ref
        .read(todayScheduleStorageServiceProvider)
        .saveTodaySchedule(schedule);
    state = AsyncValue.data(current.copyWith(todaySchedule: schedule));
  }

  Future<void> clearTodaySchedule() async {
    final current = await _currentState();
    await ref.read(todayScheduleStorageServiceProvider).clearTodaySchedule();
    state = AsyncValue.data(
      current.copyWith(todaySchedule: AppStateDefaults.defaultTodaySchedule()),
    );
  }

  Future<void> saveOrReplaceDailyLog(DailyPrayerLog log) async {
    final current = await _currentState();
    final historyService = ref.read(dailyPrayerHistoryStorageServiceProvider);

    await historyService.saveOrReplaceDailyLog(log);

    final updatedHistory = _replaceLogByDate(current.history, log);
    state = AsyncValue.data(current.copyWith(history: updatedHistory));
  }

  Future<void> clearHistory() async {
    final current = await _currentState();
    await ref.read(dailyPrayerHistoryStorageServiceProvider).clearHistory();
    state = AsyncValue.data(current.copyWith(history: const []));
  }

  Future<void> updateTrackingState(PrayerTrackingState trackingState) async {
    final current = await _currentState();
    state = AsyncValue.data(current.copyWith(tracking: trackingState));
  }

  Future<void> clearAllStoredSections() async {
    final now = DateTime.now();

    await ref.read(appSettingsStorageServiceProvider).clearSettings();
    await ref.read(userLocationStorageServiceProvider).clearLocation();
    await ref.read(todayScheduleStorageServiceProvider).clearTodaySchedule();
    await ref.read(dailyPrayerHistoryStorageServiceProvider).clearHistory();

    state = AsyncValue.data(AppStateDefaults.initialAppState(now: now));
  }

  Future<AppState> _currentState() async {
    final value = state.valueOrNull;
    if (value != null) {
      return value;
    }

    return future;
  }

  List<DailyPrayerLog> _replaceLogByDate(
    List<DailyPrayerLog> existingLogs,
    DailyPrayerLog newLog,
  ) {
    final keyDate = DateTime(
      newLog.date.year,
      newLog.date.month,
      newLog.date.day,
    );

    final filtered = existingLogs.where((log) {
      final currentDate = DateTime(log.date.year, log.date.month, log.date.day);
      return currentDate != keyDate;
    });

    final result = [...filtered, newLog];
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}

/// Main provider for full application state.
final appStateNotifierProvider =
    AsyncNotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);
