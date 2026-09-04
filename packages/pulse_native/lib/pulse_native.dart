/// Platform channel access to iOS Keychain and NWPathMonitor.
///
/// Usage:
/// ```dart
/// await PulseNativePlatform.instance.writeSecret(key: 'token', value: jwt);
/// PulseNativePlatform.instance.networkStatus().listen(...);
/// ```
library;

export 'src/in_memory_pulse_native.dart';
export 'src/method_channel_pulse_native.dart';
export 'src/network_status.dart';
export 'src/pulse_native_platform.dart';
export 'src/secure_storage_exception.dart';
