import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../core/app_config.dart';

/// Decides *when* buffered ticks are pushed to the UI.
///
/// An interface so tests can flush on demand instead of waiting on real time.
abstract class ConflationScheduler {
  /// Requests a flush. Repeated calls before the flush happens must collapse
  /// into one - that collapsing is the whole mechanism.
  void schedule(void Function() flush);

  void dispose();
}

/// Coalesces on a short timer.
///
/// Deliberately a timer rather than `addPostFrameCallback`: post-frame
/// callbacks only run if a frame was already scheduled, and when the tree is
/// otherwise idle nothing schedules one - the first tick after a quiet moment
/// would sit in the buffer indefinitely. A 16ms timer is frame-rate-shaped
/// without depending on a frame being pumped.
@LazySingleton(as: ConflationScheduler)
class TimerConflationScheduler implements ConflationScheduler {
  TimerConflationScheduler(this._config);

  final AppConfig _config;
  Timer? _timer;

  @override
  void schedule(void Function() flush) {
    if (_timer != null) return;
    _timer = Timer(_config.conflationInterval, () {
      _timer = null;
      flush();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
