import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import '../models/mdns_service_item.dart';
import '../models/scan_state.dart';
import '../models/scan_statistics.dart';
import '../services/mdns_scanner_service.dart';
import '../services/service_types.dart';

/// ViewModel managing mDNS discovery lifecycle, state batching, filtering, and telemetry.
class ScannerViewModel extends ChangeNotifier {
  /// Creates a [ScannerViewModel] with injected [IMdnsScannerService] and optional batch interval.
  ScannerViewModel({
    IMdnsScannerService? scannerService,
    Duration? batchFlushInterval,
  })  : _scannerService = scannerService ?? MdnsScannerService(),
        _batchFlushInterval = batchFlushInterval ??
            const Duration(
              milliseconds: 150, // 150ms batching interval prevents UI thread thrashing
            );

  final IMdnsScannerService _scannerService;
  final Duration _batchFlushInterval;

  // Granular ValueNotifiers to enable leaf widget rebuild isolation
  final ValueNotifier<ScanStatus> _statusNotifier =
      ValueNotifier<ScanStatus>(ScanStatus.idle);
  final ValueNotifier<List<MdnsServiceItem>> _itemsNotifier =
      ValueNotifier<List<MdnsServiceItem>>(<MdnsServiceItem>[]);
  final ValueNotifier<ScanStatistics> _statsNotifier =
      ValueNotifier<ScanStatistics>(const ScanStatistics());
  final ValueNotifier<MdnsServiceItem?> _selectedItemNotifier =
      ValueNotifier<MdnsServiceItem?>(null);
  final ValueNotifier<String> _searchQueryNotifier =
      ValueNotifier<String>('');
  final ValueNotifier<String> _selectedTypeFilterNotifier =
      ValueNotifier<String>('All');
  final ValueNotifier<String?> _errorNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<bool> _isCustomTypeModeNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<String> _customServiceTypeNotifier =
      ValueNotifier<String>('_workstation._tcp.local');
  final ValueNotifier<String> _selectedScanTypeNotifier =
      ValueNotifier<String>(ServiceTypes.dnsSdMetaQuery);

  // Public ValueListenable accessors
  ValueListenable<ScanStatus> get statusNotifier => _statusNotifier;
  ValueListenable<List<MdnsServiceItem>> get itemsNotifier => _itemsNotifier;
  ValueListenable<ScanStatistics> get statsNotifier => _statsNotifier;
  ValueListenable<MdnsServiceItem?> get selectedItemNotifier =>
      _selectedItemNotifier;
  ValueListenable<String> get searchQueryNotifier => _searchQueryNotifier;
  ValueListenable<String> get selectedTypeFilterNotifier =>
      _selectedTypeFilterNotifier;
  ValueListenable<String?> get errorNotifier => _errorNotifier;
  ValueListenable<bool> get isCustomTypeModeNotifier =>
      _isCustomTypeModeNotifier;
  ValueListenable<String> get customServiceTypeNotifier =>
      _customServiceTypeNotifier;
  ValueListenable<String> get selectedScanTypeNotifier =>
      _selectedScanTypeNotifier;

  // Internal storage
  final Map<String, MdnsServiceItem> _allDiscoveredServices =
      <String, MdnsServiceItem>{};
  final Map<String, MdnsServiceItem> _pendingBatchBuffer =
      <String, MdnsServiceItem>{};

  StreamSubscription<MdnsServiceItem>? _scanSubscription;
  Timer? _batchTimer;
  Timer? _elapsedTimer;
  DateTime? _scanStartTime;
  int _packetsCount = 0;
  int _typesQueriedCount = 0;

  /// Whether a scan is currently active.
  bool get isScanning => _statusNotifier.value == ScanStatus.scanning;

  /// Starts an mDNS scan operation.
  Future<void> startScan({
    List<String>? serviceTypes,
    Duration? timeout,
  }) async {
    // If already scanning, stop current scan first
    if (isScanning) {
      await stopScan();
    }

    _errorNotifier.value = null;
    _statusNotifier.value = ScanStatus.scanning;
    _scanStartTime = DateTime.now();
    _packetsCount = 0;

    List<String> targetTypes;
    if (serviceTypes != null && serviceTypes.isNotEmpty) {
      targetTypes = serviceTypes;
    } else if (_isCustomTypeModeNotifier.value &&
        _customServiceTypeNotifier.value.trim().isNotEmpty) {
      targetTypes = [_customServiceTypeNotifier.value.trim()];
    } else if (_selectedScanTypeNotifier.value == ServiceTypes.dnsSdMetaQuery) {
      targetTypes = ServiceTypes.defaultScanTypes;
    } else {
      targetTypes = [_selectedScanTypeNotifier.value];
    }

    _typesQueriedCount = targetTypes.length;
    _updateStats();

    // Start periodic batch timer to flush accumulated stream events at fixed intervals
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchFlushInterval, (_) {
      _flushBatch();
    });

    // Start 1-second interval timer for elapsed scan duration updates
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(
      const Duration(
        seconds: 1, // 1-second tick for duration counter
      ),
      (_) {
        _updateDuration();
      },
    );

    try {
      final stream = _scannerService.scan(
        serviceTypes: targetTypes,
        queryTimeout: timeout ??
            const Duration(
              seconds: 5, // 5-second query timeout
            ),
      );

      _scanSubscription = stream.listen(
        _onServiceDiscovered,
        onError: (dynamic error, StackTrace stackTrace) {
          developer.log(
            'Scan stream error: $error',
            name: 'ScannerViewModel',
            error: error,
            stackTrace: stackTrace,
          );
          _errorNotifier.value = error.toString();
          _statusNotifier.value = ScanStatus.error;
          _stopTimers();
        },
        onDone: () {
          _flushBatch();
          _stopTimers();
          if (_statusNotifier.value != ScanStatus.error) {
            _statusNotifier.value = ScanStatus.completed;
          }
        },
        cancelOnError: false,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to start scanner: $e',
        name: 'ScannerViewModel',
        error: e,
        stackTrace: stackTrace,
      );
      _errorNotifier.value = e.toString();
      _statusNotifier.value = ScanStatus.error;
      _stopTimers();
    }
  }

  void _onServiceDiscovered(MdnsServiceItem item) {
    _packetsCount++;
    // Buffer item instead of directly notifying listeners to avoid tight-loop UI redraws
    _pendingBatchBuffer[item.id] = item;
  }

  void _flushBatch() {
    if (_pendingBatchBuffer.isEmpty) {
      return;
    }

    _allDiscoveredServices.addAll(_pendingBatchBuffer);
    _pendingBatchBuffer.clear();
    _recomputeFilteredItems();
    _updateStats();
  }

  void _updateDuration() {
    if (_scanStartTime == null) return;
    final elapsed = DateTime.now().difference(_scanStartTime!);
    _statsNotifier.value = _statsNotifier.value.copyWith(
      duration: elapsed,
    );
  }

  void _updateStats() {
    final elapsed = _scanStartTime != null
        ? DateTime.now().difference(_scanStartTime!)
        : Duration.zero;

    _statsNotifier.value = ScanStatistics(
      totalDiscovered: _allDiscoveredServices.length,
      typesScanned: _typesQueriedCount,
      packetsReceived: _packetsCount,
      duration: elapsed,
    );
  }

  void _recomputeFilteredItems() {
    final query = _searchQueryNotifier.value.trim().toLowerCase();
    final typeFilter = _selectedTypeFilterNotifier.value;

    final filtered = _allDiscoveredServices.values.where((item) {
      // Type category filter
      if (typeFilter != 'All' && item.serviceType != typeFilter) {
        return false;
      }

      // Query filter
      if (query.isEmpty) {
        return true;
      }

      final matchesName = item.displayName.toLowerCase().contains(query);
      final matchesHost = item.hostTarget.toLowerCase().contains(query);
      final matchesType = item.serviceType.toLowerCase().contains(query);
      final matchesPort = item.port.toString().contains(query);
      final matchesIp = item.allIpAddresses.any(
        (ip) => ip.toLowerCase().contains(query),
      );

      return matchesName || matchesHost || matchesType || matchesPort || matchesIp;
    }).toList();

    // Sort items alphabetically by display name
    filtered.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    _itemsNotifier.value = List<MdnsServiceItem>.unmodifiable(filtered);
  }

  /// Sets the active search filter query.
  void setSearchQuery(String query) {
    if (_searchQueryNotifier.value != query) {
      _searchQueryNotifier.value = query;
      _recomputeFilteredItems();
    }
  }

  /// Sets the active service type category filter ('All' or specific type).
  void setTypeFilter(String type) {
    if (_selectedTypeFilterNotifier.value != type) {
      _selectedTypeFilterNotifier.value = type;
      _recomputeFilteredItems();
    }
  }

  /// Sets the selected scan target type preset.
  void setSelectedScanType(String type) {
    _selectedScanTypeNotifier.value = type;
  }

  /// Toggles custom service type entry mode.
  void setCustomTypeMode(bool enabled) {
    _isCustomTypeModeNotifier.value = enabled;
  }

  /// Sets the custom service type string.
  void setCustomServiceType(String type) {
    _customServiceTypeNotifier.value = type;
  }

  /// Selects a service item for viewing details or actions.
  void selectItem(MdnsServiceItem? item) {
    _selectedItemNotifier.value = item;
  }

  /// Clears all discovered items and resets telemetry.
  void clearResults() {
    _allDiscoveredServices.clear();
    _pendingBatchBuffer.clear();
    _itemsNotifier.value = const <MdnsServiceItem>[];
    _selectedItemNotifier.value = null;
    _errorNotifier.value = null;
    _packetsCount = 0;
    _statsNotifier.value = const ScanStatistics();
  }

  /// Stops an in-progress scan and flushes any pending results.
  Future<void> stopScan() async {
    _stopTimers();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    try {
      await _scannerService.stopScan();
    } catch (e) {
      developer.log('Error stopping scanner service: $e', name: 'ScannerViewModel', error: e);
    }

    _flushBatch();
    if (_statusNotifier.value == ScanStatus.scanning) {
      _statusNotifier.value = ScanStatus.completed;
    }
  }

  void _stopTimers() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  @override
  void dispose() {
    _stopTimers();
    _scanSubscription?.cancel();
    _scannerService.stopScan();

    _statusNotifier.dispose();
    _itemsNotifier.dispose();
    _statsNotifier.dispose();
    _selectedItemNotifier.dispose();
    _searchQueryNotifier.dispose();
    _selectedTypeFilterNotifier.dispose();
    _errorNotifier.dispose();
    _isCustomTypeModeNotifier.dispose();
    _customServiceTypeNotifier.dispose();
    _selectedScanTypeNotifier.dispose();

    super.dispose();
  }
}
