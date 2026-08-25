import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../models/tracker.dart';
import '../controllers/tracker_action_controller.dart';

class AddTrackerSheet extends ConsumerStatefulWidget {
  final Tracker? trackerToEdit;
  const AddTrackerSheet({super.key, this.trackerToEdit});

  @override
  ConsumerState<AddTrackerSheet> createState() => _AddTrackerSheetState();
}

class _AddTrackerSheetState extends ConsumerState<AddTrackerSheet> {
  final _formKey = GlobalKey<FormState>();

  String _summary = '';
  String _type = 'maintain'; // 'maintain' or 'quit'
  DateTime _startDate = DateTime.now();
  String _durationType = 'indefinite'; // 'indefinite' or 'set_time'
  int? _durationValue;
  late final String _trackerId;

  @override
  void initState() {
    super.initState();
    _trackerId = widget.trackerToEdit?.id ?? const Uuid().v4();
    if (widget.trackerToEdit != null) {
      _summary = widget.trackerToEdit!.summary;
      _type = widget.trackerToEdit!.trackerType;
      _startDate = widget.trackerToEdit!.ruleStartDate;

      if (widget.trackerToEdit!.ruleEndDate != null) {
        _durationType = 'set_time';
        _durationValue = widget.trackerToEdit!.ruleEndDate!
            .difference(widget.trackerToEdit!.ruleStartDate)
            .inDays;
      } else {
        _durationType = 'indefinite';
      }
    }
  }

  InputDecoration _buildInputDecoration(
    ColorScheme colorScheme,
    String labelText,
    String hintText,
  ) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final isEdit = widget.trackerToEdit != null;
    final user = ref.read(authRepositoryProvider).currentUser;
    final tracker = Tracker(
      id: _trackerId,
      userId: isEdit ? widget.trackerToEdit!.userId : (user?.uid ?? ''),
      summary: _summary,
      trackerType: _type,
      ruleStartDate: _startDate.dateOnly,
      ruleEndDate: _durationType == 'set_time' && _durationValue != null
          ? _startDate.dateOnly.addDays(_durationValue!)
          : null,
      rrule: 'FREQ=DAILY', // Simplified for now
      clientOffsetHours: DateTime.now().timeZoneOffset.inHours,
      currentStreak: isEdit ? widget.trackerToEdit!.currentStreak : 0,
      longestStreak: isEdit ? widget.trackerToEdit!.longestStreak : 0,
      lastCompletedDate: isEdit
          ? widget.trackerToEdit!.lastCompletedDate
          : null,
      lastSlipUpDate: isEdit ? widget.trackerToEdit!.lastSlipUpDate : null,
      createdAt: isEdit ? widget.trackerToEdit!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final controller = ref.read(
      trackerActionControllerProvider(_trackerId).notifier,
    );
    if (isEdit) {
      await controller.updateTracker(tracker);
    } else {
      await controller.addTracker(tracker);
    }

    if (mounted &&
        !ref.read(trackerActionControllerProvider(_trackerId)).hasError) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme),
                const SizedBox(height: 24),
                _buildNameField(colorScheme),
                const SizedBox(height: 24),
                _buildTypeSelector(colorScheme),
                const SizedBox(height: 24),
                _buildDurationSelector(colorScheme),
                const SizedBox(height: 24),
                _buildStartDatePicker(colorScheme),
                const SizedBox(height: 32),
                _buildActionButtons(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.trackerToEdit != null
                ? 'Edit Tracker'
                : 'Create Habit Tracker',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildNameField(ColorScheme colorScheme) {
    return TextFormField(
      initialValue: _summary,
      decoration: _buildInputDecoration(
        colorScheme,
        'Habit Name',
        'e.g., Gym, Sleep Early, No Sweets',
      ),
      style: TextStyle(color: colorScheme.onSurface),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a name for your tracker';
        }
        return null;
      },
      onSaved: (value) => _summary = value!.trim(),
    );
  }

  Widget _buildTypeSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What type of habit is this?',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'maintain',
                label: Text('Maintain'),
                icon: Icon(Icons.check_circle_outline_rounded),
              ),
              ButtonSegment(
                value: 'quit',
                label: Text('Quit'),
                icon: Icon(Icons.block_flipped),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (newSelection) {
              setState(() {
                _type = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: _type == 'quit'
                  ? colorScheme.error.withValues(alpha: 0.15)
                  : colorScheme.tertiary.withValues(alpha: 0.15),
              selectedForegroundColor: _type == 'quit'
                  ? colorScheme.error
                  : colorScheme.tertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'indefinite',
                label: Text('Indefinite'),
                icon: Icon(Icons.trending_up_rounded),
              ),
              ButtonSegment(
                value: 'set_time',
                label: Text('Set Duration'),
                icon: Icon(Icons.timer_outlined),
              ),
            ],
            selected: {_durationType},
            onSelectionChanged: (newSelection) {
              setState(() {
                _durationType = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: colorScheme.primary.withValues(
                alpha: 0.15,
              ),
              selectedForegroundColor: colorScheme.primary,
            ),
          ),
        ),
        if (_durationType == 'set_time') ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _durationValue?.toString() ?? '',
            decoration: _buildInputDecoration(
              colorScheme,
              'Duration (Days)',
              'e.g., 30',
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(color: colorScheme.onSurface),
            validator: (value) {
              if (_durationType == 'set_time') {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a number';
                }
                final num = int.tryParse(value);
                if (num == null || num <= 0) {
                  return 'Enter a valid positive number';
                }
              }
              return null;
            },
            onSaved: (value) => _durationValue = int.tryParse(value ?? ''),
          ),
        ],
      ],
    );
  }

  Widget _buildStartDatePicker(ColorScheme colorScheme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Start Date',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
        style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
      ),
      trailing: IconButton(
        icon: Icon(Icons.calendar_month, color: colorScheme.primary),
        onPressed: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: _startDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );

          if (pickedDate != null) {
            setState(() {
              _startDate = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
              );
            });
          }
        },
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    final asyncState = ref.watch(trackerActionControllerProvider(_trackerId));
    final isLoading = asyncState.isLoading;

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.trackerToEdit != null
                      ? 'Save Changes'
                      : 'Create Tracker',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
        ),
      ],
    );
  }
}
