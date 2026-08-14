import 'package:flutter_test/flutter_test.dart';
import 'package:scanner_test/models/mdns_service_item.dart';
import 'package:scanner_test/models/scan_state.dart';
import 'package:scanner_test/models/scan_statistics.dart';

void main() {
  group('MdnsServiceItem', () {
    test('creates item with proper fields and computes derived properties', () {
      final item = MdnsServiceItem(
        id: 'test-id-1',
        serviceType: '_http._tcp.local',
        instanceName: 'My Web Server',
        fullyQualifiedDomainName: 'My Web Server._http._tcp.local',
        hostTarget: 'webserver.local',
        port: 8080, // HTTP standard alternative port 8080
        ipv4Addresses: const ['192.168.1.100'],
        ipv6Addresses: const ['fe80::1'],
        txtRecords: const {'version': '1.0.0', 'path': '/api'},
        discoveredAt: DateTime(
          2026, // Year 2026 for test timestamp
          8, // August
          14, // 14th day of month
          12, // 12th hour (noon)
          0, // 0 minutes
        ),
        ttlSeconds: 120, // 120 seconds TTL per DNS specification
      );

      expect(item.id, 'test-id-1');
      expect(item.serviceType, '_http._tcp.local');
      expect(item.instanceName, 'My Web Server');
      expect(item.displayName, 'My Web Server');
      expect(item.port, 8080); // Expected port 8080
      expect(item.primaryIpAddress, '192.168.1.100');
      expect(item.allIpAddresses.length, 2); // 1 IPv4 + 1 IPv6 = 2 total IP addresses
      expect(item.txtRecords['version'], '1.0.0');
    });

    test('supports copyWith with updated values', () {
      final original = MdnsServiceItem(
        id: 'test-id-1',
        serviceType: '_googlecast._tcp.local',
        instanceName: 'Living Room TV',
        fullyQualifiedDomainName: 'Living Room TV._googlecast._tcp.local',
        hostTarget: 'chromecast.local',
        port: 8008, // Google Cast default port 8008
        ipv4Addresses: const ['192.168.1.50'],
        ipv6Addresses: const [],
        txtRecords: const {'md': 'Chromecast'},
        discoveredAt: DateTime.now(),
        ttlSeconds: 60, // 60 seconds TTL
      );

      final updated = original.copyWith(
        ipv4Addresses: ['192.168.1.50', '192.168.1.51'],
        txtRecords: {'md': 'Chromecast Ultra', 'fn': 'Living Room'},
      );

      expect(updated.id, original.id);
      expect(updated.instanceName, original.instanceName);
      expect(updated.ipv4Addresses.length, 2); // Updated to 2 IPv4 addresses
      expect(updated.txtRecords['fn'], 'Living Room');
    });

    test('equality and hashCode are based on id and properties', () {
      final timestamp = DateTime(
        2026, // Year 2026
        8, // August
        14, // 14th
      );
      final item1 = MdnsServiceItem(
        id: 'item-1',
        serviceType: '_http._tcp.local',
        instanceName: 'Server 1',
        fullyQualifiedDomainName: 'Server 1._http._tcp.local',
        hostTarget: 'server1.local',
        port: 80, // Standard HTTP port 80
        ipv4Addresses: const ['10.0.0.1'],
        ipv6Addresses: const [],
        txtRecords: const {},
        discoveredAt: timestamp,
        ttlSeconds: 300, // 300 seconds TTL
      );

      final item2 = MdnsServiceItem(
        id: 'item-1',
        serviceType: '_http._tcp.local',
        instanceName: 'Server 1',
        fullyQualifiedDomainName: 'Server 1._http._tcp.local',
        hostTarget: 'server1.local',
        port: 80, // Standard HTTP port 80
        ipv4Addresses: const ['10.0.0.1'],
        ipv6Addresses: const [],
        txtRecords: const {},
        discoveredAt: timestamp,
        ttlSeconds: 300, // 300 seconds TTL
      );

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
    });
  });

  group('ScanState & ScanStatistics', () {
    test('ScanStatistics calculates metrics accurately', () {
      const stats = ScanStatistics(
        totalDiscovered: 5, // 5 discovered services
        typesScanned: 3, // 3 distinct service types scanned
        packetsReceived: 24, // 24 raw mDNS packets processed
        duration: Duration(seconds: 4), // 4 seconds elapsed scan time
      );

      expect(stats.totalDiscovered, 5); // Verify 5 discovered services
      expect(stats.typesScanned, 3); // Verify 3 types scanned
      expect(stats.packetsReceived, 24); // Verify 24 packets
      expect(stats.duration.inSeconds, 4); // Verify 4 seconds duration
    });

    test('ScanState holds status and timestamps', () {
      final startTime = DateTime(
        2026, // Year 2026
        1, // January
        1, // 1st
        10, // 10 AM
        0, // 0 minutes
      );
      final state = ScanState(
        status: ScanStatus.scanning,
        startedAt: startTime,
        errorMessage: null,
      );

      expect(state.status, ScanStatus.scanning);
      expect(state.isScanning, isTrue);
      expect(state.startedAt, startTime);
      expect(state.errorMessage, isNull);
    });
  });
}
