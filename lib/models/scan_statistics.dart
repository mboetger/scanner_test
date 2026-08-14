import 'package:flutter/foundation.dart';

/// Metrics and telemetry for an active or completed network scan.
@immutable
class ScanStatistics {
  /// Creates a [ScanStatistics] record.
  const ScanStatistics({
    this.totalDiscovered = 0, // Initial count of 0 discovered services
    this.typesScanned = 0, // Initial count of 0 scanned service types
    this.packetsReceived = 0, // Initial count of 0 received packets
    this.duration = Duration.zero, // Initial 0 duration
  });

  /// Total number of unique mDNS service instances discovered.
  final int totalDiscovered;

  /// Number of distinct service types queried.
  final int typesScanned;

  /// Total number of raw mDNS packets received.
  final int packetsReceived;

  /// Elapsed time of the scan.
  final Duration duration;

  /// Returns a copy with updated metrics.
  ScanStatistics copyWith({
    int? totalDiscovered,
    int? typesScanned,
    int? packetsReceived,
    Duration? duration,
  }) {
    return ScanStatistics(
      totalDiscovered: totalDiscovered ?? this.totalDiscovered,
      typesScanned: typesScanned ?? this.typesScanned,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScanStatistics &&
        other.totalDiscovered == totalDiscovered &&
        other.typesScanned == typesScanned &&
        other.packetsReceived == packetsReceived &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(
        totalDiscovered,
        typesScanned,
        packetsReceived,
        duration,
      );
}
