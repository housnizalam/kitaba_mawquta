import 'prayer_time_entry.dart';

/// Represents the full list of prayer entries for one day.
class DailyPrayerSchedule {
  final DateTime date;
  final List<PrayerTimeEntry> prayers;

  const DailyPrayerSchedule({required this.date, required this.prayers});

  DailyPrayerSchedule copyWith({
    DateTime? date,
    List<PrayerTimeEntry>? prayers,
  }) {
    return DailyPrayerSchedule(
      date: date ?? this.date,
      prayers: prayers ?? this.prayers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'prayers': prayers.map((entry) => entry.toMap()).toList(),
    };
  }

  factory DailyPrayerSchedule.fromMap(Map<String, dynamic> map) {
    final rawPrayers = map['prayers'] as List<dynamic>? ?? const [];

    return DailyPrayerSchedule(
      date:
          DateTime.tryParse(map['date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      prayers: rawPrayers
          .map(
            (item) =>
                PrayerTimeEntry.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}
