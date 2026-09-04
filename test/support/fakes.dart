import 'dart:async';
import 'dart:math';

import 'package:finonex/core/clock.dart';
import 'package:finonex/core/errors.dart';
import 'package:finonex/data/auth/auth_api.dart';
import 'package:finonex/data/auth/models/session.dart';
import 'package:finonex/data/feed/conflation_scheduler.dart';
import 'package:finonex/data/feed/sse/sse_message.dart';
import 'package:finonex/data/feed/sse/sse_transport.dart';
import 'package:finonex/data/feed/tick.dart';
import 'package:finonex/domain/ports/network_monitor.dart';
import 'package:finonex/domain/ports/secure_store.dart';
import 'package:finonex/domain/ports/tick_sink.dart';
import 'package:pulse_native/pulse_native.dart';

/// Reads its time from FakeAsync's elapsed counter, so wall-clock logic and
/// timer logic advance in lockstep under `fakeAsync`.
class FakeClock implements Clock {
  FakeClock(this.start, this.elapsed);

  final DateTime start;
  final Duration Function() elapsed;

  @override
  DateTime now() => start.add(elapsed());
}

/// A clock the test moves by hand, for logic that has no timers.
class MutableClock implements Clock {
  MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;

  void advance(Duration duration) => value = value.add(duration);
}

/// A [Random] with no randomness, so jittered delays are exact in tests.
/// 0.5 maps to a jitter factor of exactly 1.0.
class FixedRandom implements Random {
  FixedRandom([this.value = 0.5]);

  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  int nextInt(int max) => (value * max).floor();
}

class FakeSecureStore implements SecureStore {
  final Map<String, String> values = <String, String>{};

  @override
  bool get isBackedByPlatform => true;

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();
}

/// Hands out sequentially numbered tokens with a configurable TTL.
class FakeAuthApi implements AuthApi {
  FakeAuthApi(this._clock, {this.ttl = const Duration(seconds: 60)});

  final Clock _clock;
  final Duration ttl;

  int calls = 0;
  final List<String> issuedTokens = <String>[];

  /// Thrown on the next login only.
  Object? failOnce;

  /// Thrown on every login until cleared.
  Object? failAlways;

  @override
  Future<Session> login({
    required String username,
    required String password,
  }) async {
    calls++;
    final Object? error = failOnce ?? failAlways;
    if (failOnce != null) failOnce = null;
    if (error != null) throw error;

    if (username != 'trader' || password != 'password123') {
      throw const InvalidCredentialsException();
    }

    final String token = 'token-$calls';
    issuedTokens.add(token);
    return Session(token: token, expiresAt: _clock.now().add(ttl));
  }
}

class FakeSseConnection implements SseConnection {
  final StreamController<SseMessage> _controller =
      StreamController<SseMessage>();

  bool closedByClient = false;

  @override
  Stream<SseMessage> get messages => _controller.stream;

  @override
  Future<void> close() async {
    closedByClient = true;
    if (!_controller.isClosed) await _controller.close();
  }

  void send(SseMessage message) {
    if (!_controller.isClosed) _controller.add(message);
  }

  void sendTick({
    required int id,
    String symbol = 'EURUSD',
    double bid = 1.0,
    double ask = 1.1,
    required int ts,
  }) {
    send(SseEvent(
      id: id,
      event: 'tick',
      data: '{"s":"$symbol","b":$bid,"a":$ask,"ts":$ts}',
    ));
  }

  void sendHeartbeat() => send(const SseComment('ping'));

  /// The server hanging up.
  void disconnect() {
    if (!_controller.isClosed) _controller.close();
  }
}

class FakeSseTransport implements SseTransport {
  final List<({String token, int? lastEventId})> attempts =
      <({String token, int? lastEventId})>[];
  final List<FakeSseConnection> connections = <FakeSseConnection>[];

  Object? failOnce;
  Object? failAlways;

  FakeSseConnection get latest => connections.last;

  @override
  Future<SseConnection> connect({
    required String token,
    int? lastEventId,
  }) async {
    attempts.add((token: token, lastEventId: lastEventId));

    final Object? error = failOnce ?? failAlways;
    if (failOnce != null) failOnce = null;
    if (error != null) throw error;

    final FakeSseConnection connection = FakeSseConnection();
    connections.add(connection);
    return connection;
  }
}

class FakeNetworkMonitor implements NetworkMonitor {
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _current = NetworkStatus.assumedOnline;

  @override
  NetworkStatus get current => _current;

  @override
  Stream<NetworkStatus> get statuses async* {
    yield _current;
    yield* _controller.stream;
  }

  void set(NetworkStatus status) {
    _current = status;
    _controller.add(status);
  }

  void goOffline() => set(NetworkStatus.offline);

  void goOnline() => set(const NetworkStatus(
        isOnline: true,
        interface: NetworkInterfaceKind.wifi,
        isExpensive: false,
      ));

  @override
  Future<void> dispose() => _controller.close();
}

class RecordingTickSink implements TickSink {
  final List<Tick> ticks = <Tick>[];
  int malformed = 0;

  @override
  void add(Tick tick) => ticks.add(tick);

  @override
  void noteMalformed() => malformed++;
}

/// Flushes only when the test says so.
class ManualConflationScheduler implements ConflationScheduler {
  void Function()? _pending;
  int scheduleCalls = 0;

  @override
  void schedule(void Function() flush) {
    scheduleCalls++;
    _pending = flush;
  }

  /// Runs the pending flush, if any. Returns true if there was one.
  bool flush() {
    final void Function()? pending = _pending;
    if (pending == null) return false;
    _pending = null;
    pending();
    return true;
  }

  @override
  void dispose() => _pending = null;
}
