import '../../../../models/task.dart';
import '../../../../models/tracker.dart';

class DayData {
  final List<Task> tasks;
  final List<Tracker> trackers;

  const DayData({this.tasks = const [], this.trackers = const []});
}
