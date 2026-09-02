import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:busy_bee/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test', () {
    testWidgets('App starts and renders UI', (tester) async {
      // Start the app and await async initialization (Firebase, SharedPreferences, etc.)
      await app.main();

      // Allow frames to render and wait for the root widget to mount
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(app.MyApp).evaluate().isNotEmpty) {
          break;
        }
      }

      // Verify MyApp rendered successfully
      expect(find.byType(app.MyApp), findsOneWidget);
    });
  });
}
