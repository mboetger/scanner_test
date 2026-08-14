import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';
import '../models/mdns_service_item.dart';
import 'service_types.dart';

/// Factory signature for producing [MDnsClient] instances.
typedef MDnsClientFactory = MDnsClient Function();

/// Abstract interface contract for mDNS network discovery operations.
abstract class IMdnsScannerService {
  /// Stream emitting discovered or updated [MdnsServiceItem]s as they are resolved.
  Stream<MdnsServiceItem> scan({
    List<String>? serviceTypes,
    Duration? queryTimeout,
    InternetAddress? listenAddress,
    int? port,
  });

  /// Stops any active network scan and releases socket resources.
  Future<void> stopScan();

  /// Whether a scan operation is actively executing.
  bool get isScanning;
}

/// Implementation of [IMdnsScannerService] using the `multicast_dns` package.
class MdnsScannerService implements IMdnsScannerService {
  /// Creates an [MdnsScannerService] with optional custom [MDnsClientFactory] for testing.
  MdnsScannerService({MDnsClientFactory? clientFactory})
      : _clientFactory = clientFactory ?? _defaultClientFactory;

  static MDnsClient _defaultClientFactory() => MDnsClient();

  final MDnsClientFactory _clientFactory;
  MDnsClient? _currentClient;
  StreamController<MdnsServiceItem>? _streamController;
  bool _isScanning = false;
  final Set<String> _processedFqdns = <String>{};

  @override
  bool get isScanning => _isScanning;

  @override
  Stream<MdnsServiceItem> scan({
    List<String>? serviceTypes,
    Duration? queryTimeout,
    InternetAddress? listenAddress,
    int? port,
  }) {
    // Stop any existing scan before starting a new one
    if (_isScanning) {
      stopScan();
    }

    _isScanning = true;
    _processedFqdns.clear();
    final controller = StreamController<MdnsServiceItem>.broadcast();
    _streamController = controller;

    final targetTypes = (serviceTypes != null && serviceTypes.isNotEmpty)
        ? serviceTypes
        : ServiceTypes.defaultScanTypes;

    final timeout = queryTimeout ??
        const Duration(
          seconds: 4, // 4-second default timeout for DNS query resolution
        );

    final mDnsPort = port ?? 5353; // Standard mDNS multicast UDP port per RFC 6762

    // Run the scan asynchronously
    unawaited(_executeScan(
      targetTypes: targetTypes,
      queryTimeout: timeout,
      listenAddress: listenAddress,
      port: mDnsPort,
      controller: controller,
    ));

    return controller.stream;
  }

  Future<void> _executeScan({
    required List<String> targetTypes,
    required Duration queryTimeout,
    required InternetAddress? listenAddress,
    required int port,
    required StreamController<MdnsServiceItem> controller,
  }) async {
    try {
      final client = _clientFactory();
      _currentClient = client;

      await client.start(
        listenAddress: listenAddress ?? InternetAddress.anyIPv4,
        mDnsPort: port,
        onError: (dynamic error) {
          developer.log(
            'MDnsClient stream error: $error',
            name: 'MdnsScannerService',
            error: error,
          );
          if (!controller.isClosed) {
            controller.addError(error as Object);
          }
        },
      );

      // Perform parallel queries for each requested service type
      final futures = <Future<void>>[];
      for (final serviceType in targetTypes) {
        futures.add(_scanServiceType(
          client: client,
          serviceType: serviceType,
          queryTimeout: queryTimeout,
          controller: controller,
        ));
      }

      await Future.wait(futures);
    } catch (e, stackTrace) {
      developer.log(
        'Error during mDNS scan execution: $e',
        name: 'MdnsScannerService',
        error: e,
        stackTrace: stackTrace,
      );
      if (!controller.isClosed) {
        controller.addError(e, stackTrace);
      }
    } finally {
      _isScanning = false;
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }

  Future<void> _scanServiceType({
    required MDnsClient client,
    required String serviceType,
    required Duration queryTimeout,
    required StreamController<MdnsServiceItem> controller,
  }) async {
    try {
      final ptrQuery = ResourceRecordQuery.serverPointer(serviceType);
      final ptrStream = client.lookup<PtrResourceRecord>(
        ptrQuery,
        timeout: queryTimeout,
      );

      await for (final PtrResourceRecord ptr in ptrStream) {
        if (!_isScanning || controller.isClosed) {
          break;
        }

        final domainName = ptr.domainName;

        // If scanning DNS-SD meta query, domainName contains a new service type
        if (serviceType == ServiceTypes.dnsSdMetaQuery) {
          // Recursively resolve discovered sub-service type
          unawaited(_scanServiceType(
            client: client,
            serviceType: domainName,
            queryTimeout: queryTimeout,
            controller: controller,
          ));
          continue;
        }

        // Avoid duplicate resolution work for the same FQDN in the current session
        if (_processedFqdns.contains(domainName)) {
          continue;
        }
        _processedFqdns.add(domainName);

        // Resolve details for this instance
        await _resolveServiceInstance(
          client: client,
          serviceType: serviceType,
          fqdn: domainName,
          queryTimeout: queryTimeout,
          controller: controller,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error querying service type $serviceType: $e',
        name: 'MdnsScannerService',
        error: e,
        stackTrace: stackTrace,
      );
      // Propagate error via controller without crashing other queries
      if (!controller.isClosed) {
        controller.addError(e, stackTrace);
      }
    }
  }

  Future<void> _resolveServiceInstance({
    required MDnsClient client,
    required String serviceType,
    required String fqdn,
    required Duration queryTimeout,
    required StreamController<MdnsServiceItem> controller,
  }) async {
    try {
      final srvQuery = ResourceRecordQuery.service(fqdn);
      final txtQuery = ResourceRecordQuery.text(fqdn);

      String hostTarget = '';
      int port = 0; // Default 0 when unassigned
      int ttl = 120; // Default 120s TTL
      final txtRecords = <String, String>{};
      final ipv4Addresses = <String>[];
      final ipv6Addresses = <String>[];

      // Query SRV and TXT in parallel
      final srvFuture = client
          .lookup<SrvResourceRecord>(srvQuery, timeout: queryTimeout)
          .toList()
          .catchError((dynamic error) {
        developer.log('SRV lookup error for $fqdn: $error', name: 'MdnsScannerService');
        return <SrvResourceRecord>[];
      });

      final txtFuture = client
          .lookup<TxtResourceRecord>(txtQuery, timeout: queryTimeout)
          .toList()
          .catchError((dynamic error) {
        developer.log('TXT lookup error for $fqdn: $error', name: 'MdnsScannerService');
        return <TxtResourceRecord>[];
      });

      final results = await Future.wait([srvFuture, txtFuture]);
      final srvRecords = results[0] as List<SrvResourceRecord>; // SRV lookup results
      final txtRecordList = results[1] as List<TxtResourceRecord>; // TXT lookup results

      if (srvRecords.isNotEmpty) {
        final srv = srvRecords.first;
        hostTarget = srv.target;
        port = srv.port;
        ttl = srv.validUntil > 0
            ? ((srv.validUntil - DateTime.now().millisecondsSinceEpoch) /
                    1000) // 1000ms per second
                .round()
            : 120; // 120 seconds fallback TTL
      }

      for (final txt in txtRecordList) {
        final parsed = _parseTxtRecord(txt.text);
        txtRecords.addAll(parsed);
      }

      // Query IP addresses if we have a host target
      if (hostTarget.isNotEmpty) {
        try {
          final ipv4List = await client
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(hostTarget),
                timeout: queryTimeout,
              )
              .toList();
          for (final ipRec in ipv4List) {
            ipv4Addresses.add(ipRec.address.address);
          }
        } catch (e) {
          developer.log('IPv4 lookup error for $hostTarget: $e', name: 'MdnsScannerService');
        }

        try {
          final ipv6List = await client
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv6(hostTarget),
                timeout: queryTimeout,
              )
              .toList();
          for (final ipRec in ipv6List) {
            ipv6Addresses.add(ipRec.address.address);
          }
        } catch (e) {
          developer.log('IPv6 lookup error for $hostTarget: $e', name: 'MdnsScannerService');
        }
      }

      final instanceName = _extractInstanceName(fqdn, serviceType);
      final id = '$serviceType:$instanceName:$hostTarget:$port';

      final item = MdnsServiceItem(
        id: id,
        serviceType: serviceType,
        instanceName: instanceName,
        fullyQualifiedDomainName: fqdn,
        hostTarget: hostTarget,
        port: port,
        ipv4Addresses: ipv4Addresses,
        ipv6Addresses: ipv6Addresses,
        txtRecords: txtRecords,
        discoveredAt: DateTime.now(),
        ttlSeconds: ttl > 0 ? ttl : 120, // Minimum 120 seconds default TTL
      );

      if (!controller.isClosed) {
        controller.add(item);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error resolving instance $fqdn: $e',
        name: 'MdnsScannerService',
        error: e,
        stackTrace: stackTrace,
      );
      if (!controller.isClosed) {
        controller.addError(e, stackTrace);
      }
    }
  }

  String _extractInstanceName(String fqdn, String serviceType) {
    if (fqdn.endsWith('.$serviceType')) {
      final lengthToTrim = serviceType.length + 1; // 1 for leading dot
      return fqdn.substring(
        0, // Start of string index 0
        fqdn.length - lengthToTrim,
      );
    }
    final firstDot = fqdn.indexOf('.');
    if (firstDot > 0) {
      return fqdn.substring(
        0, // Start of string index 0
        firstDot,
      );
    }
    return fqdn;
  }

  Map<String, String> _parseTxtRecord(String rawText) {
    final result = <String, String>{};
    final lines = rawText.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final equalsIndex = trimmed.indexOf('=');
      if (equalsIndex > 0) {
        final key = trimmed.substring(
          0, // Start of key index 0
          equalsIndex,
        );
        final value = trimmed.substring(
          equalsIndex + 1, // Start of value after equals sign (1 char offset)
        );
        result[key] = value;
      } else {
        result[trimmed] = '';
      }
    }
    return result;
  }

  @override
  Future<void> stopScan() async {
    _isScanning = false;
    try {
      _currentClient?.stop();
    } catch (e) {
      developer.log('Error stopping MDnsClient: $e', name: 'MdnsScannerService', error: e);
    } finally {
      _currentClient = null;
      if (_streamController != null && !_streamController!.isClosed) {
        unawaited(_streamController!.close());
      }
      _streamController = null;
    }
  }
}
