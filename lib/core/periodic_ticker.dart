import 'dart:async';

import 'package:injectable/injectable.dart';

/// A repeating tick source.
///
/// Injected for the same reason [Clock] is. A bloc that creates its own
/// `Timer.periodic` can only be driven by real elapsed time, and leaves a
/// pending timer behind that `testWidgets` rejects outright. Tests supply one
/// they fire by hand.
abstract class PeriodicTicker {
  /// Replaces any previous schedule.
  void start(Duration interval, void Function() onTick);

  void stop();
}

@Injectable(as: PeriodicTicker)
class TimerPeriodicTicker implements PeriodicTicker {
  Timer? _timer;

  @override
  void start(Duration interval, void Function() onTick) {
    stop();
    _timer = Timer.periodic(interval, (_) => onTick());
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
