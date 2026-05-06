import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'app_state_notifier.dart';
import 'storage_service_providers.dart';

/// Convenience provider for app settings.
final settingsProvider = Provider<AppSettings?>((ref) {
  return ref.watch(appStateNotifierProvider).valueOrNull?.settings;
});

/// Convenience provider for user location.
final locationProvider = Provider<UserLocationData?>((ref) {
  return ref.watch(appStateNotifierProvider).valueOrNull?.location;
});

/// Convenience provider for current day schedule.
final todayScheduleProvider = Provider<DailyPrayerSchedule?>((ref) {
  return ref.watch(appStateNotifierProvider).valueOrNull?.todaySchedule;
});

/// Convenience provider for current tracking state.
final trackingProvider = Provider<PrayerTrackingState?>((ref) {
  return ref.watch(appStateNotifierProvider).valueOrNull?.tracking;
});

/// Convenience provider for historical logs.
final historyProvider = Provider<List<DailyPrayerLog>>((ref) {
  return ref.watch(appStateNotifierProvider).valueOrNull?.history ?? const [];
});

/// Currently selected date for reusable day-details view.
final selectedDateProvider = Provider<DateTime>((ref) {
  final appState = ref.watch(appStateNotifierProvider).valueOrNull;
  final now = DateTime.now();
  return appState?.selectedDate ?? DateTime(now.year, now.month, now.day);
});

/// True when [selectedDateProvider] is today.
final isSelectedDateTodayProvider = Provider<bool>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return _dayOnly(selectedDate) == today;
});

/// Prayer entries for the currently selected date.
///
/// Uses today's schedule if selectedDate is today, otherwise resolves from
/// historical logs.
final selectedDatePrayerEntriesProvider = Provider<List<PrayerTimeEntry>>((
  ref,
) {
  final selectedDate = _dayOnly(ref.watch(selectedDateProvider));
  final isToday = ref.watch(isSelectedDateTodayProvider);

  if (isToday) {
    return ref.watch(todayScheduleProvider)?.prayers ?? const [];
  }

  final history = ref.watch(historyProvider);
  for (final log in history) {
    if (_dayOnly(log.date) == selectedDate) {
      return log.prayers;
    }
  }

  return const [];
});

/// Earliest day that has any prayer data in history/today schedule.
final earliestUsageDayProvider = Provider<DateTime?>((ref) {
  final history = ref.watch(historyProvider);
  final todaySchedule = ref.watch(todayScheduleProvider);

  DateTime? earliest;
  for (final log in history) {
    final day = _dayOnly(log.date);
    if (earliest == null || day.isBefore(earliest)) {
      earliest = day;
    }
  }

  if (todaySchedule != null && todaySchedule.prayers.isNotEmpty) {
    final day = _dayOnly(todaySchedule.date);
    if (earliest == null || day.isBefore(earliest)) {
      earliest = day;
    }
  }

  return earliest;
});

/// True when the user has already completed onboarding (settings exist in
/// storage). Null / false while still loading. Used by [AppRouter] to decide
/// whether to show [OnboardingPage] or [HomePage] on startup.
final hasPersistedSettingsProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(appSettingsStorageServiceProvider);
  final settings = await service.loadSettings();
  return settings != null;
});

/// Current active prayer entry derived from today's schedule.
final currentActivePrayerEntryProvider = Provider<PrayerTimeEntry?>((ref) {
  final appState = ref.watch(appStateNotifierProvider).valueOrNull;
  if (appState == null) {
    return null;
  }

  final prayerLogic = ref.watch(prayerLogicServiceProvider);
  return prayerLogic.getCurrentActivePrayerEntry(
    appState.todaySchedule,
    DateTime.now(),
  );
});

/// Next upcoming prayer entry derived from today's schedule.
final nextUpcomingPrayerEntryProvider = Provider<PrayerTimeEntry?>((ref) {
  final appState = ref.watch(appStateNotifierProvider).valueOrNull;
  if (appState == null) {
    return null;
  }

  final prayerLogic = ref.watch(prayerLogicServiceProvider);
  return prayerLogic.getNextUpcomingPrayerEntry(
    appState.todaySchedule,
    DateTime.now(),
  );
});

/// Countdown end time for the currently active prayer.
final currentPrayerCountdownEndProvider = Provider<DateTime?>((ref) {
  final appState = ref.watch(appStateNotifierProvider).valueOrNull;
  if (appState == null) {
    return null;
  }

  final prayerLogic = ref.watch(prayerLogicServiceProvider);
  return prayerLogic.getCountdownEndTimeForCurrentPrayer(
    appState.todaySchedule,
    DateTime.now(),
  );
});

/// Tries to derive the current prayer from tracking or today's schedule.
final currentPrayerProvider = Provider<PrayerType?>((ref) {
  final appState = ref.watch(appStateNotifierProvider).valueOrNull;
  if (appState == null) {
    return null;
  }

  final fromTracking = appState.tracking.currentPrayerType;
  if (fromTracking != null) {
    return fromTracking;
  }

  return ref.watch(currentActivePrayerEntryProvider)?.prayerType;
});

DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);
