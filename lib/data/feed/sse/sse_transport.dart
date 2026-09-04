import 'sse_message.dart';

/// An open feed connection.
///
/// [messages] completes when the server hangs up - which, on this feed, it
/// always eventually does.
abstract class SseConnection {
  Stream<SseMessage> get messages;

  /// Tears the socket down from our side. Used when the stall watchdog
  /// decides a silent-but-open connection is worthless.
  Future<void> close();
}

/// Opens `/stream`.
///
/// An interface, not a concrete class, because the connection state machine is
/// tested against a fake that can disconnect, stall, duplicate and reorder on
/// command - no real server, no real sockets.
abstract class SseTransport {
  /// Throws [UnauthorizedException] on 401 and [TransportException] on
  /// anything else that stops a stream from opening.
  Future<SseConnection> connect({
    required String token,
    int? lastEventId,
  });
}
