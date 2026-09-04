/// Anything the server can put on the wire.
///
/// Comments matter as much as events here: the server's `: ping` heartbeat is
/// the only signal that a silent connection is still alive, so the stall
/// watchdog has to see it. Folding both into one sealed type means the
/// watchdog resets on "any traffic" without special-casing.
sealed class SseMessage {
  const SseMessage();
}

class SseEvent extends SseMessage {
  const SseEvent({
    required this.event,
    required this.data,
    this.id,
  });

  /// The `event:` field, defaulting to `message` per the SSE spec. The
  /// server's ticks use `tick`; resume notices use `gap`; malformed lines
  /// carry no event field at all and therefore land on `message`.
  final String event;

  final String data;

  /// The last-event-id in force for this event. Per spec this persists across
  /// events until the server sends a new `id:` field, which is exactly what
  /// `Last-Event-ID` on reconnect needs.
  final int? id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SseEvent &&
          other.event == event &&
          other.data == data &&
          other.id == id;

  @override
  int get hashCode => Object.hash(event, data, id);

  @override
  String toString() => 'SseEvent(id: $id, event: $event, data: $data)';
}

/// A `:`-prefixed comment line. The server sends `: ping` every ~5s.
class SseComment extends SseMessage {
  const SseComment(this.text);

  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SseComment && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'SseComment($text)';
}
