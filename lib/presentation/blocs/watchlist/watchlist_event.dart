import 'package:freezed_annotation/freezed_annotation.dart';

part 'watchlist_event.freezed.dart';

@freezed
sealed class WatchlistEvent with _$WatchlistEvent {
  const factory WatchlistEvent.requested() = WatchlistRequested;

  /// User tapped retry after a load failure.
  const factory WatchlistEvent.retried() = WatchlistRetried;
}
