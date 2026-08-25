import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/day_data.dart';
import '../../../../models/tracker.dart';
import '../../../trackers/data/tracker_providers.dart';
import '../../../trackers/domain/tracker_calculator.dart';

class DailyDetailsWidget extends ConsumerWidget {
  final DateTime selectedDay;
  final DayData dayData;
  final bool isScrollable;
  final ScrollController? scrollController;

  const DailyDetailsWidget({
    super.key,
    required this.selectedDay,
    required this.dayData,
    this.isScrollable = true,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final formattedDate = DateFormat('EEEE, MMMM d').format(selectedDay);

    final successfulTrackers = <Tracker>[];
    final slippedTrackers = <Tracker>[];
    final pendingTrackers = <Tracker>[];

    final historyMap = ref.watch(trackerHistoryByTrackerIdProvider);

    for (final tracker in dayData.trackers) {
      final history = historyMap[tracker.id] ?? [];

      final isCompleted = TrackerCalculator.isCompletedOnDay(
        tracker: tracker,
        history: history,
        day: selectedDay,
      );
      final isSlip = TrackerCalculator.hasSlipUpOnDay(
        tracker: tracker,
        history: history,
        day: selectedDay,
      );
      final isPending = TrackerCalculator.isPendingOnDay(
        tracker: tracker,
        history: history,
        day: selectedDay,
      );

      if (isCompleted) {
        successfulTrackers.add(tracker);
      } else if (isSlip) {
        slippedTrackers.add(tracker);
      } else if (isPending) {
        pendingTrackers.add(tracker);
      }
    }

    final hasTasks = dayData.tasks.isNotEmpty;
    final hasTrackers =
        successfulTrackers.isNotEmpty ||
        pendingTrackers.isNotEmpty ||
        slippedTrackers.isNotEmpty;

    final listWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasTasks && !hasTrackers)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks or habits for this day.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (hasTasks) ...[
          // --- TASKS SECTION ---
          Text(
            'TODAY\'S TASKS',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ...dayData.tasks.map(
            (t) => ListTile(title: Text(t['name'] ?? 'Task')),
          ),

          if (hasTrackers)
            Divider(
              height: 48,
              thickness: 1,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
        ],

        if (hasTrackers) ...[
          // --- HABIT TRACKERS SECTION ---
          if (successfulTrackers.isNotEmpty) ...[
            Text(
              'SUCCESSFUL HABITS / CLEAN DAYS',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            ...successfulTrackers.map(
              (t) => _buildDetailItem(context, t, true),
            ),
          ],

          if (pendingTrackers.isNotEmpty) ...[
            if (successfulTrackers.isNotEmpty) const SizedBox(height: 24),
            Text(
              'PENDING HABITS',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            ...pendingTrackers.map((t) => _buildDetailItem(context, t, false)),
          ],

          if (slippedTrackers.isNotEmpty) ...[
            if (successfulTrackers.isNotEmpty || pendingTrackers.isNotEmpty)
              const SizedBox(height: 24),
            Text(
              'SLIPPED UP / BROKEN HABITS',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            ...slippedTrackers.map(
              (t) => _buildDetailItem(context, t, false, isSlip: true),
            ),
          ],
        ],
      ],
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      color: colorScheme.surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Habits & tasks completion details',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            Divider(
              height: 32,
              thickness: 1,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),

            if (isScrollable)
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: listWidget,
                ),
              )
            else
              listWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    Tracker tracker,
    bool isCompleted, {
    bool isSlip = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = tracker.trackerType == 'quit'
        ? colorScheme.error
        : colorScheme.tertiary;

    final slipColor = colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSlip
              ? slipColor.withValues(alpha: 0.3)
              : isCompleted
              ? color.withValues(alpha: 0.3)
              : colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  isSlip
                      ? Icons.cancel_outlined
                      : isCompleted
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: isSlip
                      ? slipColor
                      : isCompleted
                      ? color
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tracker.summary,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tracker.trackerType == 'quit' ? 'Quit' : 'Maintain',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
