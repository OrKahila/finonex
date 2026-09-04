import 'dart:io' show Platform;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'in_memory_pulse_native.dart';
import 'method_channel_pulse_native.dart';
import 'network_status.dart';

/// The Dart-facing contract for everything this plugin does natively.
///
/// Only iOS is implemented today. Adding Android means writing one subclass
/// (backed by EncryptedSharedPreferences + ConnectivityManager) and selecting
/// it in [_defaultInstance] - nothing above this line changes. That is the
/// whole point of the indirection.
abstract class PulseNativePlatform extends PlatformInterface {
  PulseNativePlatform() : super(token: _token);

  static final Object _token = Object();

  static PulseNativePlatform _instance = _defaultInstance();

  static PulseNativePlatform get instance => _instance;

  /// Subclasses must be registered here before use. Guarded by [_token] so a
  /// third party cannot swap in an implementation that bypasses this contract.
  static set instance(PulseNativePlatform value) {
    PlatformInterface.verifyToken(value, _token);
    _instance = value;
  }

  static PulseNativePlatform _defaultInstance() {
    if (Platform.isIOS) return MethodChannelPulseNative();
    // Every other platform gets a loud, in-memory stub so the app still runs.
    return InMemoryPulseNative();
  }

  /// True when the current platform actually persists secrets to hardware or
  /// OS-backed secure storage. The UI uses this to warn on stub platforms.
  bool get hasNativeSecureStorage;

  Future<void> writeSecret({required String key, required String value});

  Future<String?> readSecret(String key);

  Future<void> deleteSecret(String key);

  /// Clears every secret this app owns. Used on logout.
  Future<void> deleteAllSecrets();

  /// Reachability, hot on subscribe: the first event is the current state, not
  /// the next change. Callers must not have to wait for the network to move
  /// before they know where they stand.
  Stream<NetworkStatus> networkStatus();
}
