import 'dart:io';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:pulse_native/pulse_native.dart';

import '../../core/app_config.dart';
import '../../core/clock.dart';
import '../../data/feed/price_store.dart';
import '../../domain/ports/tick_sink.dart';

/// Third-party and platform objects that we do not own and therefore cannot
/// annotate directly.
@module
abstract class RegisterModule {
  @lazySingleton
  AppConfig get config => const AppConfig();

  @lazySingleton
  Clock get clock => const SystemClock();

  /// Seeded per-process; tests inject a fixed seed so backoff jitter is
  /// reproducible.
  @lazySingleton
  Random get random => Random();

  @lazySingleton
  HttpClient get httpClient => HttpClient();

  /// Resolves to the Keychain/NWPathMonitor implementation on iOS and to an
  /// in-memory stub elsewhere. See packages/pulse_native.
  @lazySingleton
  PulseNativePlatform get pulseNative => PulseNativePlatform.instance;

  /// The store is bound both to its own type (the UI reads per-symbol
  /// listenables and diagnostics from it) and to the narrow [TickSink] the
  /// connection bloc writes through.
  @lazySingleton
  TickSink tickSink(PriceStore store) => store;
}
