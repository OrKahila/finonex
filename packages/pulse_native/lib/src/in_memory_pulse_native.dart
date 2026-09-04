import 'dart:async';

import 'package:flutter/foundation.dart';

import 'network_status.dart';
import 'pulse_native_platform.dart';

/// Stub used on every platform without a native implementation (today:
/// everything except iOS).
///
/// It keeps the app runnable for anyone who checks the repo out on Android or
/// desktop, but it is not secure storage and says so out loud. Secrets live in
/// process memory and die with the process.
class InMemoryPulseNative extends PulseNativePlatform {
  InMemoryPulseNative() {
    debugPrint(
      '[pulse_native] No native implementation for this platform. '
      'Secrets are held in memory only and reachability is assumed online.',
    );
  }

  final Map<String, String> _secrets = <String, String>{};

  @override
  bool get hasNativeSecureStorage => false;

  @override
  Future<void> writeSecret({required String key, required String value}) async {
    _secrets[key] = value;
  }

  @override
  Future<String?> readSecret(String key) async => _secrets[key];

  @override
  Future<void> deleteSecret(String key) async {
    _secrets.remove(key);
  }

  @override
  Future<void> deleteAllSecrets() async {
    _secrets.clear();
  }

  @override
  Stream<NetworkStatus> networkStatus() =>
      Stream<NetworkStatus>.value(NetworkStatus.assumedOnline);
}
