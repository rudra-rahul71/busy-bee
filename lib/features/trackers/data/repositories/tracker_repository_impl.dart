import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../models/tracker.dart';
import '../../../../models/tracker_history.dart';
import '../../domain/repositories/tracker_repository.dart';

/// Concrete implementation of [TrackerRepository] backed by [TypedCollection].
class TrackerRepositoryImpl implements TrackerRepository {
  final TypedCollection<Tracker> _trackerCollection;
  final TypedCollection<TrackerHistory> _trackerHistoryCollection;
  final AuthRepository _authRepository;

  TrackerRepositoryImpl({
    required this._trackerCollection,
    required this._trackerHistoryCollection,
    required this._authRepository,
  });

  @override
  Stream<List<Tracker>> watchTrackers() {
    return _trackerCollection.watch();
  }

  @override
  Stream<List<TrackerHistory>> watchTrackerHistoryWindow(DateTime monthDate) {
    final normalizedMonth = monthDate.monthOnly;
    final startOfWindow = normalizedMonth.subtractDays(7);
    final endOfWindow = DateTime(
      normalizedMonth.year,
      normalizedMonth.month + 1,
      0,
      23,
      59,
      59,
    ).addDays(7);

    return _trackerHistoryCollection.watch(
      filters: [
        QueryFilter.gte('date', startOfWindow),
        QueryFilter.lte('date', endOfWindow),
      ],
    );
  }

  @override
  Future<void> createTracker(Tracker tracker) async {
    await _trackerCollection.save(tracker, tracker.id);
  }

  @override
  Future<void> updateTracker(Tracker tracker) async {
    await _trackerCollection.save(tracker, tracker.id);
  }

  @override
  Future<void> deleteTracker(String trackerId) async {
    await _trackerCollection.delete(trackerId);
  }

  @override
  Future<void> logCompletion({
    required String trackerId,
    required DateTime date,
    double? value,
  }) async {
    final user = _authRepository.currentUser;
    final history = TrackerHistory(
      id: const Uuid().v4(),
      userId: user?.uid ?? '',
      trackerId: trackerId,
      date: date.dateOnly,
      type: 'completion',
      value: value,
    );
    await _trackerHistoryCollection.save(history, history.id);
  }

  @override
  Future<void> logSlipUp({
    required String trackerId,
    required DateTime date,
    double? value,
  }) async {
    final user = _authRepository.currentUser;
    final history = TrackerHistory(
      id: const Uuid().v4(),
      userId: user?.uid ?? '',
      trackerId: trackerId,
      date: date.dateOnly,
      type: 'slip_up',
      value: value,
    );
    await _trackerHistoryCollection.save(history, history.id);
  }
}
