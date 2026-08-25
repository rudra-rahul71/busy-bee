/// Extensions on [DateTime] for common date manipulations and comparisons.
extension DateUtilsExtension on DateTime {
  /// Returns a new [DateTime] with time components set to zero (midnight in local time).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns true if this date matches [other] in year, month, and day.
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns a standard key formatted as "yyyy-M-d" used for map indexing.
  String get dateKey => '$year-$month-$day';

  /// Calendar-safe previous day (avoids DST 23h/25h transition bugs).
  DateTime get previousDay => DateTime(year, month, day - 1);

  /// Calendar-safe next day (avoids DST 23h/25h transition bugs).
  DateTime get nextDay => DateTime(year, month, day + 1);

  /// Calendar-safe day subtraction.
  DateTime subtractDays(int days) => DateTime(year, month, day - days);

  /// Calendar-safe day addition.
  DateTime addDays(int days) => DateTime(year, month, day + days);
}

/// Safely parses a dynamic database value into a local [DateTime].
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    return parsed?.toLocal();
  }
  return null;
}
