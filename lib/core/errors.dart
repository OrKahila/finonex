/// The server rejected the username/password pair.
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'InvalidCredentialsException';
}

/// A protected endpoint answered 401. The token is dead or was never valid;
/// the caller is expected to refresh and retry exactly once.
class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() => 'UnauthorizedException';
}

/// Any transport-level failure talking to the feed server: socket errors,
/// timeouts, unexpected status codes, unparseable responses.
class TransportException implements Exception {
  const TransportException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'TransportException($message${statusCode == null ? '' : ', status: $statusCode'})';
}

/// We have no stored credentials, so the user must log in interactively.
class NoStoredCredentialsException implements Exception {
  const NoStoredCredentialsException();

  @override
  String toString() => 'NoStoredCredentialsException';
}
