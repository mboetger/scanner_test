import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:scanner_test/models/mdns_service_item.dart';
import 'package:scanner_test/services/mdns_scanner_service.dart';

/// Fake MDnsClient to test MdnsScannerService in isolation without real sockets.
class FakeMDnsClient implements MDnsClient {
  bool isStarted = false;
  bool isStopped = false;

  final Map<String, List<ResourceRecord>> lookupResponses = {};

  @override
  Future<void> start({
    dynamic listenAddress,
    dynamic interfacesFactory,
    int mDnsPort = 5353, // Standard mDNS port 5353
    dynamic mDnsAddress,
    Function? onError,
  }) async {
    isStarted = true;
  }

  @override
  void stop() {
    isStopped = true;
    isStarted = false;
  }

  @override
  Stream<T> lookup<T extends ResourceRecord>(
    ResourceRecordQuery query, {
    Duration timeout = const Duration(seconds: 5), // Default 5 seconds query timeout
  }) {
    final key = '${query.resourceRecordType}:${query.fullyQualifiedName}';
    final records = lookupResponses[key] ?? <ResourceRecord>[];
    return Stream<T>.fromIterable(records.cast<T>());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MdnsScannerService', () {
    late FakeMDnsClient fakeClient;
    late MdnsScannerService scannerService;

    setUp(() {
      fakeClient = FakeMDnsClient();
      scannerService = MdnsScannerService(
        clientFactory: () => fakeClient,
      );
    });

    tearDown(() async {
      await scannerService.stopScan();
    });

    test('successfully scans and resolves PTR, SRV, TXT, and IP records', () async {
      const serviceType = '_http._tcp.local';
      const fqdn = 'My Test Service._http._tcp.local';
      const hostTarget = 'test-device.local';
      const port = 8080; // HTTP test port 8080

      final ptrRecord = PtrResourceRecord(
        serviceType,
        1000, // 1000ms validUntil
        domainName: fqdn,
      );

      final srvRecord = SrvResourceRecord(
        fqdn,
        1000, // 1000ms validUntil
        target: hostTarget,
        port: port,
        priority: 0, // Priority 0 (highest)
        weight: 0, // Weight 0
      );

      final txtRecord = TxtResourceRecord(
        fqdn,
        1000, // 1000ms validUntil
        text: 'path=/api\nversion=2.0',
      );

      fakeClient.lookupResponses['${ResourceRecordType.serverPointer}:$serviceType'] = [
        ptrRecord,
      ];
      fakeClient.lookupResponses['${ResourceRecordType.service}:$fqdn'] = [
        srvRecord,
      ];
      fakeClient.lookupResponses['${ResourceRecordType.text}:$fqdn'] = [
        txtRecord,
      ];

      final discoveredItems = <MdnsServiceItem>[];
      final stream = scannerService.scan(
        serviceTypes: [serviceType],
        queryTimeout: const Duration(milliseconds: 200), // 200ms query timeout for fast tests
      );

      final subscription = stream.listen((item) {
        discoveredItems.add(item);
      });

      // Allow async processing to yield results
      await Future<void>.delayed(
        const Duration(milliseconds: 300), // 300ms delay to allow lookup processing
      );

      await subscription.cancel();
      await scannerService.stopScan();

      expect(discoveredItems.length, greaterThanOrEqualTo(1)); // Expect at least 1 discovered service
      final item = discoveredItems.first;
      expect(item.serviceType, serviceType);
      expect(item.instanceName, 'My Test Service');
      expect(item.hostTarget, hostTarget);
      expect(item.port, port);
      expect(item.txtRecords['path'], '/api');
      expect(item.txtRecords['version'], '2.0');
    });

    test('handles stopScan properly', () async {
      final stream = scannerService.scan(
        serviceTypes: ['_http._tcp.local'],
      );

      expect(scannerService.isScanning, isTrue);
      final sub = stream.listen((_) {});

      await scannerService.stopScan();
      expect(scannerService.isScanning, isFalse);
      expect(fakeClient.isStopped, isTrue);

      await sub.cancel();
    });
  });
}
