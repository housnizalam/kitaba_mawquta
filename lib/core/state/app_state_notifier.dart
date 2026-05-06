import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/logic.dart';
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
    final prayerLogicService = ref.read(prayerLogicServiceProvider);

    final now = DateTime.now();

    final settings =
        await settingsService.loadSettings() ??
        AppStateDefaults.defaultSettings();
    final location =
        await locationService.loadLocation() ??
        AppStateDefaults.defaultLocation();
    final loadedSchedule =
        await scheduleService.loadTodaySchedule() ??
        AppStateDefaults.defaultTodaySchedule(now: now);
    final todaySchedule = prayerLogicService.synchronizeDayPrayerStatuses(
      loadedSchedule,
      now,
    );
    final history = await historyService.loadAllDailyLogs();

    await scheduleService.saveTodaySchedule(todaySchedule);

    final tracking = _buildTrackingFromSchedule(
      schedule: todaySchedule,
      currentTracking: AppStateDefaults.defaultTrackingState(),
      now: now,
      prayerLogicService: prayerLogicService,
    );

    return AppState(
      settings: settings,
      location: location,
      todaySchedule: todaySchedule,
      tracking: tracking,
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
    final prayerLogicService = ref.read(prayerLogicServiceProvider);
    final now = DateTime.now();

    final syncedSchedule = prayerLogicService.synchronizeDayPrayerStatuses(
      schedule,
      now,
    );

    await ref
        .read(todayScheduleStorageServiceProvider)
        .saveTodaySchedule(syncedSchedule);

    final tracking = _buildTrackingFromSchedule(
      schedule: syncedSchedule,
      currentTracking: current.tracking,
      now: now,
      prayerLogicService: prayerLogicService,
    );

    state = AsyncValue.data(
      current.copyWith(todaySchedule: syncedSchedule, tracking: tracking),
    );
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

  /// Synchronizes today's prayer statuses using current runtime rules.
  Future<void> synchronizeTodayPrayerStatuses({DateTime? now}) async {
    final current = await _currentState();
    final prayerLogicService = ref.read(prayerLogicServiceProvider);
    final effectiveNow = now ?? DateTime.now();

    final synchronizedSchedule = prayerLogicService
        .synchronizeDayPrayerStatuses(current.todaySchedule, effectiveNow);

    await ref
        .read(todayScheduleStorageServiceProvider)
        .saveTodaySchedule(synchronizedSchedule);

    final tracking = _buildTrackingFromSchedule(
      schedule: synchronizedSchedule,
      currentTracking: current.tracking,
      now: effectiveNow,
      prayerLogicService: prayerLogicService,
    );

    state = AsyncValue.data(
      current.copyWith(todaySchedule: synchronizedSchedule, tracking: tracking),
    );
  }

  /// Marks the selected prayer as prayed and persists updated schedule.
  Future<void> markPrayerAsPrayed(
    PrayerType prayerType, {
    DateTime? now,
  }) async {
    final current = await _currentState();
    final prayerLogicService = ref.read(prayerLogicServiceProvider);
    final effectiveNow = now ?? DateTime.now();

    final markedSchedule = prayerLogicService.updatePrayerInSchedule(
      current.todaySchedule,
      prayerType,
      (entry) => prayerLogicService.markPrayerAsPrayed(entry, effectiveNow),
    );

    final synchronizedSchedule = prayerLogicService
        .synchronizeDayPrayerStatuses(markedSchedule, effectiveNow);

    await ref
        .read(todayScheduleStorageServiceProvider)
        .saveTodaySchedule(synchronizedSchedule);

    final tracking = _buildTrackingFromSchedule(
      schedule: synchronizedSchedule,
      currentTracking: current.tracking,
      now: effectiveNow,
      prayerLogicService: prayerLogicService,
    );

    state = AsyncValue.data(
      current.copyWith(todaySchedule: synchronizedSchedule, tracking: tracking),
    );
  }

  /// Updates reminder metadata for one prayer and persists updated schedule.
  Future<void> recordReminderSentForPrayer(
    PrayerType prayerType, {
    DateTime? now,
  }) async {
    final current = await _currentState();
    final prayerLogicService = ref.read(prayerLogicServiceProvider);
    final effectiveNow = now ?? DateTime.now();

    final updatedSchedule = prayerLogicService.updatePrayerInSchedule(
      current.todaySchedule,
      prayerType,
      (entry) => prayerLogicService.recordReminderSent(entry, effectiveNow),
    );

    await ref
        .read(todayScheduleStorageServiceProvider)
        .saveTodaySchedule(updatedSchedule);

    final tracking = _buildTrackingFromSchedule(
      schedule: updatedSchedule,
      currentTracking: current.tracking,
      now: effectiveNow,
      prayerLogicService: prayerLogicService,
    );

    state = AsyncValue.data(
      current.copyWith(todaySchedule: updatedSchedule, tracking: tracking),
    );
  }

  /// Refreshes runtime tracking from the current schedule.
  Future<void> refreshTrackingFromTodaySchedule({DateTime? now}) async {
    final current = await _currentState();
    final prayerLogicService = ref.read(prayerLogicServiceProvider);
    final effectiveNow = now ?? DateTime.now();

    final tracking = _buildTrackingFromSchedule(
      schedule: current.todaySchedule,
      currentTracking: current.tracking,
      now: effectiveNow,
      prayerLogicService: prayerLogicService,
    );

    state = AsyncValue.data(current.copyWith(tracking: tracking));
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

  PrayerTrackingState _buildTrackingFromSchedule({
    required DailyPrayerSchedule schedule,
    required PrayerTrackingState currentTracking,
    required DateTime now,
    required PrayerLogicService prayerLogicService,
  }) {
    final activeEntry = prayerLogicService.getCurrentActivePrayerEntry(
      schedule,
      now,
    );

    final countdownEndsAt = prayerLogicService
        .getCountdownEndTimeForCurrentPrayer(schedule, now);

    return PrayerTrackingState(
      currentPrayerType: activeEntry?.prayerType,
      isReminderActive: activeEntry == null
          ? false
          : currentTracking.isReminderActive,
      nextReminderAt: activeEntry == null
          ? null
          : currentTracking.nextReminderAt,
      countdownEndsAt: countdownEndsAt,
    );
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
