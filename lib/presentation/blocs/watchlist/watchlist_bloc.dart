import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../data/instruments/instruments_repository.dart';
import '../../../data/instruments/models/instrument.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

/// Owns the row set. Deliberately has nothing to do with prices: this state
/// changes once per session, so rebuilding on it is free.
@injectable
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc(this._repository) : super(const WatchlistState.initial()) {
    on<WatchlistRequested>((_, Emitter<WatchlistState> emit) => _load(emit));
    on<WatchlistRetried>((_, Emitter<WatchlistState> emit) => _load(emit));
  }

  final InstrumentsRepository _repository;

  Future<void> _load(Emitter<WatchlistState> emit) async {
    emit(const WatchlistState.loading());
    try {
      final List<Instrument> instruments = await _repository.load();
      emit(WatchlistState.loaded(instruments));
    } on Object catch (error) {
      emit(WatchlistState.failed('$error'));
    }
  }
}
