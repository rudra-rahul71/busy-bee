import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/day_data.dart';

class DailyDetailsWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, MMMM d').format(selectedDay),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (dayData.tasks.isEmpty && dayData.trackers.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No events for this day.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else ...[
          if (dayData.trackers.isNotEmpty) ...[
            Text(
              'Trackers',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dayData.trackers.map((color) {
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (dayData.tasks.isNotEmpty) ...[
            Text(
              'Tasks',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                physics: isScrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                itemCount: dayData.tasks.length,
                itemBuilder: (context, index) {
                  final task = dayData.tasks[index];
                  final isCompleted = task['isCompleted'] ?? false;
                  final color = task['color'] as Color? ?? theme.colorScheme.primary;
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isCompleted ? color : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      task['name'] ?? 'Unknown Task',
                      style: TextStyle(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: content,
      ),
    );
  }
}
