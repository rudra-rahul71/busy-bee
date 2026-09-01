/// Extensions on [DateTime] for common date manipulations and comparisons.
extension DateUtilsExtension on DateTime {
  /// Returns a new [DateTime] with time components set to zero (midnight in local time).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns a normalized [DateTime] representing the 1st day of the month.
  DateTime get monthOnly => DateTime(year, month, 1);

  /// Returns true if this date matches [other] in year, month, and day.
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns a standard key formatted as "yyyy-M-d" used for map indexing.
  String get dateKey => '$year-$month-$day';

  /// Returns standard PostgreSQL DATE format "YYYY-MM-DD".
  String get dbDateString =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// Calendar-safe previous day (avoids DST 23h/25h transition bugs).
  DateTime get previousDay => DateTime(year, month, day - 1);

  /// Calendar-safe next day (avoids DST 23h/25h transition bugs).
  DateTime get nextDay => DateTime(year, month, day + 1);

  /// Calendar-safe day subtraction.
  DateTime subtractDays(int days) => DateTime(year, month, day - days);

  /// Calendar-safe day addition.
  DateTime addDays(int days) => DateTime(year, month, day + days);
}

/// Timezone-safe date parser to prevent UTC-to-local midnight shifts
/// when consuming pure PostgreSQL `DATE` strings (YYYY-MM-DD).
class AppDateParser {
  AppDateParser._();

  /// Parses a pure calendar date (e.g. "2026-09-01" or DateTime) into local midnight (year, month, day).
  /// Avoids the UTC-to-local timezone shift bug where DateTime.parse("2026-09-01").toLocal()
  /// shifts UTC midnight into the previous day in Western timezones.
  static DateTime parseDateOnly(dynamic value) {
    if (value == null) return DateTime.now().dateOnly;
    if (value is DateTime) return DateTime(value.year, value.month, value.day);
    if (value is String) {
      final dateStr = value.split('T').first.trim();
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return DateTime.now().dateOnly;
  }

  /// Parses a nullable pure calendar date into local midnight (year, month, day).
  static DateTime? parseNullableDateOnly(dynamic value) {
    if (value == null) return null;
    return parseDateOnly(value);
  }

  /// Parses a full timestamp (TIMESTAMPTZ) and converts to local timezone.
  static DateTime parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }

  /// Parses a nullable full timestamp (TIMESTAMPTZ) and converts to local timezone.
  static DateTime? parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    return parseDateTime(value);
  }

  /// Formats a date into a standard Postgres `DATE` format "YYYY-MM-DD".
  static String formatDateOnly(DateTime date) => date.dbDateString;
}
