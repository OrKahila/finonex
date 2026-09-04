import 'dart:async';
import 'dart:convert';

import 'sse_message.dart';

/// Incremental line-oriented SSE parser.
///
/// Line splitting and UTF-8 decoding are left to [LineSplitter] and
/// [Utf8Decoder] in [decodeSseStream], which already handle chunk boundaries
/// and multi-byte characters split across packets. This class only implements
/// the field grammar, which keeps it a pure, synchronous, trivially testable
/// function of the line sequence.
class SseParser {
  final StringBuffer _data = StringBuffer();

  String? _eventType;

  /// Persists across events, per the SSE spec: an event without an `id:` field
  /// inherits the last one seen. The server omits `id` on its `gap` notices and
  /// on malformed lines.
  int? _lastEventId;

  /// The highest id seen so far, which is what we send back as
  /// `Last-Event-ID`.
  int? get lastEventId => _lastEventId;

  /// Feeds one line in. Returns a message when this line completed one, else
  /// null.
  SseMessage? addLine(String line) {
    if (line.isEmpty) return _dispatch();

    if (line.startsWith(':')) {
      // Comment. Never part of an event body.
      return SseComment(line.substring(1).trim());
    }

    final int separator = line.indexOf(':');
    final String field;
    String value;
    if (separator == -1) {
      // A bare field name with no colon is legal and means an empty value.
      field = line;
      value = '';
    } else {
      field = line.substring(0, separator);
      value = line.substring(separator + 1);
      // Exactly one leading space after the colon is stripped, not all of it.
      if (value.startsWith(' ')) value = value.substring(1);
    }

    switch (field) {
      case 'event':
        _eventType = value;
      case 'data':
        _data.write(value);
        _data.write('\n');
      case 'id':
        // Per spec an unparseable id is ignored rather than reset.
        final int? parsed = int.tryParse(value);
        if (parsed != null) _lastEventId = parsed;
      case 'retry':
        // We manage our own backoff; the server never sends this anyway.
        break;
      default:
        // Unknown fields are ignored, not fatal.
        break;
    }
    return null;
  }

  SseMessage? _dispatch() {
    if (_data.isEmpty) {
      // A blank line with no buffered data dispatches nothing, but does clear
      // a pending event type.
      _eventType = null;
      return null;
    }

    String data = _data.toString();
    // The spec strips the single trailing newline added by the last data line.
    if (data.endsWith('\n')) data = data.substring(0, data.length - 1);

    final SseEvent event = SseEvent(
      event: _eventType ?? 'message',
      data: data,
      id: _lastEventId,
    );

    _data.clear();
    _eventType = null;
    return event;
  }
}

/// Decodes a raw byte stream into SSE messages.
///
/// The parser instance is created per subscription so a reconnect never
/// inherits half an event from the previous socket.
Stream<SseMessage> decodeSseStream(Stream<List<int>> bytes) {
  final SseParser parser = SseParser();
  return bytes
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .map(parser.addLine)
      .where((SseMessage? message) => message != null)
      .cast<SseMessage>();
}
