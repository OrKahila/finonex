import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/app_config.dart';
import '../../../core/clock.dart';
import '../../../core/periodic_ticker.dart';
import '../../../data/feed/conflation_scheduler.dart';
import '../../../data/feed/quote_book.dart';
import '../../../data/feed/tick.dart';
import '../../../domain/models/price_cell.dart';
import 'price_event.dart';
import 'price_state.dart';

/// Owns market-data state: latest valid quote per symbol, plus the counters
/// that show the feed's misbehaviour being absorbed.
///
/// The performance requirement is met by never letting a tick reach `emit`.
/// Ticks run the correctness filters synchronously and buffer; a scheduler
/// collapses the resulting flush requests into at most one per ~16ms window.
/// A 220-tick burst across five symbols therefore produces **one** state
/// emission carrying five changed cells - not 220 emissions, and not 220
/// rebuilds.
///
/// The complementary half of that contract lives in the widget layer:
/// `BlocSelector` per symbol, over a copy-on-write map that preserves the
/// identity of unchanged cells. Both halves are needed; either alone is not
/// enough.
@lazySingleton
class PriceBloc extends Bloc<PriceEvent, PriceState> {
  PriceBloc(this._config, this._clock, this._scheduler, this._staleTicker)
      : _book = QuoteBook(_config),
        super(const PriceState()) {
    // All four handlers are synchronous. That matters for the tick handler:
    // ticks must be applied in arrival order for the (ts, id) watermark to be
    // correct, and a synchronous handler runs to completion before the next
    // event is delivered, so order is preserved without an event transformer.
    on<PriceTickReceived>(_onTickReceived);
    on<PriceMalformedReceived>(_onMalformedReceived);
    on<PriceFlushRequested>(_onFlushRequested);
    on<PriceStalenessChecked>(_onStalenessChecked);

    _staleTicker.start(const Duration(seconds: 1), () {
      if (!isClosed) add(const PriceEvent.stalenessChecked());
    });
  }

  final AppConfig _config;
  final Clock _clock;
  final ConflationScheduler _scheduler;
  final PeriodicTicker _staleTicker;
  final QuoteBook _book;

  /// Bounded per-symbol history for the detail screen's sparkline and session
  /// extremes.
  ///
  /// Deliberately *not* in [PriceState]: it is read on demand by one screen,
  /// and copying forty ring buffers into a new state object at frame cadence
  /// to serve a screen that is usually closed would be indefensible. The
  /// detail screen already rebuilds on its symbol's quote, and reads this
  /// while it does.
  SymbolHistory historyFor(String symbol) => _book.historyFor(symbol);

  void _onTickReceived(PriceTickReceived event, Emitter<PriceState> emit) {
    _book.add(event.tick);
    // No emit. Rejected ticks still schedule a flush so the counters move.
    _requestFlush();
  }

  void _onMalformedReceived(
    PriceMalformedReceived event,
    Emitter<PriceState> emit,
  ) {
    _book.noteMalformed();
    _requestFlush();
  }

  void _requestFlush() {
    _scheduler.schedule(() {
      if (!isClosed) add(const PriceEvent.flushRequested());
    });
  }

  void _onFlushRequested(
    PriceFlushRequested event,
    Emitter<PriceState> emit,
  ) {
    final List<Tick> batch = _book.drainPending();

    if (batch.isEmpty) {
      // Only counters moved - keep the same quotes map, so every selector
      // sees identical cells and no row rebuilds.
      emit(state.next(stats: _book.stats));
      return;
    }

    final DateTime now = _clock.now();
    final Map<String, PriceCell> quotes =
        Map<String, PriceCell>.of(state.quotes);

    for (final Tick tick in batch) {
      final PriceCell previous = quotes[tick.symbol] ?? PriceCell.empty;

      // Direction is the *net* move across the window, so a burst produces one
      // flash in the direction the price actually went.
      //
      // Measured on the mid, not the bid. Comparing bids alone gets the sign
      // wrong whenever the bid rounds to the same value but the ask moves -
      // the old code fell through to `down` for an ask that had gone *up*.
      // Both sides round independently to the instrument's decimals, so that
      // is reachable, most easily on the low-precision instruments.
      final bool changed = previous.bid != tick.bid || previous.ask != tick.ask;
      final double mid = (tick.bid + tick.ask) / 2;
      final double previousMid = previous.hasPrice
          ? (previous.bid! + previous.ask!) / 2
          : mid;

      final PriceDirection direction =
          !previous.hasPrice || !changed || mid == previousMid
              ? PriceDirection.none
              : (mid > previousMid
                  ? PriceDirection.up
                  : PriceDirection.down);

      quotes[tick.symbol] = PriceCell(
        bid: tick.bid,
        ask: tick.ask,
        ts: tick.ts,
        direction: direction,
        // Revision only moves when the price moved, so an unchanged
        // re-delivery cannot trigger a second flash.
        revision: changed ? previous.revision + 1 : previous.revision,
        isStale: false,
        updatedAt: now,
      );
    }

    emit(state.next(quotes: quotes, stats: _book.stats));
  }

  /// Flips the stale badge on symbols that have gone quiet.
  ///
  /// Allocates a new map only if something actually changed, so a busy feed
  /// pays nothing for this sweep and a quiet one pays it once.
  void _onStalenessChecked(
    PriceStalenessChecked event,
    Emitter<PriceState> emit,
  ) {
    final DateTime now = _clock.now();
    Map<String, PriceCell>? updated;

    for (final MapEntry<String, PriceCell> entry in state.quotes.entries) {
      final PriceCell cell = entry.value;
      final DateTime? updatedAt = cell.updatedAt;
      if (updatedAt == null) continue;

      final bool stale = now.difference(updatedAt) >= _config.staleBadgeAfter;
      if (stale == cell.isStale) continue;

      updated ??= Map<String, PriceCell>.of(state.quotes);
      updated[entry.key] = cell.copyWith(isStale: stale);
    }

    if (updated == null) return;
    emit(state.next(quotes: updated));
  }

  @override
  Future<void> close() {
    _staleTicker.stop();
    _scheduler.dispose();
    return super.close();
  }
}
