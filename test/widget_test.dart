import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanner_test/main.dart';

void main() {
  testWidgets('ScannerApp smoke test verifies startup and UI controls', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ScannerApp());

    // Verify app title in AppBar
    expect(find.text('mDNS Network Scanner'), findsOneWidget);
    expect(find.text('DNS-SD Multicast Discovery'), findsOneWidget);

    // Verify Start Scan button and idle state message
    expect(find.text('Start Scan'), findsOneWidget);
    expect(find.text('Ready to Scan Network'), findsOneWidget);

    // Verify search bar and filter chips
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    // Verify telemetry metrics header
    expect(find.text('Discovered'), findsOneWidget);
    expect(find.text('Protocols'), findsOneWidget);
    expect(find.text('Packets'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);

    // Tap info icon in AppBar
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    // Verify about dialog appears
    expect(find.text('About mDNS Scanner'), findsOneWidget);

    // Close about dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Verify dialog closed
    expect(find.text('About mDNS Scanner'), findsNothing);
  });
}
