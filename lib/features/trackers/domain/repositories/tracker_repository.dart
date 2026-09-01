import '../../../../models/tracker.dart';
import '../../../../models/tracker_history.dart';

/// Abstract repository contract defining data and domain operations for Habit Trackers.
abstract class TrackerRepository {
  /// Stream the live list of user habit trackers.
  Stream<List<Tracker>> watchTrackers();

  /// Stream habit history within a bounded calendar window for visualization.
  Stream<List<TrackerHistory>> watchTrackerHistoryWindow(DateTime monthDate);

  /// Create a new tracker.
  Future<void> createTracker(Tracker tracker);

  /// Update an existing tracker.
  Future<void> updateTracker(Tracker tracker);

  /// Delete a tracker and its associated history.
  Future<void> deleteTracker(String trackerId);

  /// Log a habit completion for a specific date.
  Future<void> logCompletion({
    required String trackerId,
    required DateTime date,
    double? value,
  });

  /// Log a habit slip-up for a specific date.
  Future<void> logSlipUp({
    required String trackerId,
    required DateTime date,
    double? value,
  });
}
