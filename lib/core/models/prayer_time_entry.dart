import 'enums.dart';

/// Represents one prayer window and the user's completion info for it.
class PrayerTimeEntry {
  final PrayerType prayerType;
  final DateTime startTime;
  final DateTime endTime;
  final PrayerCompletionStatus status;
  final DateTime? prayedAt;
  final int remindersSentCount;
  final DateTime? lastReminderAt;

  const PrayerTimeEntry({
    required this.prayerType,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.prayedAt,
    required this.remindersSentCount,
    required this.lastReminderAt,
  });

  PrayerTimeEntry copyWith({
    PrayerType? prayerType,
    DateTime? startTime,
    DateTime? endTime,
    PrayerCompletionStatus? status,
    DateTime? prayedAt,
    bool clearPrayedAt = false,
    int? remindersSentCount,
    DateTime? lastReminderAt,
    bool clearLastReminderAt = false,
  }) {
    return PrayerTimeEntry(
      prayerType: prayerType ?? this.prayerType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      prayedAt: clearPrayedAt ? null : (prayedAt ?? this.prayedAt),
      remindersSentCount: remindersSentCount ?? this.remindersSentCount,
      lastReminderAt: clearLastReminderAt
          ? null
          : (lastReminderAt ?? this.lastReminderAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prayerType': prayerType.toMapValue(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.toMapValue(),
      'prayedAt': prayedAt?.toIso8601String(),
      'remindersSentCount': remindersSentCount,
      'lastReminderAt': lastReminderAt?.toIso8601String(),
    };
  }

  factory PrayerTimeEntry.fromMap(Map<String, dynamic> map) {
    return PrayerTimeEntry(
      prayerType: PrayerTypeMapX.fromMapValue(
        map['prayerType'] as String? ?? PrayerType.fajr.name,
      ),
      startTime:
          DateTime.tryParse(map['startTime'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endTime:
          DateTime.tryParse(map['endTime'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: PrayerCompletionStatusMapX.fromMapValue(
        map['status'] as String? ?? PrayerCompletionStatus.pending.name,
      ),
      prayedAt: DateTime.tryParse(map['prayedAt'] as String? ?? ''),
      remindersSentCount: map['remindersSentCount'] as int? ?? 0,
      lastReminderAt: DateTime.tryParse(map['lastReminderAt'] as String? ?? ''),
    );
  }
}
