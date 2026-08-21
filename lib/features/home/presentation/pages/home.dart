import 'package:flutter/material.dart';

import '../../domain/models/day_data.dart';
import '../widgets/home_calendar.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: PageHeader(
                  header: 'Busy Bee',
                  sub: 'Manage your daily tasks and events',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: HomeCalendar(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: _getEventsForDay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
