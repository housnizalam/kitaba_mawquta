import 'prayer_time_entry.dart';

/// Represents one saved day in historical prayer logs.
class DailyPrayerLog {
  final DateTime date;
  final List<PrayerTimeEntry> prayers;

  const DailyPrayerLog({required this.date, required this.prayers});

  DailyPrayerLog copyWith({DateTime? date, List<PrayerTimeEntry>? prayers}) {
    return DailyPrayerLog(
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

  factory DailyPrayerLog.fromMap(Map<String, dynamic> map) {
    final rawPrayers = map['prayers'] as List<dynamic>? ?? const [];

    return DailyPrayerLog(
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
