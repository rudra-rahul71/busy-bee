import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../models/tracker.dart';
import '../../../../models/tracker_history.dart';
import '../domain/tracker_calculator.dart';

final trackerCollectionProvider = Provider<TypedCollection<Tracker>>((ref) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return TypedCollection<Tracker>(
    repo: dbRepo,
    collectionName: 'trackers',
    toMap: (tracker) => tracker.toJson(),
    fromMap: (map, id) => Tracker.fromJson({...map, 'id': id}),
  );
});

final trackersStreamProvider = StreamProvider<List<Tracker>>((ref) {
  final collection = ref.watch(trackerCollectionProvider);
  return collection.watch();
});

final trackerByIdProvider = Provider.family<Tracker?, String>((ref, trackerId) {
  final trackersAsync = ref.watch(trackersStreamProvider);
  final trackers = trackersAsync.value ?? [];
  final matches = trackers.where((t) => t.id == trackerId);
  return matches.isNotEmpty ? matches.first : null;
});

final trackerHistoryCollectionProvider =
    Provider<TypedCollection<TrackerHistory>>((ref) {
      final dbRepo = ref.watch(databaseRepositoryProvider);
      return TypedCollection<TrackerHistory>(
        repo: dbRepo,
        collectionName: 'tracker_history',
        toMap: (history) => history.toJson(),
        fromMap: (map, id) => TrackerHistory.fromJson({...map, 'id': id}),
      );
    });

final trackerStreakProvider = Provider.family<int, Tracker>((ref, tracker) {
  return TrackerCalculator.calculateStreak(tracker: tracker);
});

/// Single aggregated stream for the user's tracker history.
final allTrackerHistoryStreamProvider = StreamProvider<List<TrackerHistory>>((
  ref,
) {
  final collection = ref.watch(trackerHistoryCollectionProvider);
  return collection.watch();
});

/// Bounded monthly stream provider for calendar and history visualization.
/// Limits data transfer to the specified month's window.
final monthlyTrackerHistoryStreamProvider =
    StreamProvider.family<List<TrackerHistory>, DateTime>((ref, monthDate) {
      final collection = ref.watch(trackerHistoryCollectionProvider);
      final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final endOfMonth = DateTime(
        monthDate.year,
        monthDate.month + 1,
        0,
        23,
        59,
        59,
      );

      return collection.watch(
        filters: [
          QueryFilter.gte('date', startOfMonth),
          QueryFilter.lte('date', endOfMonth),
        ],
      );
    });

/// Pre-indexes tracker history grouped by trackerId in memory.
final trackerHistoryByTrackerIdProvider =
    Provider<Map<String, List<TrackerHistory>>>((ref) {
      final historyAsync = ref.watch(allTrackerHistoryStreamProvider);
      final historyList = historyAsync.value ?? [];
      final map = <String, List<TrackerHistory>>{};
      for (final item in historyList) {
        map.putIfAbsent(item.trackerId, () => []).add(item);
      }
      return map;
    });

/// Pre-indexes tracker history into a quick O(1) lookup map of `"{trackerId}_{dateKey}" -> Set<String>`.
final trackerHistoryLookupMapProvider = Provider<Map<String, Set<String>>>((
  ref,
) {
  final historyAsync = ref.watch(allTrackerHistoryStreamProvider);
  final historyList = historyAsync.value ?? [];
  final map = <String, Set<String>>{};
  for (final item in historyList) {
    final key = "${item.trackerId}_${item.date.dateKey}";
    map.putIfAbsent(key, () => {}).add(item.type);
  }
  return map;
});
