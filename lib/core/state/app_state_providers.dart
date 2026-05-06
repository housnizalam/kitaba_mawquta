import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'app_state_notifier.dart';

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

  final now = DateTime.now();
  for (final prayer in appState.todaySchedule.prayers) {
    final hasStarted = !now.isBefore(prayer.startTime);
    final hasNotEnded = now.isBefore(prayer.endTime);
    if (hasStarted && hasNotEnded) {
      return prayer.prayerType;
    }
  }

  return null;
});
