import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rrule/rrule.dart';

import '../../../../core/utils/date_utils.dart';
import '../domain/models/day_data.dart';
import '../../trackers/data/tracker_providers.dart';

// Creates a Map of DateTime to DayData for efficient calendar lookups
final calendarDataProvider = Provider<Map<DateTime, DayData>>((ref) {
  final trackersAsync = ref.watch(trackersStreamProvider);
  final trackers = trackersAsync.value ?? [];

  final map = <DateTime, DayData>{};

  // Define a sensible expansion window (e.g. +/- 2 years)
  final now = DateTime.now();
  final windowStart = DateTime.utc(now.year - 2, 1, 1);
  final windowEnd = DateTime.utc(now.year + 2, 12, 31);

  for (final tracker in trackers) {
    try {
      final rruleString = tracker.rrule ?? 'FREQ=DAILY';
      // RRule string requires prefix RRULE: if passing full string, but RecurrenceRule.fromString handles it
      // if it has RRULE: or not depending on parsing. RecurrenceRule.fromString expects just FREQ=...
      String ruleToParse = rruleString;
      if (!ruleToParse.startsWith('RRULE:')) {
        ruleToParse = 'RRULE:$ruleToParse';
      }
      final rrule = RecurrenceRule.fromString(ruleToParse);

      final startDate = tracker.ruleStartDate.isUtc
          ? tracker.ruleStartDate
          : tracker.ruleStartDate.toUtc();

      final todayUtc = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
      final generationEnd = windowEnd.isBefore(todayUtc) ? windowEnd : todayUtc;

      final instances = rrule.getInstances(
        start: startDate,
        before: generationEnd,
      );

      for (final inst in instances) {
        if (inst.isBefore(windowStart)) continue;
        if (tracker.ruleEndDate != null && inst.isAfter(tracker.ruleEndDate!)) {
          continue;
        }

        final isExcluded = tracker.exdate.any((ex) => ex.isSameDay(inst));
        if (isExcluded) continue;

        // Normalize the date to local midnight for map keys
        final localDate = inst.dateOnly;
        final normalizedToday = now.dateOnly;

        // Trackers should only be displayed up to the current day
        if (localDate.isAfter(normalizedToday)) continue;

        final currentData = map[localDate] ?? const DayData();

        map[localDate] = DayData(
          tasks: currentData.tasks,
          trackers: [...currentData.trackers, tracker],
        );
      }
    } catch (e) {
      debugPrint('Failed to parse rrule for tracker ${tracker.id}: $e');
    }
  }

  return map;
});
