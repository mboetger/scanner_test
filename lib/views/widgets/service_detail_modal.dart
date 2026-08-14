import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/mdns_service_item.dart';
import '../../services/service_types.dart';

/// Modal bottom sheet displaying detailed DNS-SD records for a selected service.
class ServiceDetailModal extends StatelessWidget {
  /// Creates a [ServiceDetailModal] with the selected service item.
  const ServiceDetailModal({
    super.key,
    required this.item,
  });

  /// The service record to inspect.
  final MdnsServiceItem item;

  /// Helper to display this modal bottom sheet.
  static Future<void> show(BuildContext context, MdnsServiceItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            16.0, // 16dp top corner radius for bottom sheet
          ),
        ),
      ),
      builder: (ctx) => ServiceDetailModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final descriptor = ServiceTypes.descriptorFor(item.serviceType);

    return DraggableScrollableSheet(
      initialChildSize: 0.65, // 65% initial screen height
      minChildSize: 0.4, // 40% minimum screen height
      maxChildSize: 0.92, // 92% maximum screen height
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0, // 16dp horizontal edge padding
            vertical: 8.0, // 8dp top padding
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Drag Handle Indicator
              Center(
                child: Container(
                  width: 40.0, // 40dp drag handle width
                  height: 4.0, // 4dp drag handle height
                  margin: const EdgeInsets.only(
                    bottom: 12.0, // 12dp spacing below drag handle
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(
                      2.0, // 2dp rounded drag handle radius
                    ),
                  ),
                ),
              ),

              // Title and Protocol Header
              Row(
                children: [
                  Container(
                    width: 48.0, // 48dp header icon container width
                    height: 48.0, // 48dp header icon container height
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        12.0, // 12dp rounded corner
                      ),
                    ),
                    child: Icon(
                      descriptor.icon,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 28.0, // 28dp header icon size
                    ),
                  ),
                  const SizedBox(
                    width: 12.0, // 12dp spacing between icon and text
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Details',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16.0, // 16dp section spacing
              ),
              const Divider(),
              const SizedBox(
                height: 8.0, // 8dp spacing
              ),

              // General Section
              _buildSectionTitle(context, 'DNS Resource Records'),
              _buildRecordTile(
                context,
                title: 'Service Type (PTR)',
                value: item.serviceType,
                subtitle: descriptor.description,
                icon: Icons.tag,
                copyable: true,
              ),
              _buildRecordTile(
                context,
                title: 'Fully Qualified Name (FQDN)',
                value: item.fullyQualifiedDomainName,
                icon: Icons.dns_outlined,
                copyable: true,
              ),
              _buildRecordTile(
                context,
                title: 'Host Target (SRV)',
                value: item.hostTarget.isNotEmpty ? item.hostTarget : 'Not advertised',
                icon: Icons.computer,
                copyable: item.hostTarget.isNotEmpty,
              ),
              _buildRecordTile(
                context,
                title: 'Port (SRV)',
                value: '${item.port}',
                icon: Icons.numbers,
                copyable: true,
              ),

              const SizedBox(
                height: 12.0, // 12dp section spacing
              ),
              // IP Addresses Section
              _buildSectionTitle(context, 'IP Addresses (A / AAAA)'),
              if (item.allIpAddresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0, // 8dp vertical padding
                    horizontal: 4.0, // 4dp horizontal padding
                  ),
                  child: Text(
                    'No direct IP addresses resolved yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ...item.allIpAddresses.map(
                  (ip) => _buildRecordTile(
                    context,
                    title: ip.contains(':') ? 'IPv6 Address' : 'IPv4 Address',
                    value: ip,
                    icon: Icons.lan,
                    copyable: true,
                  ),
                ),

              const SizedBox(
                height: 12.0, // 12dp section spacing
              ),
              // TXT Records Section
              _buildSectionTitle(context, 'TXT Attributes'),
              if (item.txtRecords.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0, // 8dp padding
                    horizontal: 4.0, // 4dp padding
                  ),
                  child: Text(
                    'No TXT attributes published for this service.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ...item.txtRecords.entries.map(
                  (entry) => _buildTxtRecordTile(
                    context,
                    keyName: entry.key,
                    val: entry.value,
                  ),
                ),

              const SizedBox(
                height: 12.0, // 12dp spacing
              ),
              // Metadata Footer
              _buildSectionTitle(context, 'Telemetry & Cache'),
              _buildRecordTile(
                context,
                title: 'Time To Live (TTL)',
                value: '${item.ttlSeconds} seconds',
                icon: Icons.timer_outlined,
                copyable: false,
              ),
              _buildRecordTile(
                context,
                title: 'Discovered At',
                value: item.discoveredAt.toLocal().toString(),
                icon: Icons.access_time,
                copyable: false,
              ),

              const SizedBox(
                height: 24.0, // 24dp bottom breathing room
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0, // 6dp vertical padding for section headers
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildRecordTile(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required bool copyable,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 3.0, // 3dp vertical margin
      ),
      elevation: 0.0, // Flat card design
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          8.0, // 8dp subtle corner radius
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20.0, // 20dp icon size
          color: theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        trailing: copyable
            ? IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 18.0, // 18dp copy button icon size
                ),
                tooltip: 'Copy $title',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied $title to clipboard'),
                      duration: const Duration(
                        seconds: 2, // 2-second snackbar duration
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget _buildTxtRecordTile(
    BuildContext context, {
    required String keyName,
    required String val,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 3.0, // 3dp margin
      ),
      elevation: 0.0, // Flat
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          8.0, // 8dp radius
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0, // 12dp horizontal padding
          vertical: 8.0, // 8dp vertical padding
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0, // 6dp padding
                vertical: 2.0, // 2dp padding
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(
                  4.0, // 4dp radius
                ),
              ),
              child: Text(
                keyName,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.0, // 12sp font size
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(
              width: 8.0, // 8dp spacing
            ),
            Expanded(
              child: Text(
                val.isNotEmpty ? val : '(empty)',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.0, // 12sp font size
                  color: val.isNotEmpty
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
