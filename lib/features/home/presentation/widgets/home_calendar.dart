import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../domain/models/day_data.dart';

class HomeCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final List<DayData> Function(DateTime day) eventLoader;
  final EdgeInsetsGeometry margin;

  const HomeCalendar({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    required this.onDaySelected,
    required this.eventLoader,
    this.margin = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      color: colorScheme.surface,
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar<DayData>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          shouldFillViewport: true,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          eventLoader: eventLoader,
          calendarFormat: CalendarFormat.month,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            cellAlignment: Alignment.topLeft,
            cellPadding: const EdgeInsets.only(top: 4.0, left: 4.0),
            cellMargin: const EdgeInsets.all(2.0),
            todayDecoration: BoxDecoration(
              border: Border.all(color: colorScheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(8),
              shape: BoxShape.rectangle,
            ),
            todayTextStyle: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              border: Border.all(color: colorScheme.primary, width: 2.0),
              borderRadius: BorderRadius.circular(8),
              shape: BoxShape.rectangle,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            selectedTextStyle: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            defaultDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              shape: BoxShape.rectangle,
            ),
            weekendDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              shape: BoxShape.rectangle,
            ),
            outsideDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              shape: BoxShape.rectangle,
            ),
          ),
          calendarBuilders: CalendarBuilders<DayData>(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return const SizedBox.shrink();

              final dayData = events.first;
              final tasks = dayData.tasks;
              final trackers = dayData.trackers;

              List<Widget> taskMarkers = [];

              if (tasks.isNotEmpty) {
                final displayLimit = 2;
                final showMore = tasks.length > displayLimit;
                final count = showMore ? displayLimit - 1 : tasks.length;

                for (int i = 0; i < count; i++) {
                  final e = tasks[i];
                  taskMarkers.add(
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: 2.0,
                        left: 2.0,
                        right: 2.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2.0,
                        vertical: 1.0,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: e['isCompleted']
                            ? e['color'].withValues(alpha: 0.8)
                            : e['color'].withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: e['isCompleted']
                            ? null
                            : Border.all(
                                color: e['color'].withValues(alpha: 0.5),
                              ),
                      ),
                      child: Text(
                        e['name'],
                        style: TextStyle(
                          fontSize: 8.0,
                          fontWeight: FontWeight.bold,
                          color: e['isCompleted'] ? Colors.white : e['color'],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (showMore) {
                  taskMarkers.add(
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: 2.0,
                        left: 2.0,
                        right: 2.0,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${tasks.length - count} more',
                        style: const TextStyle(
                          fontSize: 8.0,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
              }

              return SizedBox.expand(
                child: Stack(
                  children: [
                    if (trackers.isNotEmpty)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: trackers.take(4).map((color) {
                            return Container(
                              margin: const EdgeInsets.only(left: 2.0),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (taskMarkers.isNotEmpty)
                      Positioned(
                        top: 26,
                        left: 4,
                        right: 4,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: taskMarkers,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
