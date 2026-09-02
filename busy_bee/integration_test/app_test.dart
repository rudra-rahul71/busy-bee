import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:busy_bee/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test', () {
    testWidgets('App starts and renders UI', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify something exists (fallback to checking if any widget rendered)
      expect(find.byType(app.MyApp), findsOneWidget);
    });
  });
}
