import 'package:pulse_native/pulse_native.dart';

/// Device reachability, as far as the OS knows.
///
/// [NetworkStatus] is reused from the plugin rather than re-declared: it is a
/// plain value type with no platform coupling, and duplicating it would only
/// add a mapper with no seam worth having.
abstract class NetworkMonitor {
  /// Broadcast, and hot: the first event delivered to a new subscriber is the
  /// current state, not the next change.
  Stream<NetworkStatus> get statuses;

  /// Best known state right now. Starts as [NetworkStatus.assumedOnline] so we
  /// never refuse to connect just because the platform has not reported yet.
  NetworkStatus get current;

  /// Releases the native subscription. Part of the port because an
  /// implementation that holds an OS-level monitor has to be closable.
  Future<void> dispose();
}
