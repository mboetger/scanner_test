import 'package:flutter/material.dart';
import '../../models/mdns_service_item.dart';
import '../../services/service_types.dart';

/// A leaf card widget presenting a single discovered mDNS service.
class ServiceCard extends StatelessWidget {
  /// Creates a [ServiceCard] with service data and tap callback.
  const ServiceCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  /// The service record data to display.
  final MdnsServiceItem item;

  /// Callback when user taps the card to inspect details.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final descriptor = ServiceTypes.descriptorFor(item.serviceType);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12.0, // 12dp horizontal margin between card and screen edge
        vertical: 4.0, // 4dp vertical margin between adjacent list cards
      ),
      elevation: 1.5, // 1.5dp subtle card shadow elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12.0, // 12dp rounded corner radius for modern card aesthetics
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12.0, // 12dp ripple border radius matching card shape
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            12.0, // 12dp internal card content padding
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Type Icon Badge
              Container(
                width: 44.0, // 44dp fixed width for icon container
                height: 44.0, // 44dp fixed height for icon container
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    10.0, // 10dp rounded corner for icon badge
                  ),
                ),
                child: Icon(
                  descriptor.icon,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24.0, // 24dp standard icon size
                ),
              ),
              const SizedBox(
                width: 12.0, // 12dp horizontal spacing between icon and text details
              ),
              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Name
                    Text(
                      item.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1, // Max 1 line for clean title display
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(
                      height: 3.0, // 3dp spacing between title and service type
                    ),
                    // Service Type & FQDN
                    Text(
                      item.serviceType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1, // Max 1 line
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(
                      height: 6.0, // 6dp spacing before network address badges
                    ),
                    // Host, Port, and IP Badges
                    Wrap(
                      spacing: 6.0, // 6dp spacing between badge chips
                      runSpacing: 4.0, // 4dp spacing between chip lines
                      children: [
                        // IP & Port Chip
                        _buildBadge(
                          icon: Icons.lan_outlined,
                          label: '${item.primaryIpAddress}:${item.port}',
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          textColor: theme.colorScheme.onSurfaceVariant,
                        ),
                        // Host Target Chip (if different from IP)
                        if (item.hostTarget.isNotEmpty &&
                            item.hostTarget != item.primaryIpAddress)
                          _buildBadge(
                            icon: Icons.computer_outlined,
                            label: item.hostTarget,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            textColor: theme.colorScheme.onSurfaceVariant,
                          ),
                        // TXT Attributes Count Chip (if any)
                        if (item.txtRecords.isNotEmpty)
                          _buildBadge(
                            icon: Icons.info_outline,
                            label:
                                '${item.txtRecords.length} attr',
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            textColor: theme.colorScheme.onSecondaryContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Trailing Chevron Icon
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
                size: 22.0, // 22dp standard chevron size
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6.0, // 6dp horizontal badge padding
        vertical: 2.0, // 2dp vertical badge padding
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          6.0, // 6dp subtle badge radius
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.0, // 12dp compact badge icon size
            color: textColor,
          ),
          const SizedBox(
            width: 4.0, // 4dp spacing between badge icon and text
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.0, // 11sp small typography for badge label
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
