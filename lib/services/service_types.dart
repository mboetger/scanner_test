import 'package:flutter/material.dart';

/// Descriptor for a well-known mDNS service type.
class ServiceTypeDescriptor {
  /// Creates a service type descriptor with name, mDNS type identifier, description, and icon.
  const ServiceTypeDescriptor({
    required this.name,
    required this.serviceType,
    required this.description,
    required this.icon,
    this.defaultPort,
  });

  /// User friendly name of the protocol or service.
  final String name;

  /// Full mDNS service type string (e.g. `_http._tcp.local`).
  final String serviceType;

  /// Brief description of what devices/services use this.
  final String description;

  /// Material icon representing this service.
  final IconData icon;

  /// Optional default TCP/UDP port associated with the protocol.
  final int? defaultPort;
}

/// Catalog of commonly discovered Multicast DNS / Bonjour services.
abstract class ServiceTypes {
  /// Special marker for discovering all available DNS-SD service types.
  static const String dnsSdMetaQuery = '_services._dns-sd._udp.local';

  /// Standard HTTP Web Server
  static const String http = '_http._tcp.local';

  /// Secure HTTP Web Server
  static const String https = '_https._tcp.local';

  /// Google Cast / Chromecast / Google Home
  static const String googleCast = '_googlecast._tcp.local';

  /// Apple AirPlay Video / Mirroring
  static const String airPlay = '_airplay._tcp.local';

  /// Apple AirPlay Audio (Remote Audio Output Protocol)
  static const String raop = '_raop._tcp.local';

  /// Internet Printing Protocol
  static const String ipp = '_ipp._tcp.local';

  /// Secure Internet Printing Protocol
  static const String ipps = '_ipps._tcp.local';

  /// Standard Printer
  static const String printer = '_printer._tcp.local';

  /// Spotify Connect Audio Device
  static const String spotifyConnect = '_spotify-connect._tcp.local';

  /// Secure Shell Server
  static const String ssh = '_ssh._tcp.local';

  /// Server Message Block (Windows File Sharing)
  static const String smb = '_smb._tcp.local';

  /// Apple HomeKit / Home Accessory Protocol
  static const String homeKit = '_hap._tcp.local';

  /// Matter Smart Home Protocol
  static const String matter = '_matter._tcp.local';

  /// Workstation / Generic Computer
  static const String workstation = '_workstation._tcp.local';

  /// List of pre-defined standard service type descriptors.
  static const List<ServiceTypeDescriptor> catalog = [
    ServiceTypeDescriptor(
      name: 'All Types (DNS-SD)',
      serviceType: dnsSdMetaQuery,
      description: 'Discovers all advertised service types on local subnet',
      icon: Icons.hub_outlined,
      defaultPort: 5353, // Standard mDNS multicast port 5353 per RFC 6762
    ),
    ServiceTypeDescriptor(
      name: 'Web Servers (HTTP)',
      serviceType: http,
      description: 'Standard web servers and REST APIs',
      icon: Icons.language,
      defaultPort: 80, // Standard HTTP port 80
    ),
    ServiceTypeDescriptor(
      name: 'Secure Web (HTTPS)',
      serviceType: https,
      description: 'Encrypted web endpoints and services',
      icon: Icons.lock_outline,
      defaultPort: 443, // Standard HTTPS port 443
    ),
    ServiceTypeDescriptor(
      name: 'Google Cast',
      serviceType: googleCast,
      description: 'Chromecast, Nest Hubs, and Google Home devices',
      icon: Icons.cast,
      defaultPort: 8008, // Google Cast HTTP control port 8008
    ),
    ServiceTypeDescriptor(
      name: 'Apple AirPlay',
      serviceType: airPlay,
      description: 'AirPlay video and screen mirroring endpoints',
      icon: Icons.airplay,
      defaultPort: 7000, // Apple AirPlay RTSP default port 7000
    ),
    ServiceTypeDescriptor(
      name: 'AirPlay Audio (RAOP)',
      serviceType: raop,
      description: 'AirPlay wireless audio speakers',
      icon: Icons.speaker,
      defaultPort: 5000, // RAOP RTSP port 5000
    ),
    ServiceTypeDescriptor(
      name: 'IPP Printers',
      serviceType: ipp,
      description: 'Network printers supporting IPP',
      icon: Icons.print,
      defaultPort: 631, // Standard IPP port 631
    ),
    ServiceTypeDescriptor(
      name: 'Secure Printers (IPPS)',
      serviceType: ipps,
      description: 'Encrypted network printers',
      icon: Icons.print_outlined,
      defaultPort: 631, // Standard IPPS port 631
    ),
    ServiceTypeDescriptor(
      name: 'Spotify Connect',
      serviceType: spotifyConnect,
      description: 'Spotify-enabled wireless speakers and receivers',
      icon: Icons.music_note,
      defaultPort: null,
    ),
    ServiceTypeDescriptor(
      name: 'SSH Servers',
      serviceType: ssh,
      description: 'Secure Shell remote administration services',
      icon: Icons.terminal,
      defaultPort: 22, // Standard SSH port 22
    ),
    ServiceTypeDescriptor(
      name: 'SMB File Shares',
      serviceType: smb,
      description: 'Windows and Samba network shared files',
      icon: Icons.folder_shared,
      defaultPort: 445, // Standard SMB TCP port 445
    ),
    ServiceTypeDescriptor(
      name: 'HomeKit Accessories',
      serviceType: homeKit,
      description: 'Apple HomeKit smart home devices and hubs',
      icon: Icons.home,
      defaultPort: null,
    ),
    ServiceTypeDescriptor(
      name: 'Matter Devices',
      serviceType: matter,
      description: 'Matter IoT smart devices',
      icon: Icons.sensors,
      defaultPort: 5540, // Standard Matter Commissioning port 5540
    ),
    ServiceTypeDescriptor(
      name: 'Workstations',
      serviceType: workstation,
      description: 'Network computers and servers',
      icon: Icons.computer,
      defaultPort: null,
    ),
  ];

  /// Returns the recommended default scan list for multi-query scans.
  static List<String> get defaultScanTypes => [
        dnsSdMetaQuery,
        http,
        https,
        googleCast,
        airPlay,
        raop,
        ipp,
        spotifyConnect,
        ssh,
        homeKit,
        matter,
      ];

  /// Finds a descriptor matching the given service type, or returns a generic descriptor.
  static ServiceTypeDescriptor descriptorFor(String serviceType) {
    for (final desc in catalog) {
      if (desc.serviceType == serviceType) {
        return desc;
      }
    }
    return ServiceTypeDescriptor(
      name: serviceType,
      serviceType: serviceType,
      description: 'Custom mDNS service',
      icon: Icons.devices_other,
      defaultPort: null,
    );
  }
}
