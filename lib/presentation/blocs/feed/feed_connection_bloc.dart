import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_native/pulse_native.dart';

import '../../../core/app_config.dart';
import '../../../core/clock.dart';
import '../../../core/errors.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../data/feed/sse/sse_message.dart';
import '../../../data/feed/sse/sse_transport.dart';
import '../../../data/feed/tick.dart';
import '../../../data/feed/tick_codec.dart';
import '../../../domain/ports/network_monitor.dart';
import '../../../domain/ports/tick_sink.dart';
import '../../../domain/reconnect_policy.dart';
import 'feed_event.dart';
import 'feed_state.dart';

/// The resilience state machine: connect, detect silence, back off, reconnect,
/// resume, refresh tokens, and stay out of the way when the device is offline.
///
/// Pure Dart - no Flutter imports - so every rule below is testable with a
/// fake transport and fake time.
@injectable
class FeedConnectionBloc extends Bloc<FeedEvent, FeedState> {
  FeedConnectionBloc(
    this._transport,
    this._auth,
    this._sink,
    this._monitor,
    this._policy,
    this._config,
    this._clock,
  ) : super(const FeedState()) {
    on<FeedStarted>(_onStarted);
    on<FeedStopped>(_onStopped);
    on<FeedConnectRequested>(_onConnectRequested);
    on<FeedMessageReceived>(_onMessageReceived);
    on<FeedStreamClosed>(_onStreamClosed);
    on<FeedWatchdogTicked>(_onWatchdogTicked);
    on<FeedNetworkStatusChanged>(_onNetworkStatusChanged);
    on<FeedTokenRefreshRequested>(_onTokenRefreshRequested);
  }

  final SseTransport _transport;
  final AuthRepository _auth;
  final TickSink _sink;
  final NetworkMonitor _monitor;
  final ReconnectPolicy _policy;
  final AppConfig _config;
  final Clock _clock;

  SseConnection? _connection;
  StreamSubscription<SseMessage>? _messageSubscription;
  StreamSubscription<NetworkStatus>? _networkSubscription;

  Timer? _watchdog;
  Timer? _backoffTimer;
  Timer? _tokenRefreshTimer;

  bool _started = false;
  bool _connectInFlight = false;

  /// Bumped on every teardown. Async callbacks from a previous connection
  /// carry a stale generation and are ignored - the cheapest way to make
  /// overlapping connects impossible without an event-transformer package.
  int _generation = 0;

  int _attempt = 0;
  int _authRetries = 0;

  DateTime? _lastActivityAt;
  DateTime? _streamOpenedAt;

  /// Expiry of the token *this* stream was opened with. The server closes the
  /// connection the moment it lapses, so a drop near this time is expected
  /// rather than a failure.
  DateTime? _streamTokenExpiresAt;

  // --- lifecycle -----------------------------------------------------------

  Future<void> _onStarted(FeedStarted event, Emitter<FeedState> emit) async {
    if (_started) return;
    _started = true;

    _networkSubscription = _monitor.statuses.listen(
      (NetworkStatus status) => add(FeedEvent.networkStatusChanged(status)),
    );
    _watchdog = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const FeedEvent.watchdogTicked()),
    );

    add(const FeedEvent.connectRequested());
  }

  void _onStopped(FeedStopped event, Emitter<FeedState> emit) {
    _started = false;
    _teardownConnection();
    _cancelTimers();
    unawaited(_networkSubscription?.cancel());
    _networkSubscription = null;
    _attempt = 0;
    emit(state.copyWith(
      phase: ConnectionPhase.idle,
      silentSince: null,
      nextAttemptAt: null,
    ));
  }

  @override
  Future<void> close() async {
    _teardownConnection();
    _cancelTimers();
    await _networkSubscription?.cancel();
    return super.close();
  }

  // --- connecting ----------------------------------------------------------

  Future<void> _onConnectRequested(
    FeedConnectRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (!_started || _connectInFlight) return;

    // Never spin attempts while the platform says there is no network.
    if (!_monitor.current.isOnline) {
      emit(state.copyWith(
        phase: ConnectionPhase.offline,
        nextAttemptAt: null,
        silentSince: null,
      ));
      return;
    }

    _backoffTimer?.cancel();
    _backoffTimer = null;
    _connectInFlight = true;
    final int generation = ++_generation;

    emit(state.copyWith(
      phase: ConnectionPhase.connecting,
      nextAttemptAt: null,
      silentSince: null,
      message: null,
    ));

    try {
      final String token = await _auth.validToken();
      final DateTime? expiresAt = _auth.currentSession?.expiresAt;

      final SseConnection connection = await _transport.connect(
        token: token,
        lastEventId: state.lastEventId,
      );

      // A teardown happened while we were opening; drop this socket.
      if (generation != _generation || isClosed || !_started) {
        unawaited(connection.close());
        return;
      }

      _connection = connection;
      _streamTokenExpiresAt = expiresAt;
      _streamOpenedAt = _clock.now();
      _lastActivityAt = _clock.now();
      _authRetries = 0;

      _messageSubscription = connection.messages.listen(
        (SseMessage message) => add(FeedEvent.messageReceived(message)),
        onError: (Object error) => add(FeedEvent.streamClosed(error: error)),
        onDone: () => add(const FeedEvent.streamClosed()),
      );

      _scheduleTokenRefresh(expiresAt);
      // Stay in `connecting` until something actually arrives: an open socket
      // is not evidence of data.
    } on UnauthorizedException {
      await _handleUnauthorized(emit);
    } on NoStoredCredentialsException {
      emit(state.copyWith(
        phase: ConnectionPhase.authFailed,
        message: 'No stored credentials.',
      ));
    } on InvalidCredentialsException {
      emit(state.copyWith(
        phase: ConnectionPhase.authFailed,
        message: 'Stored credentials were rejected.',
      ));
    } on Object catch (error) {
      _scheduleReconnect(emit, message: '$error');
    } finally {
      _connectInFlight = false;
    }
  }

  /// A 401 means the token died. Refresh once and retry immediately; if the
  /// refreshed token is *also* rejected, the credentials themselves are bad
  /// and only a human can fix it.
  Future<void> _handleUnauthorized(Emitter<FeedState> emit) async {
    if (_authRetries >= 1) {
      emit(state.copyWith(
        phase: ConnectionPhase.authFailed,
        message: 'Server rejected a freshly issued token.',
      ));
      return;
    }
    _authRetries++;

    try {
      await _auth.refresh();
    } on InvalidCredentialsException {
      emit(state.copyWith(
        phase: ConnectionPhase.authFailed,
        message: 'Stored credentials were rejected.',
      ));
      return;
    } on NoStoredCredentialsException {
      emit(state.copyWith(
        phase: ConnectionPhase.authFailed,
        message: 'No stored credentials.',
      ));
      return;
    } on Object catch (error) {
      _scheduleReconnect(emit, message: 'Token refresh failed: $error');
      return;
    }

    add(const FeedEvent.connectRequested());
  }

  // --- inbound data --------------------------------------------------------

  void _onMessageReceived(
    FeedMessageReceived event,
    Emitter<FeedState> emit,
  ) {
    _lastActivityAt = _clock.now();

    switch (event.message) {
      case SseComment():
        // A heartbeat carries no data but proves the socket is alive, which is
        // exactly what distinguishes "quiet" from "stalled".
        _promoteToLive(emit);

      case final SseEvent sseEvent:
        final int? id = sseEvent.id;
        final int? knownId = state.lastEventId;
        final bool advancesId = id != null && (knownId == null || id > knownId);

        if (isGapEvent(sseEvent)) {
          // We asked to resume from an id the server no longer buffers. The
          // hole is permanent; surface it rather than implying continuity.
          emit(state.copyWith(
            phase: ConnectionPhase.live,
            silentSince: null,
            nextAttemptAt: null,
            gapCount: state.gapCount + 1,
            lastEventId: advancesId ? id : knownId,
          ));
          return;
        }

        final Tick? tick = decodeTick(sseEvent);
        if (tick == null) {
          _sink.noteMalformed();
        } else {
          _sink.add(tick);
        }

        // Emit only when something the UI cares about actually changed. This
        // is the line that keeps a 220-tick burst from producing 220 state
        // emissions.
        if (advancesId || state.phase != ConnectionPhase.live) {
          emit(state.copyWith(
            phase: ConnectionPhase.live,
            silentSince: null,
            nextAttemptAt: null,
            lastEventId: advancesId ? id : knownId,
          ));
        }
    }
  }

  void _promoteToLive(Emitter<FeedState> emit) {
    if (state.phase == ConnectionPhase.live) return;
    emit(state.copyWith(
      phase: ConnectionPhase.live,
      silentSince: null,
      nextAttemptAt: null,
    ));
  }

  // --- disconnects ---------------------------------------------------------

  void _onStreamClosed(FeedStreamClosed event, Emitter<FeedState> emit) {
    // Both of these read state that teardown clears, so they have to be
    // decided before the connection is dismantled.
    final bool wasHealthy = _streamWasHealthy();
    final bool expectedDrop = _wasExpectedTokenDrop();

    _teardownConnection();
    if (!_started) return;

    if (!_monitor.current.isOnline) {
      emit(state.copyWith(
        phase: ConnectionPhase.offline,
        nextAttemptAt: null,
        silentSince: null,
      ));
      return;
    }

    if (wasHealthy) _attempt = 0;

    if (expectedDrop) {
      // The server closes every stream the instant its token expires. Paying
      // a backoff step for that would add a visible stutter every 60 seconds.
      emit(state.copyWith(
        phase: ConnectionPhase.connecting,
        nextAttemptAt: null,
        silentSince: null,
      ));
      add(const FeedEvent.connectRequested());
      return;
    }

    _scheduleReconnect(emit, message: event.error?.toString());
  }

  bool _wasExpectedTokenDrop() {
    final DateTime? expiry = _streamTokenExpiresAt;
    if (expiry == null) return false;
    return !_clock.now().isBefore(expiry.subtract(_config.expectedDropWindow));
  }

  /// A stream that ran long enough earns a clean slate, so a single long-lived
  /// connection dropping does not inherit an old backoff step. It is also what
  /// makes stall recovery fast without special-casing it.
  bool _streamWasHealthy() {
    final DateTime? openedAt = _streamOpenedAt;
    if (openedAt == null) return false;
    return _clock.now().difference(openedAt) >= _config.backoffResetAfterHealthy;
  }

  void _scheduleReconnect(Emitter<FeedState> emit, {String? message}) {
    final Duration delay = _policy.delayFor(_attempt);
    _attempt++;

    _backoffTimer?.cancel();
    _backoffTimer = Timer(delay, () => add(const FeedEvent.connectRequested()));

    emit(state.copyWith(
      phase: ConnectionPhase.reconnecting,
      attempt: _attempt,
      nextAttemptAt: _clock.now().add(delay),
      silentSince: null,
      message: message,
    ));
  }

  // --- stall detection -----------------------------------------------------

  void _onWatchdogTicked(FeedWatchdogTicked event, Emitter<FeedState> emit) {
    if (!_started || _connection == null) return;

    final DateTime? lastActivity = _lastActivityAt;
    if (lastActivity == null) return;

    final Duration silence = _clock.now().difference(lastActivity);

    if (silence >= _config.stallReconnectAfter) {
      // The socket is open and useless. Waiting out the server's 25s freeze
      // would mean up to 25 seconds of frozen prices; tear it down instead.
      final bool wasHealthy = _streamWasHealthy();
      _teardownConnection();
      if (wasHealthy) _attempt = 0;
      _scheduleReconnect(emit, message: 'No data for ${silence.inSeconds}s.');
      return;
    }

    if (silence >= _config.stallDegradedAfter &&
        state.phase != ConnectionPhase.degraded) {
      emit(state.copyWith(
        phase: ConnectionPhase.degraded,
        silentSince: lastActivity,
      ));
    }
  }

  // --- reachability --------------------------------------------------------

  void _onNetworkStatusChanged(
    FeedNetworkStatusChanged event,
    Emitter<FeedState> emit,
  ) {
    if (!_started) return;

    if (!event.status.isOnline) {
      _teardownConnection();
      _backoffTimer?.cancel();
      _backoffTimer = null;
      emit(state.copyWith(
        phase: ConnectionPhase.offline,
        nextAttemptAt: null,
        silentSince: null,
        message: 'Device is offline.',
      ));
      return;
    }

    if (state.phase == ConnectionPhase.offline) {
      // Coming back from offline is new information, not a failure: start
      // from a clean backoff rather than resuming a long delay.
      _attempt = 0;
      add(const FeedEvent.connectRequested());
    }
  }

  // --- token refresh -------------------------------------------------------

  void _scheduleTokenRefresh(DateTime? expiresAt) {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    if (expiresAt == null) return;

    final Duration delay =
        expiresAt.difference(_clock.now()) - _config.tokenRefreshLead;
    _tokenRefreshTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => add(const FeedEvent.tokenRefreshRequested()),
    );
  }

  Future<void> _onTokenRefreshRequested(
    FeedTokenRefreshRequested event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _auth.refresh();
    } on Object {
      // Nothing to do here. The stream will drop when the old token lapses and
      // the reconnect path will try again with backoff.
    }
  }

  // --- teardown ------------------------------------------------------------

  /// Synchronous on purpose. Closing a socket is fire-and-forget: the state
  /// machine must not stall waiting for a TCP teardown before it can schedule
  /// the next attempt, and awaiting a subscription cancel inside a fake-time
  /// zone never completes, which would make this logic untestable.
  void _teardownConnection() {
    _generation++;
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;

    final StreamSubscription<SseMessage>? subscription = _messageSubscription;
    final SseConnection? connection = _connection;
    _messageSubscription = null;
    _connection = null;
    _lastActivityAt = null;
    _streamOpenedAt = null;
    _streamTokenExpiresAt = null;

    unawaited(subscription?.cancel());
    unawaited(connection?.close());
  }

  void _cancelTimers() {
    _watchdog?.cancel();
    _watchdog = null;
    _backoffTimer?.cancel();
    _backoffTimer = null;
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }
}
