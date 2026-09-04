import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';

/// A bearer token and the moment it dies.
///
/// The server sends `expiresIn` (seconds); we resolve it against the injected
/// clock at the moment of login so expiry can be reasoned about - and frozen -
/// in tests.
@freezed
abstract class Session with _$Session {
  const factory Session({
    required String token,
    required DateTime expiresAt,
  }) = _Session;

  const Session._();

  /// Usable if it will still be valid [grace] from now. The grace window stops
  /// us opening a stream with a token that dies during the handshake.
  bool isUsableAt(DateTime now, Duration grace) =>
      expiresAt.subtract(grace).isAfter(now);

  Duration remainingAt(DateTime now) => expiresAt.difference(now);
}
