/// The app's view of platform secure storage.
///
/// Deliberately narrower than the plugin's API: the app only ever needs these
/// four operations, and depending on a local port (rather than on
/// `PulseNativePlatform` directly) keeps domain code free of plugin types and
/// makes fakes a two-line affair in tests.
abstract class SecureStore {
  Future<void> write(String key, String value);

  Future<String?> read(String key);

  Future<void> delete(String key);

  Future<void> deleteAll();

  /// False when the current platform has no native implementation, so the UI
  /// can warn that secrets are not actually being persisted securely.
  bool get isBackedByPlatform;
}
