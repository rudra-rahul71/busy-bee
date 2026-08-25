import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

import '../../../../models/tracker.dart';
import '../../data/tracker_providers.dart';
import '../widgets/add_tracker_sheet.dart';
import '../widgets/tracker_card.dart';

enum TrackerFilter { all, maintain, quit }

class TrackersPage extends ConsumerStatefulWidget {
  const TrackersPage({super.key});

  @override
  ConsumerState<TrackersPage> createState() => _TrackersPageState();
}

class _TrackersPageState extends ConsumerState<TrackersPage> {
  TrackerFilter _activeFilter = TrackerFilter.all;

  void _showAddTrackerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTrackerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<AsyncValue<List<Tracker>>>(trackersStreamProvider, (_, state) {
      if (!state.isLoading && state.hasError) {
        AppBannerService.showError(
          context,
          state.error.toString(),
          title: 'Failed to Load Trackers',
        );
      }
    });

    final trackersAsync = ref.watch(trackersStreamProvider);
    final trackers = trackersAsync.value ?? [];

    final filteredTrackers = trackers.where((t) {
      if (_activeFilter == TrackerFilter.all) return true;
      return t.trackerType == _activeFilter.name;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(colorScheme),
                const SizedBox(height: 24),
                _buildFilterChips(colorScheme),
                const SizedBox(height: 24),
              ]),
            ),
          ),
          if (trackersAsync.isLoading && trackers.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            )
          else if (filteredTrackers.isEmpty || trackersAsync.hasError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(colorScheme),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: _buildTrackersGrid(filteredTrackers),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trackers',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monitor and build your habit streaks',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _showAddTrackerSheet,
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            'Add Tracker',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: TrackerFilter.values.map((filter) {
        final isSelected = _activeFilter == filter;
        final label =
            filter.name.substring(0, 1).toUpperCase() +
            filter.name.substring(1);

        Color selectedColor;
        switch (filter) {
          case TrackerFilter.maintain:
            selectedColor = colorScheme.tertiary;
            break;
          case TrackerFilter.quit:
            selectedColor = colorScheme.error;
            break;
          default:
            selectedColor = colorScheme.primary;
        }

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _activeFilter = filter);
          },
          selectedColor: selectedColor.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected ? selectedColor : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
          side: BorderSide(
            color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _activeFilter == TrackerFilter.all
                ? 'No habit trackers created yet'
                : _activeFilter == TrackerFilter.maintain
                ? 'No habits to maintain yet'
                : 'No habits to quit yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Tracker" in the top right to start tracking!',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackersGrid(List<Tracker> trackers) {
    // Improved responsive design using LayoutBuilder
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.crossAxisExtent >= 850 ? 2 : 1;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 265, // Fixed height for cards
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => TrackerCard(tracker: trackers[index]),
            childCount: trackers.length,
          ),
        );
      },
    );
  }
}
