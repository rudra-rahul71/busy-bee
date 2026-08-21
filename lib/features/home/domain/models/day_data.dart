import 'package:flutter/material.dart';

class DayData {
  final List<Map<String, dynamic>> tasks;
  final List<Color> trackers;

  const DayData({this.tasks = const [], this.trackers = const []});
}
