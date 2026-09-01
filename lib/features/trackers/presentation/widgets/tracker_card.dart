import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../models/tracker.dart';
import '../../../../models/tracker_history.dart';
import '../../domain/tracker_calculator.dart';
import '../controllers/tracker_action_controller.dart';
import 'add_tracker_sheet.dart';

class TrackerCard extends ConsumerWidget {
  final Tracker tracker;

  const TrackerCard({super.key, required this.tracker});

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Delete Tracker',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${tracker.summary}"?',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(trackerActionControllerProvider.notifier)
                  .deleteTracker(tracker.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isQuit = tracker.trackerType == 'quit';
    final accentColor = isQuit ? colorScheme.error : colorScheme.tertiary;

    final now = DateTime.now();

    ref.listen<AsyncValue<void>>(trackerActionControllerProvider, (_, state) {
      if (!state.isLoading && state.hasError) {
        AppBannerService.showError(
          context,
          state.error.toString(),
          title: 'Action Failed',
        );
      }
    });

    final actionState = ref.watch(trackerActionControllerProvider);
    final isLoading = actionState.isLoading;

    // Fast-path O(1) status and streak retrieval via counter caches
    final isCompletedToday =
        !isQuit &&
        tracker.lastEventDate != null &&
        tracker.lastEventDate!.dateOnly.isSameDay(now.dateOnly);

    final isSlippedToday =
        isQuit &&
        tracker.lastEventDate != null &&
        tracker.lastEventDate!.dateOnly.isSameDay(now.dateOnly);

    final streakText = TrackerCalculator.getFormattedStreak(
      tracker: tracker,
      now: now,
    );

    final progressValue = TrackerCalculator.calculateProgress(
      tracker: tracker,
      now: now,
    );

    const periodName = 'today';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1.5),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Info and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isQuit
                              ? Icons.block_flipped
                              : Icons.check_circle_outline_rounded,
                          color: accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tracker.summary,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _buildBadge(
                                  isQuit ? 'Quitting' : 'Maintaining',
                                  accentColor.withValues(alpha: 0.15),
                                  accentColor,
                                ),
                                _buildBadge(
                                  tracker.ruleEndDate == null
                                      ? 'Indefinite'
                                      : 'Set Duration',
                                  colorScheme.onSurface.withValues(alpha: 0.06),
                                  colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      tooltip: 'Edit tracker',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              AddTrackerSheet(trackerToEdit: tracker),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: 22,
                      ),
                      tooltip: 'Delete tracker',
                      onPressed: () => _showDeleteDialog(context, ref),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Middle Row: Counter Display
            Center(
              child: Text(
                streakText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 6,
                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tracker.ruleEndDate == null
                      ? (!isQuit
                            ? (isCompletedToday
                                  ? '100% completed'
                                  : '${(progressValue * 100).toStringAsFixed(0)}% of current day left')
                            : '${(progressValue * 100).toStringAsFixed(0)}% of today completed')
                      : '${(progressValue * 100).toStringAsFixed(0)}% completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (tracker.ruleEndDate != null)
                  Builder(
                    builder: (context) {
                      final targetDays = tracker.ruleEndDate!
                          .difference(tracker.ruleStartDate)
                          .inDays;
                      return Text(
                        'Target: $targetDays day${targetDays == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
              ],
            ),

            // Action Buttons
            if (!isQuit) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (isLoading || isCompletedToday)
                      ? null
                      : () {
                          final newHistory = TrackerHistory(
                            id: const Uuid().v4(),
                            userId: tracker.userId,
                            trackerId: tracker.id,
                            date: now.dateOnly,
                            type: 'completion',
                          );
                          ref
                              .read(trackerActionControllerProvider.notifier)
                              .logHistory(newHistory);

                          AppBannerService.showSuccess(
                            context,
                            'Marked "${tracker.summary}" as completed!',
                            title: 'Success',
                          );
                        },
                  icon: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isCompletedToday
                                ? accentColor
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        )
                      : Icon(
                          isCompletedToday
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: isCompletedToday
                              ? accentColor
                              : colorScheme.onTertiary,
                        ),
                  label: Text(
                    isLoading
                        ? 'Loading...'
                        : (isCompletedToday
                              ? 'Completed for $periodName'
                              : 'Mark Completed for $periodName'),
                    style: TextStyle(
                      color: isCompletedToday
                          ? accentColor
                          : (isLoading
                                ? colorScheme.onSurface.withValues(alpha: 0.5)
                                : colorScheme.onTertiary),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompletedToday
                        ? Colors.transparent
                        : accentColor,
                    disabledBackgroundColor: isCompletedToday
                        ? Colors.transparent
                        : colorScheme.onSurface.withValues(alpha: 0.05),
                    disabledForegroundColor: isCompletedToday
                        ? accentColor
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                    shadowColor: isCompletedToday ? Colors.transparent : null,
                    elevation: isCompletedToday ? 0 : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isCompletedToday
                          ? BorderSide(
                              color: accentColor.withValues(alpha: 0.5),
                              width: 1.5,
                            )
                          : BorderSide.none,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (isQuit) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (isLoading || isSlippedToday)
                      ? null
                      : () {
                          final newHistory = TrackerHistory(
                            id: const Uuid().v4(),
                            userId: tracker.userId,
                            trackerId: tracker.id,
                            date: now.dateOnly,
                            type: 'slip_up',
                          );
                          ref
                              .read(trackerActionControllerProvider.notifier)
                              .logHistory(newHistory);

                          AppBannerService.showSuccess(
                            context,
                            'Reported slip-up for "${tracker.summary}". Don\'t give up!',
                            title: 'Slip-Up Logged',
                          );
                        },
                  icon: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isSlippedToday
                                ? colorScheme.error
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        )
                      : Icon(
                          isSlippedToday
                              ? Icons.warning
                              : Icons.warning_amber_rounded,
                          color: isSlippedToday
                              ? colorScheme.error
                              : colorScheme.onError,
                        ),
                  label: Text(
                    isLoading
                        ? 'Loading...'
                        : (isSlippedToday
                              ? 'Slip-Up Reported for $periodName'
                              : 'Report Slip-Up'),
                    style: TextStyle(
                      color: isSlippedToday
                          ? colorScheme.error
                          : (isLoading
                                ? colorScheme.onSurface.withValues(alpha: 0.5)
                                : colorScheme.onError),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSlippedToday
                        ? Colors.transparent
                        : colorScheme.error,
                    disabledBackgroundColor: isSlippedToday
                        ? Colors.transparent
                        : colorScheme.onSurface.withValues(alpha: 0.05),
                    disabledForegroundColor: isSlippedToday
                        ? colorScheme.error
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                    shadowColor: isSlippedToday ? Colors.transparent : null,
                    elevation: isSlippedToday ? 0 : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSlippedToday
                          ? BorderSide(
                              color: colorScheme.error.withValues(alpha: 0.5),
                              width: 1.5,
                            )
                          : BorderSide.none,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
