/// One price update for one instrument.
///
/// Hand-written rather than generated: this is the hot path (60-90/sec
/// baseline, 220 in a burst), it is constructed on every accepted event, and
/// the fields are four primitives. Nothing freezed would add is worth the
/// indirection here.
class Tick {
  const Tick({
    required this.symbol,
    required this.bid,
    required this.ask,
    required this.ts,
    this.eventId,
  });

  final String symbol;
  final double bid;
  final double ask;

  /// The tick's own epoch-ms timestamp, as stamped by the server. This is the
  /// ordering key - not arrival order, which the feed reorders on purpose.
  final int ts;

  /// The SSE `id`. Used for duplicate suppression and for `Last-Event-ID`.
  final int? eventId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tick &&
          other.symbol == symbol &&
          other.bid == bid &&
          other.ask == ask &&
          other.ts == ts &&
          other.eventId == eventId;

  @override
  int get hashCode => Object.hash(symbol, bid, ask, ts, eventId);

  @override
  String toString() =>
      'Tick($symbol, bid: $bid, ask: $ask, ts: $ts, id: $eventId)';
}
