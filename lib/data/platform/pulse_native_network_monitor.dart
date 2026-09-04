import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:pulse_native/pulse_native.dart';

import '../../domain/ports/network_monitor.dart';

/// Adapts the plugin's EventChannel stream to the app's [NetworkMonitor] port.
///
/// Two things happen here that the raw channel does not give us:
/// identical repeats are dropped (the reconnect logic must not be woken by a
/// no-op), and the latest value is cached so late subscribers and synchronous
/// callers both see the current state.
@LazySingleton(as: NetworkMonitor)
class PulseNativeNetworkMonitor implements NetworkMonitor {
  PulseNativeNetworkMonitor(this._platform) {
    _subscription = _platform.networkStatus().listen(
      (NetworkStatus status) {
        if (status == _current) return;
        _current = status;
        _controller.add(status);
      },
      onError: (Object _) {
        // A dead reachability channel must not take the feed down with it.
        // Assuming "online" keeps reconnects flowing.
        if (_current == NetworkStatus.assumedOnline) return;
        _current = NetworkStatus.assumedOnline;
        _controller.add(_current);
      },
    );
  }

  final PulseNativePlatform _platform;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  StreamSubscription<NetworkStatus>? _subscription;
  NetworkStatus _current = NetworkStatus.assumedOnline;

  @override
  NetworkStatus get current => _current;

  @override
  Stream<NetworkStatus> get statuses async* {
    yield _current;
    yield* _controller.stream;
  }

  @disposeMethod
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller.close();
  }
}
