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

  /// Applies a manual correction to one prayer entry.
  ///
  /// Validation rule:
  /// - If status is prayed, [prayedAt] must be inside the prayer window
  ///   (startTime <= prayedAt <= endTime).
  PrayerTimeEntry applyManualPrayerCorrection(
    PrayerTimeEntry entry, {
    required PrayerCompletionStatus status,
    required DateTime now,
    DateTime? prayedAt,
  }) {
    if (now.isBefore(entry.startTime)) {
      throw ArgumentError('Future prayers cannot be edited yet.');
    }

    if (status == PrayerCompletionStatus.pending) {
      throw ArgumentError(
        'Pending is not allowed for manual correction. Choose prayed or missed.',
      );
    }

    if (status == PrayerCompletionStatus.prayed) {
      if (prayedAt == null) {
        throw ArgumentError('Prayed time is required when status is prayed.');
      }

      final isBeforeStart = prayedAt.isBefore(entry.startTime);
      final isAfterEnd = prayedAt.isAfter(entry.endTime);
      if (isBeforeStart || isAfterEnd) {
        throw ArgumentError('Prayed time must be within the prayer window.');
      }

      if (prayedAt.isAfter(now)) {
        throw ArgumentError('Prayed time cannot be in the future.');
      }

      return entry.copyWith(
        status: PrayerCompletionStatus.prayed,
        prayedAt: prayedAt,
      );
    }

    return entry.copyWith(status: status, clearPrayedAt: true);
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
