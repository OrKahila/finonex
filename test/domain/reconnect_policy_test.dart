import 'dart:math';

import 'package:finonex/core/app_config.dart';
import 'package:finonex/domain/reconnect_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  const AppConfig config = AppConfig();

  test('doubles from the base delay and stops at the cap', () {
    final ReconnectPolicy policy = ReconnectPolicy(config, FixedRandom());

    expect(
      List<int>.generate(8, (int i) => policy.delayFor(i).inMilliseconds),
      <int>[500, 1000, 2000, 4000, 8000, 15000, 15000, 15000],
    );
  });

  test('jitter stays inside the configured band', () {
    final ReconnectPolicy policy = ReconnectPolicy(config, Random(7));

    for (int attempt = 0; attempt < 12; attempt++) {
      final int nominal = (config.backoffBase.inMilliseconds << attempt.clamp(0, 30))
          .clamp(config.backoffBase.inMilliseconds, config.backoffCap.inMilliseconds);

      for (int i = 0; i < 200; i++) {
        final int delay = policy.delayFor(attempt).inMilliseconds;
        expect(delay, greaterThanOrEqualTo((nominal * 0.8).floor()));
        expect(delay, lessThanOrEqualTo((nominal * 1.2).ceil()));
      }
    }
  });

  test('jitter actually varies, so clients do not retry in lockstep', () {
    final ReconnectPolicy policy = ReconnectPolicy(config, Random(11));

    final Set<int> delays = <int>{
      for (int i = 0; i < 50; i++) policy.delayFor(3).inMilliseconds,
    };

    expect(delays.length, greaterThan(10));
  });

  test('a very long outage cannot overflow into a negative delay', () {
    final ReconnectPolicy policy = ReconnectPolicy(config, FixedRandom());

    for (final int attempt in <int>[31, 64, 1000, 1 << 40]) {
      final Duration delay = policy.delayFor(attempt);
      expect(delay, config.backoffCap);
    }
  });
}
