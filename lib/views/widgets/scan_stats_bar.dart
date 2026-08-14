import 'package:flutter/material.dart';
import '../../models/scan_state.dart';
import '../../models/scan_statistics.dart';
import '../../viewmodels/scanner_viewmodel.dart';

/// Leaf widget rendering telemetry metrics and status indicator without parent rebuilds.
class ScanStatsBar extends StatelessWidget {
  /// Creates a [ScanStatsBar] observing [ScannerViewModel].
  const ScanStatsBar({
    super.key,
    required this.viewModel,
  });

  /// The ViewModel providing stats and status listenables.
  final ScannerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0, // 16dp horizontal padding
            vertical: 8.0, // 8dp vertical padding
          ),
          color: theme.colorScheme.surfaceContainerLow,
          child: ValueListenableBuilder<ScanStatistics>(
            valueListenable: viewModel.statsNotifier,
            builder: (context, stats, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Discovered count
                  _buildMetric(
                    context,
                    icon: Icons.check_circle_outline,
                    label: 'Discovered',
                    value: '${stats.totalDiscovered}',
                    color: theme.colorScheme.primary,
                  ),
                  // Queried types count
                  _buildMetric(
                    context,
                    icon: Icons.radar,
                    label: 'Protocols',
                    value: '${stats.typesScanned}',
                    color: theme.colorScheme.secondary,
                  ),
                  // Raw packets count
                  _buildMetric(
                    context,
                    icon: Icons.swap_vert,
                    label: 'Packets',
                    value: '${stats.packetsReceived}',
                    color: theme.colorScheme.tertiary,
                  ),
                  // Elapsed time
                  _buildMetric(
                    context,
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: _formatDuration(stats.duration),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              );
            },
          ),
        ),
        // Linear Progress Bar (shown only while active scanning)
        ValueListenableBuilder<ScanStatus>(
          valueListenable: viewModel.statusNotifier,
          builder: (context, scanStatus, _) {
            if (scanStatus == ScanStatus.scanning) {
              return const LinearProgressIndicator(
                minHeight: 2.5, // 2.5dp subtle progress indicator height
              );
            }
            return const SizedBox(
              height: 2.5, // 2.5dp empty placeholder spacing to prevent layout jumps
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16.0, // 16dp compact icon size
          color: color,
        ),
        const SizedBox(
          width: 4.0, // 4dp horizontal spacing
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.0, // 10sp caption text size
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.0, // 13sp metric value text size
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes
        .remainder(60) // 60 minutes per hour
        .toString()
        .padLeft(2, '0'); // 2 digit padded minute
    final seconds = d.inSeconds
        .remainder(60) // 60 seconds per minute
        .toString()
        .padLeft(2, '0'); // 2 digit padded second
    return '$minutes:$seconds';
  }
}
