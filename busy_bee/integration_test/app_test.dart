import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:busy_bee/main.dart' as app;
import 'package:busy_bee/features/trackers/data/tracker_providers.dart';
import 'package:busy_bee/features/trackers/presentation/controllers/tracker_action_controller.dart';
import 'package:busy_bee/features/trackers/presentation/widgets/add_tracker_sheet.dart';
import 'package:busy_bee/features/trackers/presentation/widgets/tracker_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test', () {
    testWidgets('Create a new habit tracker, verify DB persistence, and clean up', (tester) async {
      // 1. Ensure backend config exists so app never halts on the hosting wizard
      final configService = ConfigService();
      final existingConfig = await configService.getSavedConfig();
      if (existingConfig == null) {
        // Default to managed backend if not configured
        await configService.saveConfig(AppConfig(backendType: BackendType.managed));
      }

      // 2. Launch the application
      await app.main();

      // Wait for app to finish loading the initial screen
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byIcon(Icons.track_changes_outlined).evaluate().isNotEmpty ||
            find.text('SIGN IN').evaluate().isNotEmpty ||
            find.text('SIGN UP').evaluate().isNotEmpty) {
          break;
        }
      }

      // 3. Handle Authentication if the app is on the Sign-In / Sign-Up screen (e.g. in CI)
      if (find.text('SIGN IN').evaluate().isNotEmpty || find.text('SIGN UP').evaluate().isNotEmpty) {
        debugPrint('[E2E Test] App is on Auth screen. Performing automated sign-up...');

        // Switch to Sign Up mode if currently on Sign In
        final signUpToggle = find.text("Don't have an account? Sign Up");
        if (signUpToggle.evaluate().isNotEmpty) {
          await tester.tap(signUpToggle);
          await tester.pump(const Duration(milliseconds: 500));
        }

        // Enter unique test credentials
        final testEmail = 'e2e_user_${DateTime.now().millisecondsSinceEpoch}@test.com';
        final emailField = find.widgetWithText(TextFormField, 'Email');
        final passwordField = find.widgetWithText(TextFormField, 'Password');

        expect(emailField, findsOneWidget, reason: 'Email field must be present on Auth screen');
        expect(passwordField, findsOneWidget, reason: 'Password field must be present on Auth screen');

        await tester.enterText(emailField, testEmail);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.enterText(passwordField, 'Password123!');
        await tester.pump(const Duration(milliseconds: 500));

        // Submit sign up
        final submitAuthBtn = find.text('SIGN UP');
        expect(submitAuthBtn, findsOneWidget);
        await tester.tap(submitAuthBtn);

        // Wait for auth to complete and home screen navigation shell to mount
        for (int i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          if (find.byIcon(Icons.track_changes_outlined).evaluate().isNotEmpty) {
            break;
          }
        }
      }

      // 4. Strict assertion: We MUST be on the main shell. No silent early returns!
      final trackersTab = find.byIcon(Icons.track_changes_outlined);
      expect(
        trackersTab,
        findsOneWidget,
        reason: 'Test must reach the main shell with the Trackers tab. (Auth failed if not found).',
      );

      // 5. Navigate to the Trackers tab
      await tester.tap(trackersTab);
      await tester.pump(const Duration(milliseconds: 800));

      // 6. Tap "Add Tracker" button
      final addTrackerBtn = find.text('Add Tracker');
      expect(addTrackerBtn, findsOneWidget);
      await tester.tap(addTrackerBtn);
      await tester.pump(const Duration(milliseconds: 800));

      // Verify the sheet opened
      expect(find.byType(AddTrackerSheet), findsOneWidget);

      // 7. Fill in the tracker name
      final habitName = 'E2E Habit ${DateTime.now().millisecondsSinceEpoch % 10000}';
      final nameField = find.widgetWithText(TextFormField, 'Habit Name');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, habitName);
      await tester.pump(const Duration(milliseconds: 300));

      // 8. Scroll down to "Create Tracker" button and tap it
      final createBtn = find.widgetWithText(ElevatedButton, 'Create Tracker');
      expect(createBtn, findsOneWidget);
      await tester.ensureVisible(createBtn);
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(createBtn);
      await tester.pump(const Duration(milliseconds: 200));

      // Wait for the async database request to finish and modal to dismiss
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.byType(AddTrackerSheet).evaluate().isEmpty) {
          break;
        }
      }

      // If sheet didn't dismiss, fail with the exact controller error
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

      // 9. Verify the new tracker card appears in the UI
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.widgetWithText(TrackerCard, habitName).evaluate().isNotEmpty) {
          break;
        }
      }
      expect(find.widgetWithText(TrackerCard, habitName), findsOneWidget);

      // 10. Direct Database Verification: Query PostgreSQL directly through the collection
      final element = tester.element(find.byType(app.MyApp));
      final container = ProviderScope.containerOf(element);
      final trackerCollection = container.read(trackerCollectionProvider);

      final dbRows = await trackerCollection.fetch(
        filters: [QueryFilter.eq('summary', habitName)],
      );

      expect(
        dbRows.length,
        equals(1),
        reason: 'CRITICAL FAILURE: The tracker "$habitName" was NOT found in the database table!',
      );
      debugPrint('[E2E Test] Verified tracker exists in database: ID=${dbRows.first.id}, Summary="${dbRows.first.summary}"');

      // 11. Cleanup: Delete the created test record so it leaves zero database pollution
      await trackerCollection.delete(dbRows.first.id);
      debugPrint('[E2E Test] Successfully cleaned up test record ID=${dbRows.first.id} from database.');
    });
  });
}
