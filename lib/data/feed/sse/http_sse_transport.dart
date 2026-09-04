import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../core/app_config.dart';
import '../../../core/errors.dart';
import 'sse_message.dart';
import 'sse_parser.dart';
import 'sse_transport.dart';

@LazySingleton(as: SseTransport)
class HttpSseTransport implements SseTransport {
  HttpSseTransport(this._client, this._config);

  /// Applies to opening the stream only. There is deliberately no timeout on
  /// the stream itself: silence is the stall watchdog's business, and it knows
  /// the difference between "quiet" and "dead".
  static const Duration _connectTimeout = Duration(seconds: 10);

  final HttpClient _client;
  final AppConfig _config;

  @override
  Future<SseConnection> connect({
    required String token,
    int? lastEventId,
  }) async {
    final HttpClientRequest request;
    final HttpClientResponse response;
    try {
      request = await _client
          .getUrl(_config.endpoint('/stream'))
          .timeout(_connectTimeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      if (lastEventId != null) {
        request.headers.set('Last-Event-ID', '$lastEventId');
      }
      response = await request.close().timeout(_connectTimeout);
    } on Object catch (error) {
      throw TransportException('Could not open stream: $error');
    }

    if (response.statusCode == HttpStatus.unauthorized) {
      unawaited(response.drain<void>().catchError((Object _) {}));
      throw const UnauthorizedException();
    }
    if (response.statusCode != HttpStatus.ok) {
      unawaited(response.drain<void>().catchError((Object _) {}));
      throw TransportException(
        'Stream refused',
        statusCode: response.statusCode,
      );
    }

    return _HttpSseConnection(response);
  }
}

class _HttpSseConnection implements SseConnection {
  _HttpSseConnection(this._response) {
    _subscription = decodeSseStream(_response).listen(
      _controller.add,
      onError: _controller.addError,
      onDone: () {
        if (!_controller.isClosed) _controller.close();
      },
      cancelOnError: true,
    );
  }

  final HttpClientResponse _response;
  final StreamController<SseMessage> _controller =
      StreamController<SseMessage>();

  late final StreamSubscription<SseMessage> _subscription;
  bool _closed = false;

  @override
  Stream<SseMessage> get messages => _controller.stream;

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    // Cancelling an in-flight response subscription destroys the socket, which
    // is what we want: a stalled connection must actually go away, not linger.
    await _subscription.cancel();
    if (!_controller.isClosed) await _controller.close();
  }
}
