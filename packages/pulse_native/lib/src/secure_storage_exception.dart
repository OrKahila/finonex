/// Thrown when the platform's secure store rejects an operation.
///
/// Native errors (OSStatus on iOS) are mapped to a stable [code] so Dart-side
/// callers never have to know which platform they are talking to.
class SecureStorageException implements Exception {
  const SecureStorageException(this.code, [this.message, this.details]);

  final String code;
  final String? message;
  final Object? details;

  @override
  String toString() => 'SecureStorageException($code): ${message ?? ''}';
}
