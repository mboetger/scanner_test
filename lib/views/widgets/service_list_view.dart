import 'package:flutter/material.dart';
import '../../models/mdns_service_item.dart';
import '../../models/scan_state.dart';
import '../../viewmodels/scanner_viewmodel.dart';
import 'service_card.dart';
import 'service_detail_modal.dart';

/// Leaf widget rendering the scrollable list of discovered mDNS service items.
class ServiceListView extends StatelessWidget {
  /// Creates a [ServiceListView] observing [ScannerViewModel].
  const ServiceListView({
    super.key,
    required this.viewModel,
  });

  /// The ViewModel providing item and state listenables.
  final ScannerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScanStatus>(
      valueListenable: viewModel.statusNotifier,
      builder: (context, scanStatus, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: viewModel.errorNotifier,
          builder: (context, errorMessage, _) {
            // Error State
            if (errorMessage != null && scanStatus == ScanStatus.error) {
              return _buildErrorState(context, errorMessage);
            }

            return ValueListenableBuilder<List<MdnsServiceItem>>(
              valueListenable: viewModel.itemsNotifier,
              builder: (context, items, _) {
                // Empty state when scanning
                if (items.isEmpty && scanStatus == ScanStatus.scanning) {
                  return _buildScanningEmptyState(context);
                }

                // Empty state when idle / completed
                if (items.isEmpty) {
                  return _buildIdleEmptyState(context);
                }

                // Discovered items list with minimal paint / rebuild overhead
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6.0, // 6dp vertical list padding
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ServiceCard(
                      key: ValueKey(item.id),
                      item: item,
                      onTap: () {
                        viewModel.selectItem(item);
                        ServiceDetailModal.show(context, item);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildScanningEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          24.0, // 24dp padding for empty state container
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56.0, // 56dp spinner container width
              height: 56.0, // 56dp spinner container height
              child: CircularProgressIndicator(
                strokeWidth: 3.0, // 3dp thickness
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(
              height: 20.0, // 20dp vertical spacing
            ),
            Text(
              'Scanning Local Network...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8.0, // 8dp spacing
            ),
            Text(
              'Broadcasting mDNS query packets on 224.0.0.251:5353.\nListening for PTR, SRV, TXT, and IP responses.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          32.0, // 32dp spacious padding
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.0, // 72dp icon container width
              height: 72.0, // 72dp icon container height
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.4, // 40% opacity
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_tethering,
                size: 36.0, // 36dp large icon
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(
              height: 16.0, // 16dp spacing
            ),
            Text(
              'Ready to Scan Network',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8.0, // 8dp spacing
            ),
            Text(
              'Tap "Start Scan" above to discover Bonjour, Avahi, and mDNS services on your local Wi-Fi / Ethernet subnet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          24.0, // 24dp padding
        ),
        child: Card(
          color: theme.colorScheme.errorContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12.0, // 12dp radius
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              16.0, // 16dp card padding
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                  size: 36.0, // 36dp error icon size
                ),
                const SizedBox(
                  height: 10.0, // 10dp spacing
                ),
                Text(
                  'Scan Error Encountered',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 6.0, // 6dp spacing
                ),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(
                  height: 12.0, // 12dp spacing
                ),
                FilledButton.tonal(
                  onPressed: () {
                    viewModel.startScan();
                  },
                  child: const Text('Retry Scan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
