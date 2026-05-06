import '../logic/prayer_logic_service.dart';
import '../models/models.dart';
import 'raw_daily_prayer_times.dart';

/// Builds a [DailyPrayerSchedule] from [RawDailyPrayerTimes].
///
/// This service does not perform astronomical calculations.
/// It assumes the raw times are already correct DateTime values for one day.
class PrayerScheduleBuilderService {
  final PrayerLogicService _prayerLogicService;

  PrayerScheduleBuilderService(this._prayerLogicService);

  /// Builds a full [DailyPrayerSchedule] from raw times.
  ///
  /// The provided [now] is used to set correct initial statuses on all entries.
  DailyPrayerSchedule buildSchedule(
    RawDailyPrayerTimes rawTimes, {
    required DateTime now,
  }) {
    final entries = _buildEntries(rawTimes);
    final schedule = DailyPrayerSchedule(
      date: _dayOnly(rawTimes.date),
      prayers: entries,
    );

    return _prayerLogicService.synchronizeDayPrayerStatuses(schedule, now);
  }

  /// Returns an empty schedule for a day with no prayers.
  ///
  /// Useful as a safe default on first startup when no times exist yet.
  DailyPrayerSchedule buildEmptySchedule({required DateTime date}) {
    return DailyPrayerSchedule(date: _dayOnly(date), prayers: const []);
  }

  List<PrayerTimeEntry> _buildEntries(RawDailyPrayerTimes rawTimes) {
    return [
      _buildEntry(
        prayerType: PrayerType.fajr,
        startTime: rawTimes.fajr,
        endTime: rawTimes.dhuhr,
      ),
      _buildEntry(
        prayerType: PrayerType.dhuhr,
        startTime: rawTimes.dhuhr,
        endTime: rawTimes.asr,
      ),
      _buildEntry(
        prayerType: PrayerType.asr,
        startTime: rawTimes.asr,
        endTime: rawTimes.maghrib,
      ),
      _buildEntry(
        prayerType: PrayerType.maghrib,
        startTime: rawTimes.maghrib,
        endTime: rawTimes.isha,
      ),
      _buildEntry(
        prayerType: PrayerType.isha,
        startTime: rawTimes.isha,
        // Temporary rule: Isha ends at midnight (23:59:59) of the same day.
        // This will be updated later when next-day Fajr integration is added.
        endTime: _endOfDay(rawTimes.date),
      ),
    ];
  }

  PrayerTimeEntry _buildEntry({
    required PrayerType prayerType,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return PrayerTimeEntry(
      prayerType: prayerType,
      startTime: startTime,
      endTime: endTime,
      status: PrayerCompletionStatus.pending,
      prayedAt: null,
      remindersSentCount: 0,
      lastReminderAt: null,
    );
  }

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  /// Returns 23:59:59 of the same date.
  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);
}
