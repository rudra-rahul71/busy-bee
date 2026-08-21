import 'package:flutter/material.dart';

import '../../domain/models/day_data.dart';
import '../widgets/home_calendar.dart';
import '../widgets/daily_details_widget.dart';
import '../../../../core/widgets/page_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Data for events and trackers
  final Map<DateTime, DayData> _events = {};

  List<DayData> _getEventsForDay(DateTime day) {
    // Normalize time to compare dates only
    final normalizedDay = DateTime(day.year, day.month, day.day);
    if (_events.containsKey(normalizedDay)) {
      return [_events[normalizedDay]!];
    }
    return [];
  }

  void _showMobileBottomSheet(BuildContext context, DateTime day, DayData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: DailyDetailsWidget(
                selectedDay: day,
                dayData: data,
                isScrollable: true,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: PageHeader(
              header: 'Busy Bee',
              sub: 'Manage your daily tasks and events',
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth >= 850;
                final dayEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];
                final dayData = dayEvents.isNotEmpty ? dayEvents.first : const DayData();

                final calendarWidget = HomeCalendar(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  margin: isLargeScreen ? EdgeInsets.zero : const EdgeInsets.all(16.0),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    
                    if (!isLargeScreen) {
                      final events = _getEventsForDay(selectedDay);
                      final data = events.isNotEmpty ? events.first : const DayData();
                      _showMobileBottomSheet(context, selectedDay, data);
                    }
                  },
                  eventLoader: _getEventsForDay,
                );

                if (isLargeScreen) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: DailyDetailsWidget(
                            selectedDay: _selectedDay ?? _focusedDay,
                            dayData: dayData,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: calendarWidget,
                        ),
                      ],
                    ),
                  );
                } else {
                  return calendarWidget;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
