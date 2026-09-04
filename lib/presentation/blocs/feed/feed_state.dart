import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_state.freezed.dart';

/// What the user is allowed to believe about the prices on screen.
enum ConnectionPhase {
  /// Not started yet, or deliberately stopped.
  idle,

  /// Opening a socket, or open but nothing has arrived yet.
  connecting,

  /// Data is flowing. Only in this phase are the numbers trustworthy.
  live,

  /// The socket is open but silent - no ticks and no heartbeats. This is the
  /// dangerous one: without it, a stalled feed looks exactly like a calm
  /// market.
  degraded,

  /// Disconnected, waiting out a backoff delay before the next attempt.
  reconnecting,

  /// The device itself has no network, per the platform reachability monitor.
  /// We deliberately do not burn attempts in this state.
  offline,

  /// The app is in the background. Nothing can be rendered, so holding a
  /// socket open would spend battery, data and the server's replay buffer on
  /// data nobody can see. Entering this phase is also what stops the banner
  /// claiming "Live" over pre-suspension prices when the user comes back.
  suspended,

  /// The server rejected our credentials. The only state that needs a human.
  authFailed,
}

/// Low-frequency connection status. Deliberately *not* where ticks live.
///
/// Every field here changes at most a few times a minute, so emitting a new
/// state is cheap. Anything that changes per tick belongs in the price store.
@freezed
abstract class FeedState with _$FeedState {
  const factory FeedState({
    @Default(ConnectionPhase.idle) ConnectionPhase phase,

    /// How many consecutive reconnect attempts have been scheduled.
    @Default(0) int attempt,

    /// When the current silence began. Drives the "no data for Ns" readout.
    DateTime? silentSince,

    /// When the pending backoff timer fires. Drives the countdown.
    DateTime? nextAttemptAt,

    /// How many times the server told us our resume point was too old. Each
    /// one is a hole in history we can never fill.
    @Default(0) int gapCount,

    String? message,
  }) = _FeedState;

  const FeedState._();

  bool get isLive => phase == ConnectionPhase.live;

  /// True whenever prices on screen must not be presented as current.
  bool get isStalePresentation => phase != ConnectionPhase.live;
}
