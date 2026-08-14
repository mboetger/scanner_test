import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanner_test/models/mdns_service_item.dart';
import 'package:scanner_test/models/scan_state.dart';
import 'package:scanner_test/services/mdns_scanner_service.dart';
import 'package:scanner_test/viewmodels/scanner_viewmodel.dart';

/// Mock scanner service for ViewModel testing.
class MockMdnsScannerService implements IMdnsScannerService {
  StreamController<MdnsServiceItem>? controller;
  bool _isScanning = false;
  List<String>? lastRequestedTypes;

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
    lastRequestedTypes = serviceTypes;
    controller = StreamController<MdnsServiceItem>.broadcast();
    return controller!.stream;
  }

  @override
  Future<void> stopScan() async {
    _isScanning = false;
    if (controller != null && !controller!.isClosed) {
      await controller!.close();
    }
  }

  void emitItem(MdnsServiceItem item) {
    controller?.add(item);
  }

  void emitError(Object error) {
    controller?.addError(error);
  }

  Future<void> completeScan() async {
    _isScanning = false;
    if (controller != null && !controller!.isClosed) {
      await controller!.close();
    }
  }
}

void main() {
  group('ScannerViewModel', () {
    late MockMdnsScannerService mockService;
    late ScannerViewModel viewModel;

    setUp(() {
      mockService = MockMdnsScannerService();
      viewModel = ScannerViewModel(
        scannerService: mockService,
        batchFlushInterval: const Duration(
          milliseconds: 50, // 50ms flush interval for fast unit test execution
        ),
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('initial state is idle with empty list', () {
      expect(viewModel.statusNotifier.value, ScanStatus.idle);
      expect(viewModel.itemsNotifier.value, isEmpty);
      expect(viewModel.statsNotifier.value.totalDiscovered, 0); // 0 discovered initially
      expect(viewModel.selectedItemNotifier.value, isNull);
    });

    test('startScan transitions status to scanning and receives batched items', () async {
      await viewModel.startScan(serviceTypes: ['_http._tcp.local']);

      expect(viewModel.statusNotifier.value, ScanStatus.scanning);

      final item1 = MdnsServiceItem(
        id: 'id-1',
        serviceType: '_http._tcp.local',
        instanceName: 'Test Web Server 1',
        fullyQualifiedDomainName: 'Test Web Server 1._http._tcp.local',
        hostTarget: 'server1.local',
        port: 80, // Port 80 for HTTP server
        ipv4Addresses: const ['192.168.1.10'],
        discoveredAt: DateTime.now(),
      );

      final item2 = MdnsServiceItem(
        id: 'id-2',
        serviceType: '_http._tcp.local',
        instanceName: 'Test Web Server 2',
        fullyQualifiedDomainName: 'Test Web Server 2._http._tcp.local',
        hostTarget: 'server2.local',
        port: 8080, // Port 8080 alternative
        ipv4Addresses: const ['192.168.1.20'],
        discoveredAt: DateTime.now(),
      );

      // Emit multiple items rapidly (tight stream)
      mockService.emitItem(item1);
      mockService.emitItem(item2);

      // Wait for batch interval to flush
      await Future<void>.delayed(
        const Duration(milliseconds: 100), // 100ms wait to verify batch flush
      );

      expect(viewModel.itemsNotifier.value.length, 2); // Expect 2 batched items
      expect(viewModel.statsNotifier.value.totalDiscovered, 2); // Expect 2 discovered in stats

      await mockService.completeScan();
      await Future<void>.delayed(
        const Duration(milliseconds: 100), // 100ms wait for completion
      );

      expect(viewModel.statusNotifier.value, ScanStatus.completed);
    });

    test('filters items by search query and type filter', () async {
      await viewModel.startScan();

      final webItem = MdnsServiceItem(
        id: 'web-1',
        serviceType: '_http._tcp.local',
        instanceName: 'Kitchen Display',
        fullyQualifiedDomainName: 'Kitchen Display._http._tcp.local',
        hostTarget: 'display.local',
        port: 80, // Port 80
        ipv4Addresses: const ['192.168.1.15'],
        discoveredAt: DateTime.now(),
      );

      final castItem = MdnsServiceItem(
        id: 'cast-1',
        serviceType: '_googlecast._tcp.local',
        instanceName: 'Living Room TV',
        fullyQualifiedDomainName: 'Living Room TV._googlecast._tcp.local',
        hostTarget: 'cast.local',
        port: 8008, // Google Cast port 8008
        ipv4Addresses: const ['192.168.1.25'],
        discoveredAt: DateTime.now(),
      );

      mockService.emitItem(webItem);
      mockService.emitItem(castItem);

      await Future<void>.delayed(
        const Duration(milliseconds: 100), // 100ms batch flush delay
      );

      expect(viewModel.itemsNotifier.value.length, 2); // 2 total items before filtering

      // Filter by search query
      viewModel.setSearchQuery('Kitchen');
      expect(viewModel.itemsNotifier.value.length, 1); // 1 item matching 'Kitchen'
      expect(viewModel.itemsNotifier.value.first.instanceName, 'Kitchen Display');

      // Clear search query
      viewModel.setSearchQuery('');
      expect(viewModel.itemsNotifier.value.length, 2); // 2 items restored

      // Filter by service type
      viewModel.setTypeFilter('_googlecast._tcp.local');
      expect(viewModel.itemsNotifier.value.length, 1); // 1 item matching Google Cast type
      expect(viewModel.itemsNotifier.value.first.instanceName, 'Living Room TV');

      // Reset filter to All
      viewModel.setTypeFilter('All');
      expect(viewModel.itemsNotifier.value.length, 2); // 2 items returned
    });

    test('handles item selection', () {
      final item = MdnsServiceItem(
        id: 'item-1',
        serviceType: '_http._tcp.local',
        instanceName: 'Printer',
        fullyQualifiedDomainName: 'Printer._http._tcp.local',
        hostTarget: 'printer.local',
        port: 631, // IPP printer port 631
        discoveredAt: DateTime.now(),
      );

      viewModel.selectItem(item);
      expect(viewModel.selectedItemNotifier.value, item);

      viewModel.selectItem(null);
      expect(viewModel.selectedItemNotifier.value, isNull);
    });

    test('handles errors gracefully without throwing', () async {
      await viewModel.startScan();
      mockService.emitError(Exception('Network error'));

      await Future<void>.delayed(
        const Duration(milliseconds: 50), // 50ms wait for error dispatch
      );

      expect(viewModel.errorNotifier.value, isNotNull);
      expect(viewModel.statusNotifier.value, ScanStatus.error);
    });

    test('clearResults resets state to empty', () async {
      await viewModel.startScan();
      mockService.emitItem(MdnsServiceItem(
        id: 'item-1',
        serviceType: '_http._tcp.local',
        instanceName: 'Test',
        fullyQualifiedDomainName: 'Test._http._tcp.local',
        hostTarget: 'test.local',
        port: 80, // Port 80
        discoveredAt: DateTime.now(),
      ));

      await Future<void>.delayed(
        const Duration(milliseconds: 100), // 100ms batch delay
      );

      expect(viewModel.itemsNotifier.value.length, 1); // 1 item present

      viewModel.clearResults();
      expect(viewModel.itemsNotifier.value, isEmpty);
      expect(viewModel.statsNotifier.value.totalDiscovered, 0); // 0 count after clear
    });
  });
}
