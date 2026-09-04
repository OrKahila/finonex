import 'dart:math';

import 'package:injectable/injectable.dart';

import '../core/app_config.dart';

/// Exponential backoff with jitter.
///
/// Pure and injectable so the delay sequence can be asserted exactly with a
/// seeded [Random]. Jitter matters even with a single client: without it,
/// every client that dropped in the same server-side event retries in the same
/// millisecond forever.
@lazySingleton
class ReconnectPolicy {
  ReconnectPolicy(this._config, this._random);

  final AppConfig _config;
  final Random _random;

  /// [attempt] is zero-based: attempt 0 is the first retry after a drop.
  Duration delayFor(int attempt) {
    final int base = _config.backoffBase.inMilliseconds;
    final int cap = _config.backoffCap.inMilliseconds;

    // Shift rather than pow, and clamp the exponent so a long outage cannot
    // overflow into a negative delay.
    final int exponent = attempt.clamp(0, 30);
    final int uncapped =
        exponent >= 30 ? cap : (base << exponent).clamp(base, cap);

    final double jitter = 1 + (_random.nextDouble() * 2 - 1) * _config.backoffJitter;
    final int withJitter = (uncapped * jitter).round();

    return Duration(milliseconds: max(0, withJitter));
  }
}
