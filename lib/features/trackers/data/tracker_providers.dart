import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../models/tracker.dart';
import '../../../../models/tracker_history.dart';
import '../domain/repositories/tracker_repository.dart';
import 'repositories/tracker_repository_impl.dart';

final trackerCollectionProvider = Provider<TypedCollection<Tracker>>((ref) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return TypedCollection<Tracker>(
    repo: dbRepo,
    collectionName: 'trackers',
    toMap: (tracker) => tracker.toJson(),
    fromMap: (map, id) => Tracker.fromJson({...map, 'id': id}),
  );
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

/// Provides the singleton [TrackerRepository] instance.
final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  return TrackerRepositoryImpl(
    trackerCollection: ref.watch(trackerCollectionProvider),
    trackerHistoryCollection: ref.watch(trackerHistoryCollectionProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

/// Live stream of all trackers for the current user.
final trackersStreamProvider = StreamProvider<List<Tracker>>((ref) {
  final repository = ref.watch(trackerRepositoryProvider);
  return repository.watchTrackers();
});

/// Bounded window stream provider for calendar and history visualization.
/// Captures the specified month plus the previous week and next week to catch calendar overflow.
final calendarTrackerHistoryStreamProvider =
    StreamProvider.family<List<TrackerHistory>, DateTime>((ref, monthDate) {
      final repository = ref.watch(trackerRepositoryProvider);
      return repository.watchTrackerHistoryWindow(monthDate);
    });

/// Pre-indexes tracker history grouped by trackerId in memory for the bounded calendar window.
final calendarTrackerHistoryByTrackerIdProvider =
    Provider.family<Map<String, List<TrackerHistory>>, DateTime>((
      ref,
      monthDate,
    ) {
      final historyAsync = ref.watch(
        calendarTrackerHistoryStreamProvider(monthDate.monthOnly),
      );
      final historyList = historyAsync.value ?? [];
      final map = <String, List<TrackerHistory>>{};
      for (final item in historyList) {
        map.putIfAbsent(item.trackerId, () => []).add(item);
      }
      return map;
    });

/// Pre-indexes tracker history into a quick O(1) lookup map of `"{trackerId}_{dateKey}" -> Set<String>`
/// for the bounded calendar window.
final calendarTrackerHistoryLookupMapProvider =
    Provider.family<Map<String, Set<String>>, DateTime>((ref, monthDate) {
      final historyAsync = ref.watch(
        calendarTrackerHistoryStreamProvider(monthDate.monthOnly),
      );
      final historyList = historyAsync.value ?? [];
      final map = <String, Set<String>>{};
      for (final item in historyList) {
        final key = "${item.trackerId}_${item.date.dateKey}";
        map.putIfAbsent(key, () => {}).add(item.type);
      }
      return map;
    });
