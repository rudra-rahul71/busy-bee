import 'package:flutter_test/flutter_test.dart';
import 'package:busy_bee/core/utils/date_utils.dart';
import 'package:busy_bee/models/tracker.dart';
import 'package:busy_bee/models/tracker_history.dart';
import 'package:busy_bee/models/task.dart';
import 'package:busy_bee/features/home/domain/models/day_data.dart';
import 'package:busy_bee/features/trackers/domain/tracker_calculator.dart';

void main() {
  group('AppDateParser & DateUtilsExtension Tests', () {
    test('parseDateOnly parses YYYY-MM-DD string into local midnight', () {
      final parsed = AppDateParser.parseDateOnly('2026-09-01');
      expect(parsed.year, equals(2026));
      expect(parsed.month, equals(9));
      expect(parsed.day, equals(1));
      expect(parsed.isUtc, isFalse);
    });

    test('formatDateOnly formats date into YYYY-MM-DD string', () {
      final date = DateTime(2026, 9, 1, 23, 59, 59);
      expect(AppDateParser.formatDateOnly(date), equals('2026-09-01'));
    });

    test('parseNullableDateOnly handles null safely', () {
      expect(AppDateParser.parseNullableDateOnly(null), isNull);
    });
  });

  group('Tracker and TrackerHistory Serialization Tests', () {
    test('Tracker round-trips correctly with Postgres DATE fields', () {
      final json = {
        'id': 'tracker-123',
        'userId': 'user-abc',
        'summary': 'Morning Run',
        'trackerType': 'maintain',
        'rrule': 'FREQ=DAILY',
        'ruleStartDate': '2026-09-01',
        'ruleEndDate': '2026-10-01',
        'currentStreak': 5,
        'longestStreak': 10,
        'lastEventDate': '2026-09-01',
        'createdAt': '2026-09-01T00:00:00.000Z',
        'updatedAt': '2026-09-01T00:00:00.000Z',
      };

      final tracker = Tracker.fromJson(json);
      expect(tracker.id, equals('tracker-123'));
      expect(tracker.ruleStartDate.year, equals(2026));
      expect(tracker.ruleStartDate.month, equals(9));
      expect(tracker.ruleStartDate.day, equals(1));
      expect(tracker.ruleEndDate?.day, equals(1));

      final serialized = tracker.toJson();
      expect(serialized['ruleStartDate'], equals('2026-09-01'));
      expect(serialized['ruleEndDate'], equals('2026-10-01'));
      expect(serialized['lastEventDate'], equals('2026-09-01'));
    });

    test('TrackerHistory serializes date as pure YYYY-MM-DD', () {
      final history = TrackerHistory(
        id: 'hist-1',
        userId: 'user-abc',
        trackerId: 'tracker-123',
        date: DateTime(2026, 9, 1),
        type: 'completion',
      );

      final json = history.toJson();
      expect(json['date'], equals('2026-09-01'));
      expect(json['type'], equals('completion'));

      final parsed = TrackerHistory.fromJson(json);
      expect(parsed.date.year, equals(2026));
      expect(parsed.date.month, equals(9));
      expect(parsed.date.day, equals(1));
    });

    test('DayData holds strongly typed Task objects', () {
      final task = Task(
        id: 'task-1',
        userId: 'user-abc',
        summary: 'Review Code',
        steps: [],
        status: 'COMPLETED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dayData = DayData(tasks: [task], trackers: []);
      expect(dayData.tasks.first.summary, equals('Review Code'));
      expect(dayData.tasks.first.status, equals('COMPLETED'));
    });
  });

  group('TrackerCalculator.getFormattedStreak Tests', () {
    test(
      'returns "Last Day!" when 0 days remaining on a set duration card',
      () {
        final tracker = Tracker(
          id: 't-1',
          userId: 'u-1',
          summary: '30-day Challenge',
          trackerType: 'maintain',
          ruleStartDate: DateTime(2026, 8, 3),
          ruleEndDate: DateTime(2026, 9, 2),
          createdAt: DateTime(2026, 8, 3),
          updatedAt: DateTime(2026, 8, 3),
        );

        final now = DateTime(2026, 9, 2, 14, 30);
        final text = TrackerCalculator.getFormattedStreak(
          tracker: tracker,
          now: now,
        );
        expect(text, equals('Last Day!'));
      },
    );

    test(
      'returns remaining days when > 0 days remaining on a set duration card',
      () {
        final tracker = Tracker(
          id: 't-2',
          userId: 'u-1',
          summary: '30-day Challenge',
          trackerType: 'maintain',
          ruleStartDate: DateTime(2026, 8, 3),
          ruleEndDate: DateTime(2026, 9, 6),
          createdAt: DateTime(2026, 8, 3),
          updatedAt: DateTime(2026, 8, 3),
        );

        final now = DateTime(2026, 9, 2, 10, 0);
        final text = TrackerCalculator.getFormattedStreak(
          tracker: tracker,
          now: now,
        );
        expect(text, equals('3 days remaining'));
      },
    );

    test(
      'returns "1 day remaining" when 1 day left on a set duration card',
      () {
        final tracker = Tracker(
          id: 't-3',
          userId: 'u-1',
          summary: '30-day Challenge',
          trackerType: 'maintain',
          ruleStartDate: DateTime(2026, 8, 3),
          ruleEndDate: DateTime(2026, 9, 3),
          createdAt: DateTime(2026, 8, 3),
          updatedAt: DateTime(2026, 8, 3),
        );

        final now = DateTime(2026, 9, 1, 10, 0);
        final text = TrackerCalculator.getFormattedStreak(
          tracker: tracker,
          now: now,
        );
        expect(text, equals('1 day remaining'));
      },
    );

    test('returns streak for indefinite cards (ruleEndDate == null)', () {
      final tracker = Tracker(
        id: 't-4',
        userId: 'u-1',
        summary: 'Daily Meditation',
        trackerType: 'maintain',
        ruleStartDate: DateTime(2026, 8, 1),
        currentStreak: 5,
        lastEventDate: DateTime(2026, 9, 2),
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      final now = DateTime(2026, 9, 2);
      final text = TrackerCalculator.getFormattedStreak(
        tracker: tracker,
        now: now,
      );
      expect(text, equals('5 days'));
    });
  });
}
