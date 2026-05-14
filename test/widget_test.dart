import 'package:flutter_test/flutter_test.dart';
import 'package:fleetmanagment/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FleetOpsApp(),
      ),
    );

    // Verify that the app starts (e.g. finds the title)
    expect(find.text('FleetOps Pro'), findsOneWidget);
  });
}
