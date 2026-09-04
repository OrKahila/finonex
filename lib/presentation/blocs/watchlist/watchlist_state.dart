import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/instruments/models/instrument.dart';

part 'watchlist_state.freezed.dart';

@freezed
sealed class WatchlistState with _$WatchlistState {
  const factory WatchlistState.initial() = WatchlistInitial;

  const factory WatchlistState.loading() = WatchlistLoading;

  /// The instrument list is static for the session: it defines the rows, and
  /// nothing about it changes when prices move.
  const factory WatchlistState.loaded(List<Instrument> instruments) =
      WatchlistLoaded;

  const factory WatchlistState.failed(String message) = WatchlistFailed;
}
