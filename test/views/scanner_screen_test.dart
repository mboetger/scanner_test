import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanner_test/models/mdns_service_item.dart';
import 'package:scanner_test/services/mdns_scanner_service.dart';
import 'package:scanner_test/viewmodels/scanner_viewmodel.dart';
import 'package:scanner_test/views/scanner_screen.dart';

class TestMockScannerService implements IMdnsScannerService {
  StreamController<MdnsServiceItem>? controller;
  bool _isScanning = false;

  @override
  bool get isScanning => _isScanning;

  @override
  Stream<MdnsServiceItem> scan({
    List<String>? serviceTypes,
    Duration? queryTimeout,
    dynamic listenAddress,
    int? port,
  }) {
    _isScanning = true;
    controller = StreamController<MdnsServiceItem>.broadcast();
    return controller!.stream;
  }

  @override
  Future<void> stopScan() async {
    _isScanning = false;
    if (controller != null && !controller!.isClosed) {
      unawaited(controller!.close());
    }
  }

  void emitItem(MdnsServiceItem item) {
    controller?.add(item);
  }
}

void main() {
  group('ScannerScreen UI & Leaf Rebuilding', () {
    late TestMockScannerService mockService;
    late ScannerViewModel viewModel;

    setUp(() {
      mockService = TestMockScannerService();
      viewModel = ScannerViewModel(
        scannerService: mockService,
        batchFlushInterval: const Duration(
          milliseconds: 20, // 20ms flush interval for fast widget tests
        ),
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    testWidgets('renders initial UI with scan controls and idle empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScannerScreen(viewModel: viewModel),
        ),
      );

      // Verify header and Scan button
      expect(find.text('mDNS Network Scanner'), findsOneWidget);
      expect(find.text('Start Scan'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify initial empty state
      expect(find.text('Ready to Scan Network'), findsOneWidget);
    });

    testWidgets('starts scan and updates stats bar and list view on item arrival', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScannerScreen(viewModel: viewModel),
        ),
      );

      // Tap the Start Scan button
      await tester.tap(find.text('Start Scan'));
      await tester.pump();

      // Verify scanning state appears
      expect(find.text('Stop Scan'), findsOneWidget);

      // Emit discovered mDNS items
      final testItem = MdnsServiceItem(
        id: 'cast-101',
        serviceType: '_googlecast._tcp.local',
        instanceName: 'Living Room TV',
        fullyQualifiedDomainName: 'Living Room TV._googlecast._tcp.local',
        hostTarget: 'chromecast.local',
        port: 8008, // Port 8008 for Google Cast
        ipv4Addresses: const ['192.168.1.105'],
        txtRecords: const {'md': 'Chromecast Ultra', 'fn': 'Living Room'},
        discoveredAt: DateTime.now(),
      );

      mockService.emitItem(testItem);

      // Wait for batch timer tick
      await tester.pump(
        const Duration(milliseconds: 50), // 50ms pump for batch flush
      );

      // Verify item card is displayed in the list
      expect(find.text('Living Room TV'), findsOneWidget);
      expect(find.text('_googlecast._tcp.local'), findsOneWidget);
      expect(find.text('192.168.1.105:8008'), findsOneWidget);

      // Tap on card to open detail sheet
      await tester.tap(find.text('Living Room TV'));
      await tester.pump(
        const Duration(milliseconds: 500), // 500ms pump for bottom sheet entrance animation
      );

      // Verify detail modal opened with DNS details
      expect(find.text('Service Details'), findsOneWidget);
      expect(find.text('Living Room TV._googlecast._tcp.local'), findsOneWidget);
      expect(find.text('DNS Resource Records'), findsOneWidget);

      // Dismiss the bottom sheet
      Navigator.of(tester.element(find.text('Service Details'))).pop();
      await tester.pump(
        const Duration(milliseconds: 500), // 500ms pump for bottom sheet exit animation
      );

      // Tap Stop Scan button to stop
      await tester.tap(find.text('Stop Scan'));
      await tester.pump(
        const Duration(milliseconds: 50), // 50ms pump to settle
      );
    });

    testWidgets('filters list when user types in search bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScannerScreen(viewModel: viewModel),
        ),
      );

      await tester.tap(find.text('Start Scan'));
      await tester.pump();

      final itemA = MdnsServiceItem(
        id: 'id-a',
        serviceType: '_http._tcp.local',
        instanceName: 'Office Router Web UI',
        fullyQualifiedDomainName: 'Office Router._http._tcp.local',
        hostTarget: 'router.local',
        port: 80, // HTTP port 80
        ipv4Addresses: const ['192.168.1.1'],
        discoveredAt: DateTime.now(),
      );

      final itemB = MdnsServiceItem(
        id: 'id-b',
        serviceType: '_ipp._tcp.local',
        instanceName: 'Laser Printer',
        fullyQualifiedDomainName: 'Laser Printer._ipp._tcp.local',
        hostTarget: 'printer.local',
        port: 631, // IPP port 631
        ipv4Addresses: const ['192.168.1.200'],
        discoveredAt: DateTime.now(),
      );

      mockService.emitItem(itemA);
      mockService.emitItem(itemB);

      await tester.pump(
        const Duration(milliseconds: 50), // 50ms batch pump
      );

      expect(find.text('Office Router Web UI'), findsOneWidget);
      expect(find.text('Laser Printer'), findsOneWidget);

      // Enter search filter
      await tester.enterText(find.byType(TextField), 'Router');
      await tester.pump();

      expect(find.text('Office Router Web UI'), findsOneWidget);
      expect(find.text('Laser Printer'), findsNothing);

      // Tap Stop Scan button to stop
      await tester.tap(find.text('Stop Scan'));
      await tester.pump(
        const Duration(milliseconds: 50), // 50ms pump to settle
      );
    });
  });
}
