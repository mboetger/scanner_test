import 'package:flutter/material.dart';
import '../../models/scan_state.dart';
import '../../services/service_types.dart';
import '../../viewmodels/scanner_viewmodel.dart';

/// Leaf widget providing interactive controls to configure and launch network scans.
class ScanControlHeader extends StatelessWidget {
  /// Creates a [ScanControlHeader] with the target [ScannerViewModel].
  const ScanControlHeader({
    super.key,
    required this.viewModel,
  });

  /// The ViewModel driving scan control actions.
  final ScannerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0, // 16dp standard horizontal container padding
        vertical: 10.0, // 10dp vertical container padding
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: 0.5, // 50% opacity for subtle bottom header divider
            ),
            width: 1.0, // 1dp divider border width
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Service Type Preset Selector Row
          ValueListenableBuilder<bool>(
            valueListenable: viewModel.isCustomTypeModeNotifier,
            builder: (context, isCustomMode, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Preset Dropdown
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: viewModel.selectedScanTypeNotifier,
                          builder: (context, selectedScanType, _) {
                            return DropdownButtonFormField<String>(
                              initialValue: isCustomMode ? null : selectedScanType,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Target Service Query',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, // 12dp internal dropdown padding
                                  vertical: 8.0, // 8dp vertical padding
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    8.0, // 8dp dropdown border radius
                                  ),
                                ),
                              ),
                              items: isCustomMode
                                  ? [
                                      const DropdownMenuItem<String>(
                                        value: 'custom',
                                        child: Text('Custom Query Mode'),
                                      ),
                                    ]
                                  : ServiceTypes.catalog.map((desc) {
                                      return DropdownMenuItem<String>(
                                        value: desc.serviceType,
                                        child: Row(
                                          children: [
                                            Icon(
                                              desc.icon,
                                              size: 18.0, // 18dp dropdown icon size
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(
                                              width: 8.0, // 8dp spacing
                                            ),
                                            Flexible(
                                              child: Text(
                                                desc.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              onChanged: isCustomMode
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        viewModel.setSelectedScanType(value);
                                      }
                                    },
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 8.0, // 8dp horizontal spacing
                      ),
                      // Custom Mode Toggle Button
                      IconButton.outlined(
                        icon: Icon(
                          isCustomMode ? Icons.list_alt : Icons.edit_note,
                          size: 20.0, // 20dp icon size
                        ),
                        tooltip: isCustomMode
                            ? 'Switch to Presets'
                            : 'Enter Custom Service Type',
                        onPressed: () {
                          viewModel.setCustomTypeMode(!isCustomMode);
                        },
                      ),
                    ],
                  ),
                  // Custom Service Type Input Field (when enabled)
                  if (isCustomMode) ...[
                    const SizedBox(
                      height: 8.0, // 8dp vertical spacing
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: viewModel.customServiceTypeNotifier,
                      builder: (context, customType, _) {
                        return TextFormField(
                          initialValue: customType,
                          decoration: InputDecoration(
                            labelText: 'Custom Service Type (FQDN format)',
                            hintText: '_workstation._tcp.local',
                            prefixIcon: const Icon(
                              Icons.edit,
                              size: 18.0, // 18dp icon size
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0, // 12dp padding
                              vertical: 8.0, // 8dp padding
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                8.0, // 8dp radius
                              ),
                            ),
                          ),
                          onChanged: (text) {
                            viewModel.setCustomServiceType(text);
                          },
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(
            height: 10.0, // 10dp vertical spacing before action buttons
          ),

          // Action Buttons: Scan / Stop and Clear
          ValueListenableBuilder<ScanStatus>(
            valueListenable: viewModel.statusNotifier,
            builder: (context, scanStatus, _) {
              final isScanning = scanStatus == ScanStatus.scanning;

              return Row(
                children: [
                  // Start / Stop Primary Button
                  Expanded(
                    flex: 3, // 3:1 button width proportion
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isScanning
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        foregroundColor: isScanning
                            ? theme.colorScheme.onError
                            : theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0, // 12dp button vertical padding
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            8.0, // 8dp rounded corner
                          ),
                        ),
                      ),
                      icon: isScanning
                          ? const SizedBox(
                              width: 18.0, // 18dp spinner width
                              height: 18.0, // 18dp spinner height
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0, // 2dp indicator stroke
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.play_arrow,
                              size: 22.0, // 22dp play icon size
                            ),
                      label: Text(
                        isScanning ? 'Stop Scan' : 'Start Scan',
                        style: const TextStyle(
                          fontSize: 15.0, // 15sp button text size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        if (isScanning) {
                          viewModel.stopScan();
                        } else {
                          viewModel.startScan();
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 8.0, // 8dp horizontal spacing
                  ),
                  // Clear Results Button
                  Expanded(
                    flex: 1, // 1 flex unit
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0, // 12dp vertical padding
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            8.0, // 8dp radius
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.clear_all,
                        size: 20.0, // 20dp icon size
                      ),
                      label: const Text('Clear'),
                      onPressed: isScanning
                          ? null
                          : () {
                              viewModel.clearResults();
                            },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
