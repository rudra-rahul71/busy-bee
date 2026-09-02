import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/day_data.dart';
import '../../data/calendar_providers.dart';
import '../../../trackers/data/tracker_providers.dart';
import '../widgets/home_calendar.dart';
import '../widgets/daily_details_widget.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/page_header.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<DayData> _getEventsForDay(DateTime day) {
    final calendarData = ref.read(calendarDataProvider);
    final normalizedDay = DateTime(day.year, day.month, day.day);
    if (calendarData.containsKey(normalizedDay)) {
      return [calendarData[normalizedDay]!];
    }
    return [];
  }

  void _showMobileBottomSheet(
    BuildContext context,
    DateTime day,
    DayData data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                child: DailyDetailsWidget(
                  selectedDay: day,
                  dayData: data,
                  isScrollable: false,
                  asCard: false,
                ),
              ),
            ),
          ),
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
    ref.watch(calendarDataProvider);
    final trackerHistoryMap = ref.watch(
      calendarTrackerHistoryLookupMapProvider(_focusedDay.monthOnly),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth >= 850;
          const minHeight = 440.0;
          const headerAndPaddingHeight = 128.0;
          final availableHeight = constraints.maxHeight - headerAndPaddingHeight;
          final targetHeight =
              availableHeight > minHeight ? availableHeight : minHeight;

          final dayEvents = _selectedDay != null
              ? _getEventsForDay(_selectedDay!)
              : [];
          final dayData =
              dayEvents.isNotEmpty ? dayEvents.first : const DayData();

          final calendarWidget = HomeCalendar(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            trackerHistoryMap: trackerHistoryMap,
            margin: EdgeInsets.zero,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              if (!isLargeScreen) {
                final events = _getEventsForDay(selectedDay);
                final data =
                    events.isNotEmpty ? events.first : const DayData();
                _showMobileBottomSheet(context, selectedDay, data);
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
          );

          Widget contentWidget;
          if (isLargeScreen) {
            contentWidget = SizedBox(
              height: targetHeight,
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
                  Expanded(flex: 4, child: calendarWidget),
                ],
              ),
            );
          } else {
            contentWidget = SizedBox(
              height: targetHeight,
              child: calendarWidget,
            );
          }

          return CustomScrollView(
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.all(24.0),
                sliver: SliverToBoxAdapter(
                  child: PageHeader(
                    header: 'Busy Bee',
                    sub: 'Manage your daily tasks and events',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: 24.0,
                ),
                sliver: SliverToBoxAdapter(
                  child: contentWidget,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
