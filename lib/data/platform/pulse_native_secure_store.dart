import 'package:injectable/injectable.dart';
import 'package:pulse_native/pulse_native.dart';

import '../../domain/ports/secure_store.dart';

@LazySingleton(as: SecureStore)
class PulseNativeSecureStore implements SecureStore {
  PulseNativeSecureStore(this._platform);

  final PulseNativePlatform _platform;

  @override
  bool get isBackedByPlatform => _platform.hasNativeSecureStorage;

  @override
  Future<void> write(String key, String value) =>
      _platform.writeSecret(key: key, value: value);

  @override
  Future<String?> read(String key) => _platform.readSecret(key);

  @override
  Future<void> delete(String key) => _platform.deleteSecret(key);

  @override
  Future<void> deleteAll() => _platform.deleteAllSecrets();
}
