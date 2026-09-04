import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../core/app_config.dart';
import '../../core/clock.dart';
import '../../domain/ports/tick_sink.dart';
import 'conflation_scheduler.dart';
import 'price_cell.dart';
import 'tick.dart';

/// The data plane: every tick that reaches the screen passes through here.
///
/// Three ordered filters, then a coalescing buffer:
///   1. drop events whose SSE id we have already seen (the server replays);
///   2. drop ticks whose timestamp is not newer than what that symbol already
///      shows (the server reorders, with a *new* id, so filter 1 cannot catch
///      it);
///   3. keep only the newest pending tick per symbol and publish on a timer.
///
/// Publishing writes to a per-symbol [ValueNotifier], so one tick rebuilds one
/// leaf widget. The list itself never rebuilds.
///
/// Uses `foundation`, not `widgets`: no BuildContext, no element tree, fully
/// testable in a plain unit test.
@LazySingleton(as: TickSink)
class PriceStore implements TickSink {
  PriceStore(this._config, this._clock, this._scheduler)
      : _seenIds = _DedupWindow(_config.dedupWindow) {
    _stalenessSweep = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _markStaleSymbols(),
    );
  }

  final AppConfig _config;
  final Clock _clock;
  final ConflationScheduler _scheduler;
  final _DedupWindow _seenIds;

  final Map<String, ValueNotifier<PriceCell>> _cells =
      <String, ValueNotifier<PriceCell>>{};

  /// Last accepted timestamp per symbol. The ordering guard.
  final Map<String, int> _lastTs = <String, int>{};

  /// Newest pending tick per symbol; last write wins within a window.
  final Map<String, Tick> _pending = <String, Tick>{};

  final ValueNotifier<FeedStats> stats =
      ValueNotifier<FeedStats>(const FeedStats());

  Timer? _stalenessSweep;
  int _accepted = 0;
  int _duplicates = 0;
  int _outOfOrder = 0;
  int _malformed = 0;
  bool _statsDirty = false;

  /// The notifier a row listens to. Created on demand so instruments that have
  /// not ticked yet still render an empty row.
  ValueListenable<PriceCell> listenableFor(String symbol) =>
      _notifierFor(symbol);

  ValueNotifier<PriceCell> _notifierFor(String symbol) => _cells.putIfAbsent(
        symbol,
        () => ValueNotifier<PriceCell>(const PriceCell()),
      );

  @override
  void add(Tick tick) {
    // 1. Duplicate suppression by SSE id.
    final int? id = tick.eventId;
    if (id != null && !_seenIds.add(id)) {
      _duplicates++;
      _statsDirty = true;
      _scheduler.schedule(_flush);
      return;
    }

    // 2. Ordering guard. `<=` rather than `<`: an identical timestamp carries
    // no new information and would only risk a spurious flash.
    final int? last = _lastTs[tick.symbol];
    if (last != null && tick.ts <= last) {
      _outOfOrder++;
      _statsDirty = true;
      _scheduler.schedule(_flush);
      return;
    }
    _lastTs[tick.symbol] = tick.ts;

    // 3. Conflate.
    _pending[tick.symbol] = tick;
    _accepted++;
    _statsDirty = true;
    _scheduler.schedule(_flush);
  }

  @override
  void noteMalformed() {
    _malformed++;
    _statsDirty = true;
    _scheduler.schedule(_flush);
  }

  /// Publishes at most one update per symbol per window. A 220-tick burst
  /// across five symbols costs five notifier writes, not 220.
  @visibleForTesting
  void flushNow() => _flush();

  void _flush() {
    if (_pending.isNotEmpty) {
      final DateTime now = _clock.now();
      for (final Tick tick in _pending.values) {
        final ValueNotifier<PriceCell> notifier = _notifierFor(tick.symbol);
        final PriceCell previous = notifier.value;

        // Direction is the *net* move across the window, so a burst produces
        // one flash in the direction the price actually went.
        final bool changed =
            previous.bid != tick.bid || previous.ask != tick.ask;
        final PriceDirection direction = !previous.hasPrice || !changed
            ? PriceDirection.none
            : (tick.bid > previous.bid! ? PriceDirection.up : PriceDirection.down);

        notifier.value = PriceCell(
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
      _pending.clear();
    }

    if (_statsDirty) {
      _statsDirty = false;
      stats.value = FeedStats(
        accepted: _accepted,
        duplicates: _duplicates,
        outOfOrder: _outOfOrder,
        malformed: _malformed,
      );
    }
  }

  /// Flips the stale flag on symbols that have gone quiet. Only cells whose
  /// flag actually changes are written, so a quiet minute costs nothing.
  @visibleForTesting
  void debugSweepStaleness() => _markStaleSymbols();

  void _markStaleSymbols() {
    final DateTime now = _clock.now();
    for (final ValueNotifier<PriceCell> notifier in _cells.values) {
      final PriceCell cell = notifier.value;
      final DateTime? updatedAt = cell.updatedAt;
      if (updatedAt == null) continue;

      final bool stale =
          now.difference(updatedAt) >= _config.staleBadgeAfter;
      if (stale != cell.isStale) {
        notifier.value = cell.copyWith(isStale: stale);
      }
    }
  }

  @disposeMethod
  void dispose() {
    _stalenessSweep?.cancel();
    _stalenessSweep = null;
    _scheduler.dispose();
    for (final ValueNotifier<PriceCell> notifier in _cells.values) {
      notifier.dispose();
    }
    _cells.clear();
    stats.dispose();
  }
}

/// Fixed-size set of recently seen event ids.
///
/// A plain Set would grow without bound over a long session; a ring buffer
/// keeps eviction O(1) and memory flat. Sized from AppConfig - the server's
/// own replay buffer is 1000 events, so a 2048-id window comfortably covers
/// anything it can legitimately re-send.
class _DedupWindow {
  _DedupWindow(this._capacity) : _ring = List<int>.filled(_capacity, 0);

  final int _capacity;
  final List<int> _ring;
  final Set<int> _seen = <int>{};

  int _index = 0;
  int _size = 0;

  /// Returns false if [id] was already in the window.
  bool add(int id) {
    if (!_seen.add(id)) return false;

    if (_size == _capacity) {
      _seen.remove(_ring[_index]);
    } else {
      _size++;
    }
    _ring[_index] = id;
    _index = (_index + 1) % _capacity;
    return true;
  }
}
