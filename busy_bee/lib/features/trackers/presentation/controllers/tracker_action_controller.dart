import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../models/tracker.dart';
import '../../data/tracker_providers.dart';

/// Scoped controller per [trackerId] so UI actions on one card don't lock or trigger errors on others.
class TrackerActionController extends AsyncNotifier<void> {
  final String trackerId;

  TrackerActionController(this.trackerId);

  @override
  FutureOr<void> build() {}

  Future<void> logCompletion(DateTime date, {double? value}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.logCompletion(
        trackerId: trackerId,
        date: date,
        value: value,
      );
    });
  }

  Future<void> logSlipUp(DateTime date, {double? value}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.logSlipUp(
        trackerId: trackerId,
        date: date,
        value: value,
      );
    });
  }

  Future<void> deleteTracker() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.deleteTracker(trackerId);
    });
  }
}

final trackerActionControllerProvider =
    AsyncNotifierProvider.family<TrackerActionController, void, String>(
      TrackerActionController.new,
    );

/// Form controller for tracker creation and updates.
class TrackerFormController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createTracker(Tracker tracker) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.createTracker(tracker);
    });
  }

  Future<void> updateTracker(Tracker tracker) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.updateTracker(tracker);
    });
  }
}

final trackerFormControllerProvider =
    AsyncNotifierProvider<TrackerFormController, void>(
      TrackerFormController.new,
    );
