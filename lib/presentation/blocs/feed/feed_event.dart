import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_native/pulse_native.dart';

import '../../../data/feed/sse/sse_message.dart';

part 'feed_event.freezed.dart';

@freezed
sealed class FeedEvent with _$FeedEvent {
  /// Begin. Idempotent.
  const factory FeedEvent.started() = FeedStarted;

  /// Tear everything down (logout, or the screen going away).
  const factory FeedEvent.stopped() = FeedStopped;

  /// Attempt a connection now. Raised by the backoff timer, by reachability
  /// coming back, and by the token-refresh retry path.
  const factory FeedEvent.connectRequested() = FeedConnectRequested;

  const factory FeedEvent.messageReceived(SseMessage message) =
      FeedMessageReceived;

  const factory FeedEvent.streamClosed({Object? error}) = FeedStreamClosed;

  /// One-per-second heartbeat driving stall detection and the backoff reset.
  /// A single periodic timer, rather than a timer reset on every tick: at 90
  /// ticks/sec, resetting a timer per tick is pure allocation churn.
  const factory FeedEvent.watchdogTicked() = FeedWatchdogTicked;

  const factory FeedEvent.networkStatusChanged(NetworkStatus status) =
      FeedNetworkStatusChanged;

  /// The app went to the background. Raised on `paused` only - never on
  /// `inactive`, which fires for the app switcher, Control Centre and incoming
  /// calls, where dropping the feed would be wrong.
  const factory FeedEvent.appBackgrounded() = FeedAppBackgrounded;

  /// The app came back. Treated as new information rather than a failure, the
  /// same way reachability returning is.
  const factory FeedEvent.appForegrounded() = FeedAppForegrounded;

  /// Fired ~15s before the current token dies, so the inevitable drop at
  /// expiry can be answered with an instant reconnect instead of a login
  /// round-trip.
  const factory FeedEvent.tokenRefreshRequested() = FeedTokenRefreshRequested;
}
