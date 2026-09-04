import 'package:fake_async/fake_async.dart';
import 'package:finonex/core/app_config.dart';
import 'package:finonex/core/errors.dart';
import 'package:finonex/data/auth/auth_repository.dart';
import 'package:finonex/data/feed/sse/sse_message.dart';
import 'package:finonex/domain/reconnect_policy.dart';
import 'package:finonex/presentation/blocs/feed/feed_connection_bloc.dart';
import 'package:finonex/presentation/blocs/feed/feed_event.dart';
import 'package:finonex/presentation/blocs/feed/feed_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_native/pulse_native.dart';

import '../support/fakes.dart';

const AppConfig config = AppConfig();

/// Everything the bloc needs, wired to fakes and to FakeAsync's clock.
class Harness {
  Harness(this.async, {Duration tokenTtl = const Duration(seconds: 60)}) {
    clock = FakeClock(DateTime.utc(2026, 1, 1, 12), () => async.elapsed);
    store = FakeSecureStore();
    store.values[AuthRepository.keyUsername] = 'trader';
    store.values[AuthRepository.keyPassword] = 'password123';
    api = FakeAuthApi(clock, ttl: tokenTtl);
    auth = AuthRepository(api, store, clock, config);
    bloc = FeedConnectionBloc(
      transport,
      auth,
      sink,
      monitor,
      ReconnectPolicy(config, FixedRandom()),
      config,
      clock,
    );
    bloc.stream.listen(states.add);
  }

  final FakeAsync async;
  final FakeSseTransport transport = FakeSseTransport();
  final RecordingTickSink sink = RecordingTickSink();
  final FakeNetworkMonitor monitor = FakeNetworkMonitor();
  final List<FeedState> states = <FeedState>[];

  late final FakeClock clock;
  late final FakeSecureStore store;
  late final FakeAuthApi api;
  late final AuthRepository auth;
  late final FeedConnectionBloc bloc;

  ConnectionPhase get phase => bloc.state.phase;
  int get attempts => transport.attempts.length;

  void start() {
    bloc.add(const FeedEvent.started());
    async.flushMicrotasks();
  }

  void elapse(Duration duration) {
    async.elapse(duration);
    async.flushMicrotasks();
  }

  /// Opens a connection and puts the bloc in the live phase.
  void connectAndGoLive({int id = 1, int ts = 1000}) {
    start();
    transport.latest.sendTick(id: id, ts: ts);
    async.flushMicrotasks();
  }

  /// Keeps the stream alive across [total] by heartbeating every 5s, the way
  /// the real server does.
  void keepAlive(Duration total) {
    Duration remaining = total;
    while (remaining > Duration.zero) {
      final Duration step =
          remaining < const Duration(seconds: 5) ? remaining : const Duration(seconds: 5);
      elapse(step);
      transport.latest.sendHeartbeat();
      async.flushMicrotasks();
      remaining -= step;
    }
  }

  void dispose() {
    bloc.close();
    async.flushMicrotasks();
  }
}

void main() {
  group('opening a connection', () {
    test('stays in connecting until data actually arrives', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..start();

        expect(h.attempts, 1);
        expect(h.phase, ConnectionPhase.connecting,
            reason: 'an open socket is not evidence of data');

        h.transport.latest.sendTick(id: 1, ts: 1000);
        async.flushMicrotasks();

        expect(h.phase, ConnectionPhase.live);
        h.dispose();
      });
    });

    test('a heartbeat alone is enough to prove the stream is alive', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..start();

        h.transport.latest.sendHeartbeat();
        async.flushMicrotasks();

        expect(h.phase, ConnectionPhase.live);
        h.dispose();
      });
    });

    test('ticks are forwarded to the sink, not carried in bloc state', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();
        final int statesAfterLive = h.states.length;

        for (int i = 2; i <= 51; i++) {
          h.transport.latest.sendTick(id: i, ts: 1000 + i);
        }
        async.flushMicrotasks();

        expect(h.sink.ticks.length, 51);
        // 50 ticks must not cost 50 UI states. The id advancing is the only
        // reason any state is emitted at all here.
        expect(h.states.length - statesAfterLive, lessThanOrEqualTo(50));
        expect(h.bloc.state.lastEventId, 51);
        h.dispose();
      });
    });

    test('malformed events are counted and do not kill the stream', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();

        h.transport.latest.send(
          const SseEvent(event: 'message', data: '###garbage-not-json###'),
        );
        async.flushMicrotasks();

        expect(h.sink.malformed, 1);
        expect(h.phase, ConnectionPhase.live);

        h.transport.latest.sendTick(id: 2, ts: 2000);
        async.flushMicrotasks();

        expect(h.sink.ticks.length, 2);
        h.dispose();
      });
    });
  });

  group('backoff', () {
    test('follows an exponential sequence capped at 15s', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async);
        h.transport.failAlways = const TransportException('refused');
        h.start();

        expect(h.attempts, 1);
        expect(h.phase, ConnectionPhase.reconnecting);

        const List<int> expectedDelaysMs = <int>[500, 1000, 2000, 4000, 8000, 15000, 15000];

        for (int i = 0; i < expectedDelaysMs.length; i++) {
          final int delay = expectedDelaysMs[i];

          // Nothing may happen a hair before the delay is up.
          h.elapse(Duration(milliseconds: delay - 1));
          expect(h.attempts, i + 1, reason: 'retried early at step $i');

          h.elapse(const Duration(milliseconds: 1));
          expect(h.attempts, i + 2, reason: 'missed retry at step $i');
        }

        h.dispose();
      });
    });

    test('a stream that stayed healthy resets the sequence', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async);
        h.transport.failOnce = const TransportException('refused');
        h.start();

        // First attempt failed, so the next delay would normally be 1s.
        h.elapse(const Duration(milliseconds: 500));
        expect(h.attempts, 2);

        h.transport.latest.sendTick(id: 1, ts: 1000);
        async.flushMicrotasks();
        h.keepAlive(config.backoffResetAfterHealthy + const Duration(seconds: 1));

        h.transport.latest.disconnect();
        async.flushMicrotasks();

        // Back to the base delay, not 1s.
        h.elapse(const Duration(milliseconds: 499));
        expect(h.attempts, 2);
        h.elapse(const Duration(milliseconds: 1));
        expect(h.attempts, 3);

        h.dispose();
      });
    });
  });

  group('stall detection', () {
    test('heartbeats keep the connection out of degraded', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();

        // Well past the 8s degrade threshold, but never 8s without traffic.
        h.keepAlive(const Duration(seconds: 30));

        expect(h.phase, ConnectionPhase.live);
        expect(h.attempts, 1);
        h.dispose();
      });
    });

    test('silence past the threshold degrades before it disconnects', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();

        h.elapse(config.stallDegradedAfter - const Duration(seconds: 1));
        expect(h.phase, ConnectionPhase.live);

        h.elapse(const Duration(seconds: 1));
        expect(h.phase, ConnectionPhase.degraded,
            reason: 'a silent socket must stop claiming to be live');
        expect(h.bloc.state.silentSince, isNotNull);
        h.dispose();
      });
    });

    test('a stalled socket is torn down rather than waited out', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();
        final FakeSseConnection first = h.transport.latest;

        h.elapse(config.stallReconnectAfter);

        expect(first.closedByClient, isTrue,
            reason: 'the server stalls for 25s; we must not sit through it');
        expect(h.phase, ConnectionPhase.reconnecting);

        h.elapse(const Duration(milliseconds: 500));
        expect(h.attempts, 2);
        h.dispose();
      });
    });

    test('activity resets the watchdog rather than the clock running down', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();

        h.elapse(const Duration(seconds: 7));
        h.transport.latest.sendHeartbeat();
        async.flushMicrotasks();

        h.elapse(const Duration(seconds: 7));
        expect(h.phase, ConnectionPhase.live,
            reason: '14s elapsed but never 8s of silence');
        h.dispose();
      });
    });
  });

  group('token expiry', () {
    test('refreshes proactively before the token dies', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();
        expect(h.api.calls, 1);

        h.keepAlive(const Duration(seconds: 44));
        expect(h.api.calls, 1, reason: 'refreshed too early');

        h.keepAlive(const Duration(seconds: 2));
        expect(h.api.calls, 2, reason: 'should refresh 15s before expiry');
        h.dispose();
      });
    });

    test('the drop at expiry reconnects instantly with the fresh token', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();

        h.keepAlive(const Duration(seconds: 59));
        h.transport.latest.disconnect();
        async.flushMicrotasks();

        // No backoff delay elapsed, yet the reconnect already happened.
        expect(h.attempts, 2);
        expect(h.transport.attempts.last.token, 'token-2');
        expect(h.bloc.state.attempt, 0,
            reason: 'an expected drop must not count as a failure');
        h.dispose();
      });
    });

    test('a 401 refreshes once and retries immediately', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async);
        h.transport.failOnce = const UnauthorizedException();
        h.start();

        expect(h.attempts, 2, reason: 'should retry without waiting');
        expect(h.api.calls, 2);
        expect(h.transport.attempts.last.token, 'token-2');
        h.dispose();
      });
    });

    test('a 401 on a freshly issued token is a real auth failure', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async);
        h.transport.failAlways = const UnauthorizedException();
        h.start();

        expect(h.phase, ConnectionPhase.authFailed);
        expect(h.attempts, 2, reason: 'must not loop on 401s');
        h.dispose();
      });
    });

    test('rejected stored credentials surface as an auth failure', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async);
        h.api.failAlways = const InvalidCredentialsException();
        h.start();

        expect(h.phase, ConnectionPhase.authFailed);
        expect(h.attempts, 0);
        h.dispose();
      });
    });
  });

  group('reachability', () {
    test('does not attempt anything while the device is offline', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async);
        h.monitor.set(NetworkStatus.offline);
        h.start();

        h.elapse(const Duration(minutes: 2));

        expect(h.attempts, 0, reason: 'no point hammering a dead radio');
        expect(h.phase, ConnectionPhase.offline);
        h.dispose();
      });
    });

    test('going offline tears the live connection down', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();
        final FakeSseConnection first = h.transport.latest;

        h.monitor.goOffline();
        async.flushMicrotasks();

        expect(first.closedByClient, isTrue);
        expect(h.phase, ConnectionPhase.offline);
        h.dispose();
      });
    });

    test('coming back online reconnects at once with a clean backoff', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async);
        h.transport.failAlways = const TransportException('refused');
        h.start();

        // Burn a few backoff steps so the delay is long.
        h.elapse(const Duration(seconds: 20));
        final int attemptsBeforeOffline = h.attempts;
        expect(attemptsBeforeOffline, greaterThan(3));

        h.monitor.goOffline();
        async.flushMicrotasks();
        h.elapse(const Duration(minutes: 1));
        expect(h.attempts, attemptsBeforeOffline, reason: 'silent while offline');

        h.transport.failAlways = null;
        h.monitor.goOnline();
        async.flushMicrotasks();

        expect(h.attempts, attemptsBeforeOffline + 1,
            reason: 'reachability returning is new information');
        h.dispose();
      });
    });
  });

  group('app lifecycle', () {
    test('backgrounding drops the connection and stops all attempts', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();
        final FakeSseConnection first = h.transport.latest;

        h.bloc.add(const FeedEvent.appBackgrounded());
        async.flushMicrotasks();

        expect(first.closedByClient, isTrue,
            reason: 'nobody is looking at the screen');
        expect(h.phase, ConnectionPhase.suspended);

        h.elapse(const Duration(minutes: 3));
        expect(h.attempts, 1, reason: 'no reconnects while backgrounded');
        h.dispose();
      });
    });

    test('the phase never claims live across a background cycle', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();

        h.bloc.add(const FeedEvent.appBackgrounded());
        async.flushMicrotasks();
        h.elapse(const Duration(minutes: 5));

        // This is the whole point: on the frame the user comes back to, the
        // banner must not be green above five-minute-old prices.
        expect(h.phase, isNot(ConnectionPhase.live));
        h.dispose();
      });
    });

    test('foregrounding reconnects at once with a clean backoff', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async);
        h.transport.failAlways = const TransportException('refused');
        h.start();

        // Burn several backoff steps so the pending delay is long.
        h.elapse(const Duration(seconds: 20));
        final int burned = h.attempts;
        expect(burned, greaterThan(3));

        h.bloc.add(const FeedEvent.appBackgrounded());
        async.flushMicrotasks();
        h.elapse(const Duration(minutes: 1));
        expect(h.attempts, burned, reason: 'silent while backgrounded');

        h.transport.failAlways = null;
        h.bloc.add(const FeedEvent.appForegrounded());
        async.flushMicrotasks();

        expect(h.attempts, burned + 1,
            reason: 'coming back is new information, not another failure');
        expect(h.bloc.state.attempt, 0);
        h.dispose();
      });
    });

    test('a resumed stream carries the last event id across the gap', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive(id: 12, ts: 1000);

        h.bloc.add(const FeedEvent.appBackgrounded());
        async.flushMicrotasks();
        h.elapse(const Duration(minutes: 2));

        h.bloc.add(const FeedEvent.appForegrounded());
        async.flushMicrotasks();

        expect(h.transport.attempts.last.lastEventId, 12);
        h.dispose();
      });
    });

    test('foregrounding without a preceding background does nothing', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();
        final int before = h.attempts;

        // What a bare `inactive` (Control Centre, app switcher) looks like:
        // resume fires, but nothing was ever torn down.
        h.bloc.add(const FeedEvent.appForegrounded());
        async.flushMicrotasks();

        expect(h.attempts, before);
        expect(h.phase, ConnectionPhase.live);
        h.dispose();
      });
    });
  });

  group('resume', () {
    test('reconnects with the highest id seen', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive(id: 5, ts: 1000);

        h.transport.latest.sendTick(id: 7, ts: 1100);
        async.flushMicrotasks();
        // A duplicate replay of an older id must not move the resume point
        // backwards.
        h.transport.latest.sendTick(id: 3, ts: 900);
        async.flushMicrotasks();

        h.transport.latest.disconnect();
        async.flushMicrotasks();
        h.elapse(const Duration(seconds: 1));

        expect(h.transport.attempts.last.lastEventId, 7);
        h.dispose();
      });
    });

    test('a gap notice is counted rather than silently swallowed', () {
      fakeAsync((FakeAsync async) {
        final Harness h = Harness(async)..connectAndGoLive();

        h.transport.latest.send(
          const SseEvent(event: 'gap', data: '{"resumeFrom":900}'),
        );
        async.flushMicrotasks();

        expect(h.bloc.state.gapCount, 1);
        expect(h.phase, ConnectionPhase.live);
        h.dispose();
      });
    });
  });
}
