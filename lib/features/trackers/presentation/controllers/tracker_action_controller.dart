import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../models/tracker.dart';
import '../../../../models/tracker_history.dart';
import '../../data/tracker_providers.dart';

class TrackerActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addTracker(Tracker tracker) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final collection = ref.read(trackerCollectionProvider);
      await collection.save(tracker, tracker.id);
    });
  }

  Future<void> updateTracker(Tracker tracker) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final collection = ref.read(trackerCollectionProvider);
      await collection.save(tracker, tracker.id);
    });
  }

  Future<void> deleteTracker(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final collection = ref.read(trackerCollectionProvider);
      await collection.delete(id);
    });
  }

  Future<void> logHistory(TrackerHistory history) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final collection = ref.read(trackerHistoryCollectionProvider);
      await collection.save(history, history.id);
    });
  }
}

final trackerActionControllerProvider =
    AsyncNotifierProvider<TrackerActionController, void>(
      TrackerActionController.new,
    );
