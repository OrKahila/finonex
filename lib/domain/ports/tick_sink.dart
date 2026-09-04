import '../../data/feed/tick.dart';

/// Where accepted ticks go.
///
/// The connection bloc owns the *control* plane (is there a healthy stream?)
/// and pushes ticks straight into this sink rather than through bloc state.
/// Routing 60-90 ticks/sec - 220 in a burst - through emit() would rebuild the
/// widget tree at tick rate, which is exactly what the brief says must not
/// happen. Correctness filtering (dedup, ordering) lives behind this interface.
abstract class TickSink {
  void add(Tick tick);

  /// An event arrived that we could not turn into a tick. Counted for the
  /// diagnostics row so "the feed is misbehaving and we are coping" is
  /// visible rather than merely claimed.
  void noteMalformed();
}
