/// Shared key values and key builders used in Hive boxes.
abstract final class StorageKeyHelpers {
  static const String singleRecordKey = 'value';

  /// Builds a stable day key like 2026-05-06.
  static String dayKey(DateTime date) {
    final safeDate = DateTime(date.year, date.month, date.day);
    final month = safeDate.month.toString().padLeft(2, '0');
    final day = safeDate.day.toString().padLeft(2, '0');
    return '${safeDate.year}-$month-$day';
  }
}
