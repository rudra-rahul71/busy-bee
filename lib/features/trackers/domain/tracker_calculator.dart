import '../../../../core/utils/date_utils.dart';
import '../../../../models/tracker.dart';
import '../../../../models/tracker_history.dart';

/// Pure domain utility responsible for streak counting, progress interpolation,
/// and day completion status across habit trackers.
class TrackerCalculator {
  TrackerCalculator._();

  /// Calculates the active streak count (in days) in O(1) constant time.
  /// Uses the database counter cache and a temporal expiration check without looping history.
  static int calculateStreak({required Tracker tracker, DateTime? now}) {
    final currentNow = now ?? DateTime.now();
    final todayZero = currentNow.dateOnly;

    if (tracker.trackerType == 'quit') {
      final streakStart =
          tracker.lastSlipUpDate?.dateOnly ?? tracker.ruleStartDate.dateOnly;
      final streak = todayZero.difference(streakStart).inDays;
      return streak < 0 ? 0 : streak;
    } else {
      if (tracker.lastCompletedDate == null) return 0;
      final lastComp = tracker.lastCompletedDate!.dateOnly;

      // Active streak is valid only if completed today or yesterday
      if (lastComp.isSameDay(todayZero) ||
          lastComp.isSameDay(todayZero.previousDay)) {
        return tracker.currentStreak;
      }
      return 0;
    }
  }

  /// Calculates the progress ratio (0.0 to 1.0) for a tracker.
  static double calculateProgress({required Tracker tracker, DateTime? now}) {
    final currentNow = now ?? DateTime.now();
    final startDate = tracker.ruleStartDate;
    final endDate = tracker.ruleEndDate;
    final isQuit = tracker.trackerType == 'quit';

    if (endDate == null) {
      final minutesPassed = currentNow.hour * 60 + currentNow.minute;
      const totalMinutes = 24 * 60;
      if (!isQuit) {
        return 1.0 - (minutesPassed / totalMinutes).clamp(0.0, 1.0);
      } else {
        return (minutesPassed / totalMinutes).clamp(0.0, 1.0);
      }
    } else {
      final totalDays = endDate.difference(startDate).inDays;
      final daysElapsed = currentNow.difference(startDate).inDays;
      if (totalDays > 0) {
        return (daysElapsed / totalDays).clamp(0.0, 1.0);
      }
      return 1.0;
    }
  }

  /// Formats the current streak or time remaining for display on tracker cards.
  static String getFormattedStreak({required Tracker tracker, DateTime? now}) {
    final currentNow = now ?? DateTime.now();
    final endDate = tracker.ruleEndDate;

    if (endDate == null) {
      final streak = calculateStreak(tracker: tracker, now: currentNow);
      return '$streak day${streak == 1 ? '' : 's'}';
    } else {
      final daysRemaining = endDate.difference(currentNow).inDays;
      final remValue = daysRemaining < 0 ? 0 : daysRemaining;
      return '$remValue day${remValue == 1 ? '' : 's'} remaining';
    }
  }

  /// Checks if a tracker is completed on a specific day.
  static bool isCompletedOnDay({
    required Tracker tracker,
    required List<TrackerHistory> history,
    required DateTime day,
  }) {
    final dayZero = day.dateOnly;
    final isQuit = tracker.trackerType == 'quit';

    if (isQuit) {
      return !hasSlipUpOnDay(tracker: tracker, history: history, day: day);
    } else {
      return history.any(
        (h) => h.type == 'completion' && h.date.isSameDay(dayZero),
      );
    }
  }

  /// Checks if a tracker had a slip-up on a specific day.
  static bool hasSlipUpOnDay({
    required Tracker tracker,
    required List<TrackerHistory> history,
    required DateTime day,
  }) {
    final dayZero = day.dateOnly;
    final isQuit = tracker.trackerType == 'quit';

    if (isQuit) {
      return history.any(
        (h) => h.type == 'slip_up' && h.date.isSameDay(dayZero),
      );
    } else {
      final todayZero = DateTime.now().dateOnly;
      if (dayZero.isBefore(todayZero)) {
        return !isCompletedOnDay(tracker: tracker, history: history, day: day);
      }
      return false;
    }
  }

  /// Checks if a maintain tracker is still pending completion for today.
  static bool isPendingOnDay({
    required Tracker tracker,
    required List<TrackerHistory> history,
    required DateTime day,
    DateTime? now,
  }) {
    if (tracker.trackerType == 'quit') return false;

    final currentNow = now ?? DateTime.now();
    final dayZero = day.dateOnly;
    final todayZero = currentNow.dateOnly;

    if (dayZero.isAtSameMomentAs(todayZero) || dayZero.isAfter(todayZero)) {
      return !isCompletedOnDay(tracker: tracker, history: history, day: day);
    }
    return false;
  }
}
