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

    testWidgets('renders services with long IPv6 addresses without RenderFlex overflow exceptions on mobile screen', (tester) async {
      // Set viewport size to a realistic mobile screen width (360dp width)
      tester.view.physicalSize = const Size(
        360.0, // 360 physical pixels width representing standard mobile viewport
        640.0, // 640 physical pixels height
      );
      tester.view.devicePixelRatio = 1.0; // 1.0 device pixel ratio for 1:1 dp mapping
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ScannerScreen(viewModel: viewModel),
        ),
      );

      await tester.tap(find.text('Start Scan'));
      await tester.pump();

      // Emit item with a full IPv6 address and attributes
      final ipv6Item = MdnsServiceItem(
        id: 'ipv6-service-1',
        serviceType: '_http._tcp.local',
        instanceName: 'IPv6 Node Server',
        fullyQualifiedDomainName: 'IPv6 Node Server._http._tcp.local',
        hostTarget: 'node-srv.local',
        port: 8080, // HTTP port 8080
        ipv4Addresses: const [],
        ipv6Addresses: const ['2001:0db8:85a3:0000:0000:8a2e:0370:7334'],
        txtRecords: const {'model': 'ServerV6', 'mode': 'prod'},
        discoveredAt: DateTime.now(),
      );

      mockService.emitItem(ipv6Item);

      await tester.pump(
        const Duration(milliseconds: 50), // 50ms pump for batch flush
      );

      // Verify that the card is displayed with formatted IPv6 endpoint badge
      expect(find.text('IPv6 Node Server'), findsOneWidget);
      expect(
        find.text('[2001:0db8:85a3:0000:0000:8a2e:0370:7334]:8080'),
        findsOneWidget,
      );

      // Stop scan first to settle progress animations before navigating modal
      await tester.tap(find.text('Stop Scan'));
      await tester.pump(
        const Duration(milliseconds: 50), // 50ms pump to settle
      );

      // Tap on card to open detail sheet
      await tester.tap(find.text('IPv6 Node Server'));
      for (int i = 0; i < 6; i++) {
        await tester.pump(
          const Duration(milliseconds: 100), // 100ms step for smooth bottom sheet entrance
        );
      }

      // Verify detail modal opened
      expect(find.text('Service Details'), findsOneWidget);
      expect(find.text('DNS Resource Records'), findsOneWidget);

      // Scroll modal sheet to reveal the IP address section
      final modalScrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).last,
      );
      modalScrollable.position.jumpTo(
        500.0, // 500dp scroll offset down to IP address section
      );
      await tester.pump(
        const Duration(milliseconds: 100), // 100ms pump to layout scrolled content
      );

      expect(find.text('IPv6 Address'), findsOneWidget);
      expect(find.text('2001:0db8:85a3:0000:0000:8a2e:0370:7334'), findsOneWidget);

      // Dismiss the bottom sheet
      Navigator.of(tester.element(find.text('IPv6 Address'))).pop();
      for (int i = 0; i < 6; i++) {
        await tester.pump(
          const Duration(milliseconds: 100), // 100ms step for exit animation
        );
      }
    });
  });
}

