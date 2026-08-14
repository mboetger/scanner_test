/// Represents the lifecycle states of an mDNS network discovery scan.
enum ScanStatus {
  /// Scan is not currently running.
  idle,

  /// Scan is actively issuing queries and listening for responses.
  scanning,

  /// Scan has completed its search duration.
  completed,

  /// Scan encountered an error.
  error,
}

/// Holds the current state of a network scan operation.
class ScanState {
  /// Creates a [ScanState] with status, start time, end time, and optional error message.
  const ScanState({
    this.status = ScanStatus.idle,
    this.startedAt,
    this.finishedAt,
    this.errorMessage,
  });

  /// The current status of the scan.
  final ScanStatus status;

  /// The timestamp when the current/last scan started.
  final DateTime? startedAt;

  /// The timestamp when the scan concluded.
  final DateTime? finishedAt;

  /// Error message if [status] is [ScanStatus.error].
  final String? errorMessage;

  /// Whether a scan is currently running.
  bool get isScanning => status == ScanStatus.scanning;

  /// Returns a copy of [ScanState] with updated fields.
  ScanState copyWith({
    ScanStatus? status,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? errorMessage,
  }) {
    return ScanState(
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
