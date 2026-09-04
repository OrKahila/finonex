import '../../core/app_config.dart';
import '../../domain/models/price_cell.dart';
import 'tick.dart';

/// The correctness core of the data plane: which ticks are real, which are
/// stale, and what the newest tick per symbol is for the current window.
///
/// Deliberately framework-free and free of any notion of how updates reach the
/// screen. It holds no UI state - it decides what is *true*, and something
/// above it decides how to present it. That split is what lets the same logic
/// be unit-tested in isolation and reused regardless of the state-management
/// choice above it.
class QuoteBook {
  QuoteBook(this._config) : _seenIds = _DedupWindow(_config.dedupWindow);

  final AppConfig _config;
  final _DedupWindow _seenIds;

  /// Last accepted (timestamp, event id) per symbol. The ordering guard.
  ///
  /// Timestamp alone is not a total order: the server's burst emits ~220 ticks
  /// synchronously, so dozens of ticks for the same symbol share one
  /// millisecond. Discarding those would pin the symbol to the burst's opening
  /// price. The SSE id is globally monotonic, so it breaks ties in true
  /// emission order.
  final Map<String, ({int ts, int eventId})> _lastAccepted =
      <String, ({int ts, int eventId})>{};

  /// Newest pending tick per symbol; last write wins within a window.
  final Map<String, Tick> _pending = <String, Tick>{};

  final Map<String, _History> _histories = <String, _History>{};

  int _accepted = 0;
  int _duplicates = 0;
  int _outOfOrder = 0;
  int _malformed = 0;

  FeedStats get stats => FeedStats(
        accepted: _accepted,
        duplicates: _duplicates,
        outOfOrder: _outOfOrder,
        malformed: _malformed,
      );

  bool get hasPending => _pending.isNotEmpty;

  /// Runs the two correctness filters and buffers the tick if it survives.
  /// Returns false if the tick was rejected.
  bool add(Tick tick) {
    // 1. Duplicate suppression by SSE id.
    final int? id = tick.eventId;
    if (id != null && !_seenIds.add(id)) {
      _duplicates++;
      return false;
    }

    // 2. Ordering guard, keyed on (ts, id).
    //
    // An older ts is stale - that is the server's reordered event, which
    // carries a *new* id and so sails past filter 1. An equal ts is only
    // accepted if the id moved forward.
    final int eventId = id ?? 0;
    final ({int ts, int eventId})? last = _lastAccepted[tick.symbol];
    if (last != null &&
        (tick.ts < last.ts ||
            (tick.ts == last.ts && eventId <= last.eventId))) {
      _outOfOrder++;
      return false;
    }
    _lastAccepted[tick.symbol] = (ts: tick.ts, eventId: eventId);

    // 3. Conflate.
    _pending[tick.symbol] = tick;
    _accepted++;
    return true;
  }

  void noteMalformed() => _malformed++;

  /// The conflated batch: at most one tick per symbol, the newest seen since
  /// the last drain. A 220-tick burst across five symbols drains to five ticks.
  ///
  /// History is recorded here rather than in [add] so the sparkline samples the
  /// same series the screen shows.
  List<Tick> drainPending() {
    if (_pending.isEmpty) return const <Tick>[];

    final List<Tick> batch = _pending.values.toList(growable: false);
    _pending.clear();

    for (final Tick tick in batch) {
      _histories
          .putIfAbsent(tick.symbol, () => _History(_config.sparklineDepth))
          .add(tick.bid);
    }
    return batch;
  }

  SymbolHistory historyFor(String symbol) =>
      _histories[symbol]?.snapshot() ?? SymbolHistory.empty;
}

/// Fixed-size set of recently seen event ids.
///
/// A plain Set would grow without bound over a long session; a ring buffer
/// keeps eviction O(1) and memory flat. Sized from AppConfig - the server's own
/// replay buffer is 1000 events, so a 2048-id window comfortably covers
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

/// Ring buffer of recent prices plus running session extremes.
class _History {
  _History(this._capacity) : _ring = List<double>.filled(_capacity, 0);

  final int _capacity;
  final List<double> _ring;

  int _index = 0;
  int _size = 0;
  double? _high;
  double? _low;

  void add(double price) {
    _ring[_index] = price;
    _index = (_index + 1) % _capacity;
    if (_size < _capacity) _size++;

    // Extremes are for the whole session, not just the visible tail.
    if (_high == null || price > _high!) _high = price;
    if (_low == null || price < _low!) _low = price;
  }

  SymbolHistory snapshot() {
    final int start = _size < _capacity ? 0 : _index;
    return SymbolHistory(
      recent: <double>[
        for (int i = 0; i < _size; i++) _ring[(start + i) % _capacity],
      ],
      high: _high,
      low: _low,
    );
  }
}
