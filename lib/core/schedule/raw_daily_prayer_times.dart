/// Raw prayer times for a single day, received before schedule creation.
///
/// Each field represents the start time of that prayer.
/// Calculating end times (= next prayer's start) is handled by
/// [PrayerScheduleBuilderService].
class RawDailyPrayerTimes {
  final DateTime date;
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const RawDailyPrayerTimes({
    required this.date,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  RawDailyPrayerTimes copyWith({
    DateTime? date,
    DateTime? fajr,
    DateTime? dhuhr,
    DateTime? asr,
    DateTime? maghrib,
    DateTime? isha,
  }) {
    return RawDailyPrayerTimes(
      date: date ?? this.date,
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'fajr': fajr.toIso8601String(),
      'dhuhr': dhuhr.toIso8601String(),
      'asr': asr.toIso8601String(),
      'maghrib': maghrib.toIso8601String(),
      'isha': isha.toIso8601String(),
    };
  }

  factory RawDailyPrayerTimes.fromMap(Map<String, dynamic> map) {
    DateTime parseField(String key) =>
        DateTime.tryParse(map[key] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return RawDailyPrayerTimes(
      date: parseField('date'),
      fajr: parseField('fajr'),
      dhuhr: parseField('dhuhr'),
      asr: parseField('asr'),
      maghrib: parseField('maghrib'),
      isha: parseField('isha'),
    );
  }
}
