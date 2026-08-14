import 'package:flutter/foundation.dart';

/// Represents a discovered network service via Multicast DNS (DNS-SD).
@immutable
class MdnsServiceItem {
  /// Creates an immutable [MdnsServiceItem].
  const MdnsServiceItem({
    required this.id,
    required this.serviceType,
    required this.instanceName,
    required this.fullyQualifiedDomainName,
    required this.hostTarget,
    required this.port,
    this.ipv4Addresses = const <String>[],
    this.ipv6Addresses = const <String>[],
    this.txtRecords = const <String, String>{},
    required this.discoveredAt,
    this.ttlSeconds = 120, // Default 120 seconds TTL per standard mDNS caching guidelines
  });

  /// Unique identifier composed of service type and instance name.
  final String id;

  /// The mDNS service type, e.g. `_http._tcp.local` or `_googlecast._tcp.local`.
  final String serviceType;

  /// The human-readable name of the specific service instance.
  final String instanceName;

  /// The Fully Qualified Domain Name (FQDN) for the record.
  final String fullyQualifiedDomainName;

  /// The hostname of the device hosting the service, e.g. `printer.local`.
  final String hostTarget;

  /// The TCP or UDP port number the service is listening on.
  final int port;

  /// Discovered IPv4 addresses for the host.
  final List<String> ipv4Addresses;

  /// Discovered IPv6 addresses for the host.
  final List<String> ipv6Addresses;

  /// Parsed key-value attributes from DNS TXT records.
  final Map<String, String> txtRecords;

  /// Timestamp when this service record was first discovered or updated.
  final DateTime discoveredAt;

  /// Time-To-Live in seconds for this DNS record.
  final int ttlSeconds;

  /// Returns user-facing display name.
  String get displayName =>
      instanceName.isNotEmpty ? instanceName : hostTarget;

  /// Returns the primary IP address (prefers IPv4 if available, otherwise IPv6 or hostname).
  String get primaryIpAddress {
    if (ipv4Addresses.isNotEmpty) {
      return ipv4Addresses.first;
    }
    if (ipv6Addresses.isNotEmpty) {
      return ipv6Addresses.first;
    }
    return hostTarget;
  }

  /// All unique IP addresses discovered for this service.
  List<String> get allIpAddresses => [...ipv4Addresses, ...ipv6Addresses];

  /// Returns a copy with updated properties.
  MdnsServiceItem copyWith({
    String? id,
    String? serviceType,
    String? instanceName,
    String? fullyQualifiedDomainName,
    String? hostTarget,
    int? port,
    List<String>? ipv4Addresses,
    List<String>? ipv6Addresses,
    Map<String, String>? txtRecords,
    DateTime? discoveredAt,
    int? ttlSeconds,
  }) {
    return MdnsServiceItem(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      instanceName: instanceName ?? this.instanceName,
      fullyQualifiedDomainName:
          fullyQualifiedDomainName ?? this.fullyQualifiedDomainName,
      hostTarget: hostTarget ?? this.hostTarget,
      port: port ?? this.port,
      ipv4Addresses: ipv4Addresses ?? this.ipv4Addresses,
      ipv6Addresses: ipv6Addresses ?? this.ipv6Addresses,
      txtRecords: txtRecords ?? this.txtRecords,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MdnsServiceItem &&
        other.id == id &&
        other.serviceType == serviceType &&
        other.instanceName == instanceName &&
        other.fullyQualifiedDomainName == fullyQualifiedDomainName &&
        other.hostTarget == hostTarget &&
        other.port == port &&
        listEquals(other.ipv4Addresses, ipv4Addresses) &&
        listEquals(other.ipv6Addresses, ipv6Addresses) &&
        mapEquals(other.txtRecords, txtRecords) &&
        other.discoveredAt == discoveredAt &&
        other.ttlSeconds == ttlSeconds;
  }

  @override
  int get hashCode => Object.hash(
        id,
        serviceType,
        instanceName,
        fullyQualifiedDomainName,
        hostTarget,
        port,
        Object.hashAll(ipv4Addresses),
        Object.hashAll(ipv6Addresses),
        Object.hashAll(txtRecords.entries),
        discoveredAt,
        ttlSeconds,
      );

  @override
  String toString() {
    return 'MdnsServiceItem(id: $id, name: $instanceName, type: $serviceType, target: $hostTarget:$port)';
  }
}
