import 'dart:convert';

import 'sse/sse_message.dart';
import 'tick.dart';

/// Turns a `tick` event into a [Tick], or null if it is not one we can use.
///
/// Returning null rather than throwing is the whole point: the server
/// deliberately emits garbage payloads, and a malformed event must cost us one
/// dropped tick, never the stream.
Tick? decodeTick(SseEvent event) {
  if (event.event != 'tick') return null;

  Object? decoded;
  try {
    decoded = jsonDecode(event.data);
  } on FormatException {
    return null;
  }

  if (decoded is! Map<String, dynamic>) return null;

  final Object? symbol = decoded['s'];
  final Object? bid = decoded['b'];
  final Object? ask = decoded['a'];
  final Object? ts = decoded['ts'];

  if (symbol is! String || symbol.isEmpty) return null;
  if (bid is! num || ask is! num || ts is! num) return null;

  return Tick(
    symbol: symbol,
    bid: bid.toDouble(),
    ask: ask.toDouble(),
    ts: ts.toInt(),
    eventId: event.id,
  );
}

/// The server's resume notice: we asked to replay from an id it no longer
/// buffers, so there is a hole in the sequence we can never fill.
bool isGapEvent(SseEvent event) => event.event == 'gap';
