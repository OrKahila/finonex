/// Which way the price moved on the last accepted update.
enum PriceDirection { none, up, down }

/// What one row shows: the current quote for one symbol.
///
/// Lives in `domain` rather than `data` because widgets render it directly - a
/// data-layer type reaching the widget tree is a layering leak regardless of
/// how it gets delivered.
class PriceCell {
  const PriceCell({
    this.bid,
    this.ask,
    this.ts = 0,
    this.direction = PriceDirection.none,
    this.revision = 0,
    this.isStale = false,
    this.updatedAt,
  });

  /// Null until the first tick for this symbol arrives.
  final double? bid;
  final double? ask;

  /// Server timestamp of the tick being displayed - the ordering key.
  final int ts;

  final PriceDirection direction;

  /// Increments only when the displayed price actually changed. The flash
  /// animation keys off this, so a duplicate or an identical re-delivery
  /// cannot produce a second flash.
  final int revision;

  /// No update for this symbol in a while, even though the feed is live.
  final bool isStale;

  /// Local time of the last accepted update, used for the staleness sweep.
  final DateTime? updatedAt;

  /// A single shared instance for symbols that have not ticked yet.
  ///
  /// Reference stability matters: `BlocSelector` skips a rebuild when the
  /// selected value is unchanged, and returning a fresh `PriceCell()` for
  /// every empty row on every emit would defeat that.
  static const PriceCell empty = PriceCell();

  bool get hasPrice => bid != null && ask != null;

  PriceCell copyWith({bool? isStale}) => PriceCell(
        bid: bid,
        ask: ask,
        ts: ts,
        direction: direction,
        revision: revision,
        isStale: isStale ?? this.isStale,
        updatedAt: updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceCell &&
          other.bid == bid &&
          other.ask == ask &&
          other.ts == ts &&
          other.direction == direction &&
          other.revision == revision &&
          other.isStale == isStale;

  @override
  int get hashCode =>
      Object.hash(bid, ask, ts, direction, revision, isStale);

  @override
  String toString() =>
      'PriceCell(bid: $bid, ask: $ask, ts: $ts, ${direction.name}, '
      'rev: $revision, stale: $isStale)';
}

/// A symbol's session so far: a bounded tail of recent prices plus the
/// extremes seen since the app started.
class SymbolHistory {
  const SymbolHistory({
    required this.recent,
    this.high,
    this.low,
  });

  static const SymbolHistory empty =
      SymbolHistory(recent: <double>[]);

  /// Oldest to newest. Bounded by AppConfig.sparklineDepth, so a session that
  /// runs for hours costs the same memory as one that runs for a minute.
  final List<double> recent;

  final double? high;
  final double? low;

  bool get hasData => recent.isNotEmpty;
}

/// Counters for the diagnostics row. Updated once per flush, never per tick.
class FeedStats {
  const FeedStats({
    this.accepted = 0,
    this.duplicates = 0,
    this.outOfOrder = 0,
    this.malformed = 0,
  });

  /// Ticks that made it to the screen.
  final int accepted;

  /// Events dropped because we had already seen that SSE id.
  final int duplicates;

  /// Events dropped because a newer timestamp for that symbol was already
  /// displayed.
  final int outOfOrder;

  /// Events we could not decode at all.
  final int malformed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedStats &&
          other.accepted == accepted &&
          other.duplicates == duplicates &&
          other.outOfOrder == outOfOrder &&
          other.malformed == malformed;

  @override
  int get hashCode => Object.hash(accepted, duplicates, outOfOrder, malformed);

  @override
  String toString() => 'FeedStats(accepted: $accepted, dup: $duplicates, '
      'ooo: $outOfOrder, malformed: $malformed)';
}
