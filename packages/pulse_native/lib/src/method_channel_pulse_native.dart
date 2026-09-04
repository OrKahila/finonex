import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'network_status.dart';
import 'pulse_native_platform.dart';
import 'secure_storage_exception.dart';

/// iOS implementation: Keychain over a [MethodChannel], NWPathMonitor over an
/// [EventChannel].
class MethodChannelPulseNative extends PulseNativePlatform {
  @visibleForTesting
  static const MethodChannel methodChannel =
      MethodChannel('pulse_native/secure_storage');

  @visibleForTesting
  static const EventChannel eventChannel =
      EventChannel('pulse_native/reachability');

  Stream<NetworkStatus>? _networkStatus;

  @override
  bool get hasNativeSecureStorage => true;

  @override
  Future<void> writeSecret({
    required String key,
    required String value,
  }) async {
    await _guard(() => methodChannel.invokeMethod<void>('write', {
          'key': key,
          'value': value,
        }));
  }

  @override
  Future<String?> readSecret(String key) {
    return _guard(
      () => methodChannel.invokeMethod<String>('read', {'key': key}),
    );
  }

  @override
  Future<void> deleteSecret(String key) async {
    await _guard(
      () => methodChannel.invokeMethod<void>('delete', {'key': key}),
    );
  }

  @override
  Future<void> deleteAllSecrets() async {
    await _guard(() => methodChannel.invokeMethod<void>('deleteAll'));
  }

  @override
  Stream<NetworkStatus> networkStatus() {
    // Broadcast + cached so several listeners share one native monitor.
    return _networkStatus ??= eventChannel
        .receiveBroadcastStream()
        .map((Object? event) =>
            NetworkStatus.fromMap((event as Map).cast<Object?, Object?>()))
        .asBroadcastStream();
  }

  /// Turns channel failures into our own exception type. A missing plugin
  /// (wrong platform, or a hot restart before registration) is reported
  /// distinctly because it is a wiring bug, not a storage failure.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on MissingPluginException catch (error) {
      throw SecureStorageException('unavailable', 'Plugin not registered', error);
    } on PlatformException catch (error) {
      throw SecureStorageException(error.code, error.message, error.details);
    }
  }
}
