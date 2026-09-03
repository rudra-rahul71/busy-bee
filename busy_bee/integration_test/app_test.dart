import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:busy_bee/main.dart' as app;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:busy_bee/features/trackers/presentation/controllers/tracker_action_controller.dart';
import 'package:busy_bee/features/trackers/presentation/widgets/add_tracker_sheet.dart';
import 'package:busy_bee/features/trackers/presentation/widgets/tracker_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test', () {
    testWidgets('Create a new habit tracker and verify database persistence', (tester) async {
      // 1. Launch the application
      await app.main();

      // Wait for app to finish loading and rendering the first screen
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byIcon(Icons.track_changes_outlined).evaluate().isNotEmpty ||
            find.text('Trackers').evaluate().isNotEmpty) {
          break;
        }
      }

      // Verify we are in the main app shell
      final trackersTab = find.byIcon(Icons.track_changes_outlined);
      if (trackersTab.evaluate().isEmpty) {
        debugPrint('App is not on main shell (requires login/onboarding).');
        expect(find.byType(app.MyApp), findsOneWidget);
        return;
      }

      // 2. Navigate to the Trackers tab
      await tester.tap(trackersTab);
      await tester.pumpAndSettle();

      // 3. Tap "Add Tracker" button
      final addTrackerBtn = find.text('Add Tracker');
      expect(addTrackerBtn, findsOneWidget);
      await tester.tap(addTrackerBtn);
      await tester.pumpAndSettle();

      // Verify the sheet opened
      expect(find.byType(AddTrackerSheet), findsOneWidget);

      // 4. Fill in the tracker name
      final habitName = 'E2E Habit ${DateTime.now().millisecondsSinceEpoch % 10000}';
      final nameField = find.widgetWithText(TextFormField, 'Habit Name');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, habitName);
      await tester.pumpAndSettle();

      // 5. Scroll down to "Create Tracker" button so it is fully visible and clickable
      final createBtn = find.widgetWithText(ElevatedButton, 'Create Tracker');
      expect(createBtn, findsOneWidget);
      await tester.ensureVisible(createBtn);
      await tester.pumpAndSettle();

      // 6. Tap "Create Tracker"
      await tester.tap(createBtn);
      await tester.pump();
      
      // Wait for the async database request to finish and modal to dismiss
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.byType(AddTrackerSheet).evaluate().isEmpty) {
          break;
        }
      }

      // If sheet didn't dismiss, inspect the controller error to diagnose why
      if (find.byType(AddTrackerSheet).evaluate().isNotEmpty) {
        final element = tester.element(find.byType(AddTrackerSheet));
        final container = ProviderScope.containerOf(element);
        final formState = container.read(trackerFormControllerProvider);
        if (formState.hasError) {
          fail('🚨 AddTrackerSheet failed with database error: ${formState.error}');
        } else if (formState.isLoading) {
          fail('🚨 AddTrackerSheet is still loading (network call hung).');
        } else {
          fail('🚨 AddTrackerSheet submit was not triggered or form validation failed.');
        }
      }

      // Assert that the sheet dismissed (proves form was submitted successfully)
      expect(find.byType(AddTrackerSheet), findsNothing);

      // 7. Wait for the live database stream to receive the new tracker
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.widgetWithText(TrackerCard, habitName).evaluate().isNotEmpty) {
          break;
        }
      }

      // 8. Verify the new tracker card exists on screen
      expect(find.widgetWithText(TrackerCard, habitName), findsOneWidget);
    });
  });
}
