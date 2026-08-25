import '../../../../models/tracker.dart';

class DayData {
  final List<Map<String, dynamic>> tasks;
  final List<Tracker> trackers;

  const DayData({this.tasks = const [], this.trackers = const []});
}
