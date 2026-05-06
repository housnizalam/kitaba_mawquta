import 'enums.dart';

/// Holds runtime tracking information for reminders and active prayer state.
class PrayerTrackingState {
  final PrayerType? currentPrayerType;
  final bool isReminderActive;
  final DateTime? nextReminderAt;
  final DateTime? countdownEndsAt;

  const PrayerTrackingState({
    required this.currentPrayerType,
    required this.isReminderActive,
    required this.nextReminderAt,
    required this.countdownEndsAt,
  });

  PrayerTrackingState copyWith({
    PrayerType? currentPrayerType,
    bool clearCurrentPrayerType = false,
    bool? isReminderActive,
    DateTime? nextReminderAt,
    bool clearNextReminderAt = false,
    DateTime? countdownEndsAt,
    bool clearCountdownEndsAt = false,
  }) {
    return PrayerTrackingState(
      currentPrayerType: clearCurrentPrayerType
          ? null
          : (currentPrayerType ?? this.currentPrayerType),
      isReminderActive: isReminderActive ?? this.isReminderActive,
      nextReminderAt: clearNextReminderAt
          ? null
          : (nextReminderAt ?? this.nextReminderAt),
      countdownEndsAt: clearCountdownEndsAt
          ? null
          : (countdownEndsAt ?? this.countdownEndsAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentPrayerType': currentPrayerType?.toMapValue(),
      'isReminderActive': isReminderActive,
      'nextReminderAt': nextReminderAt?.toIso8601String(),
      'countdownEndsAt': countdownEndsAt?.toIso8601String(),
    };
  }

  factory PrayerTrackingState.fromMap(Map<String, dynamic> map) {
    final currentPrayerValue = map['currentPrayerType'] as String?;

    return PrayerTrackingState(
      currentPrayerType: currentPrayerValue == null
          ? null
          : PrayerTypeMapX.fromMapValue(currentPrayerValue),
      isReminderActive: map['isReminderActive'] as bool? ?? false,
      nextReminderAt: DateTime.tryParse(map['nextReminderAt'] as String? ?? ''),
      countdownEndsAt: DateTime.tryParse(
        map['countdownEndsAt'] as String? ?? '',
      ),
    );
  }
}
