import 'package:flutter/material.dart';
import '../viewmodels/scanner_viewmodel.dart';
import 'widgets/scan_control_header.dart';
import 'widgets/scan_stats_bar.dart';
import 'widgets/service_list_view.dart';
import 'widgets/service_search_bar.dart';

/// Main screen for the Multicast DNS network scanner application using MVVM architecture.
class ScannerScreen extends StatefulWidget {
  /// Creates a [ScannerScreen] with an optional injected [ScannerViewModel] (useful for testing).
  const ScannerScreen({
    super.key,
    this.viewModel,
  });

  /// Optional injected ViewModel. If null, an instance is instantiated internally.
  final ScannerViewModel? viewModel;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final ScannerViewModel _viewModel;
  late final bool _isInternalViewModel;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _isInternalViewModel = false;
    } else {
      _viewModel = ScannerViewModel();
      _isInternalViewModel = true;
    }
  }

  @override
  void dispose() {
    if (_isInternalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Note: No setState is ever called here. All state transitions and list updates
    // are isolated strictly to their respective leaf widgets below.
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'mDNS Network Scanner',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0, // 18sp title size
              ),
            ),
            Text(
              'DNS-SD Multicast Discovery',
              style: TextStyle(
                fontSize: 11.0, // 11sp subtitle font size
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              size: 22.0, // 22dp info icon size
            ),
            tooltip: 'About Scanner',
            onPressed: () {
              _showAboutDialog(context);
            },
          ),
        ],
        elevation: 0.0, // 0dp elevation for flat app bar
        scrolledUnderElevation: 2.0, // 2dp elevation when content scrolls under
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Leaf Widget: Scan Control Header (Presets, Custom Mode, Start/Stop/Clear)
            ScanControlHeader(viewModel: _viewModel),

            // Leaf Widget: Telemetry Metrics & Progress Bar
            ScanStatsBar(viewModel: _viewModel),

            // Leaf Widget: Search & Category Filter Chips
            ServiceSearchBar(viewModel: _viewModel),

            // Leaf Widget: Scrollable Results List View
            Expanded(
              child: ServiceListView(viewModel: _viewModel),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.network_check),
              SizedBox(
                width: 8.0, // 8dp spacing
              ),
              Text('About mDNS Scanner'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This application utilizes the multicast_dns package to perform RFC 6762 / RFC 6763 Multicast DNS and DNS-Based Service Discovery on local subnets.\n',
              ),
              Text(
                'Architecture Highlights:\n'
                '• MVVM Pattern with granular ValueNotifiers\n'
                '• Zero setState tight-loop thrashing via rate-limited batching\n'
                '• Leaf-isolated widget tree refreshes\n'
                '• Android SDK 16 compatibility',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
