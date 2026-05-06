import '../models/models.dart';

/// Runtime prayer state used by logic helpers.
enum PrayerRuntimeStatus { notStarted, active, prayed, missed }

/// Contains pure local business logic for prayer state transitions.
class PrayerLogicService {
  /// Resolves runtime status for a prayer entry based on current time and data.
  PrayerRuntimeStatus determinePrayerRuntimeStatus(
    PrayerTimeEntry entry,
    DateTime now,
  ) {
    if (entry.prayedAt != null) {
      return PrayerRuntimeStatus.prayed;
    }

    if (now.isBefore(entry.startTime)) {
      return PrayerRuntimeStatus.notStarted;
    }

    final isAfterOrEqualStart =
        now.isAtSameMomentAs(entry.startTime) || now.isAfter(entry.startTime);
    final isBeforeOrEqualEnd =
        now.isAtSameMomentAs(entry.endTime) || now.isBefore(entry.endTime);

    if (isAfterOrEqualStart && isBeforeOrEqualEnd) {
      return PrayerRuntimeStatus.active;
    }

    return PrayerRuntimeStatus.missed;
  }

  /// Synchronizes persisted prayer completion status from runtime rules.
  PrayerTimeEntry synchronizePrayerEntry(PrayerTimeEntry entry, DateTime now) {
    final runtimeStatus = determinePrayerRuntimeStatus(entry, now);

    switch (runtimeStatus) {
      case PrayerRuntimeStatus.prayed:
        return entry.copyWith(status: PrayerCompletionStatus.prayed);
      case PrayerRuntimeStatus.missed:
        return entry.copyWith(status: PrayerCompletionStatus.missed);
      case PrayerRuntimeStatus.notStarted:
      case PrayerRuntimeStatus.active:
        return entry.copyWith(status: PrayerCompletionStatus.pending);
    }
  }

  /// Synchronizes all prayer entries for one day schedule.
  DailyPrayerSchedule synchronizeDayPrayerStatuses(
    DailyPrayerSchedule schedule,
    DateTime now,
  ) {
    final synchronizedPrayers = schedule.prayers
        .map((entry) => synchronizePrayerEntry(entry, now))
        .toList();

    return schedule.copyWith(prayers: synchronizedPrayers);
  }

  /// Marks a prayer as completed now.
  PrayerTimeEntry markPrayerAsPrayed(PrayerTimeEntry entry, DateTime now) {
    return entry.copyWith(status: PrayerCompletionStatus.prayed, prayedAt: now);
  }

  /// Records reminder metadata after a reminder was triggered.
  PrayerTimeEntry recordReminderSent(PrayerTimeEntry entry, DateTime now) {
    return entry.copyWith(
      remindersSentCount: entry.remindersSentCount + 1,
      lastReminderAt: now,
    );
  }

  /// Returns the active prayer entry for now, if any.
  PrayerTimeEntry? getCurrentActivePrayerEntry(
    DailyPrayerSchedule schedule,
    DateTime now,
  ) {
    for (final entry in schedule.prayers) {
      final runtimeStatus = determinePrayerRuntimeStatus(entry, now);
      if (runtimeStatus == PrayerRuntimeStatus.active) {
        return entry;
      }
    }

    return null;
  }

  /// Returns the next upcoming prayer entry for now, if any.
  PrayerTimeEntry? getNextUpcomingPrayerEntry(
    DailyPrayerSchedule schedule,
    DateTime now,
  ) {
    final upcoming = schedule.prayers
        .where((entry) => now.isBefore(entry.startTime))
        .toList();

    if (upcoming.isEmpty) {
      return null;
    }

    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming.first;
  }

  /// Returns the countdown end time for the current active prayer.
  DateTime? getCountdownEndTimeForCurrentPrayer(
    DailyPrayerSchedule schedule,
    DateTime now,
  ) {
    return getCurrentActivePrayerEntry(schedule, now)?.endTime;
  }

  /// Updates one prayer in schedule using a transform callback.
  DailyPrayerSchedule updatePrayerInSchedule(
    DailyPrayerSchedule schedule,
    PrayerType prayerType,
    PrayerTimeEntry Function(PrayerTimeEntry entry) transform,
  ) {
    final updatedPrayers = schedule.prayers.map((entry) {
      if (entry.prayerType != prayerType) {
        return entry;
      }

      return transform(entry);
    }).toList();

    return schedule.copyWith(prayers: updatedPrayers);
  }
}
