// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:io' as _i497;
import 'dart:math' as _i407;

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:pulse_native/pulse_native.dart' as _i1048;

import '../../core/app_config.dart' as _i207;
import '../../core/clock.dart' as _i215;
import '../../core/periodic_ticker.dart' as _i30;
import '../../data/auth/auth_api.dart' as _i812;
import '../../data/auth/auth_repository.dart' as _i344;
import '../../data/feed/conflation_scheduler.dart' as _i329;
import '../../data/feed/sse/http_sse_transport.dart' as _i314;
import '../../data/feed/sse/sse_transport.dart' as _i929;
import '../../data/instruments/instruments_api.dart' as _i484;
import '../../data/instruments/instruments_repository.dart' as _i408;
import '../../data/platform/pulse_native_network_monitor.dart' as _i110;
import '../../data/platform/pulse_native_secure_store.dart' as _i882;
import '../../domain/ports/network_monitor.dart' as _i231;
import '../../domain/ports/secure_store.dart' as _i8;
import '../../domain/ports/tick_sink.dart' as _i753;
import '../../domain/reconnect_policy.dart' as _i725;
import '../../presentation/blocs/auth/auth_bloc.dart' as _i141;
import '../../presentation/blocs/feed/feed_connection_bloc.dart' as _i905;
import '../../presentation/blocs/price/price_bloc.dart' as _i397;
import '../../presentation/blocs/price/price_bloc_tick_sink.dart' as _i901;
import '../../presentation/blocs/watchlist/watchlist_bloc.dart' as _i929;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i207.AppConfig>(() => registerModule.config);
    gh.lazySingleton<_i215.Clock>(() => registerModule.clock);
    gh.lazySingleton<_i407.Random>(() => registerModule.random);
    gh.lazySingleton<_i497.HttpClient>(() => registerModule.httpClient);
    gh.lazySingleton<_i1048.PulseNativePlatform>(
      () => registerModule.pulseNative,
    );
    gh.lazySingleton<_i8.SecureStore>(
      () => _i882.PulseNativeSecureStore(gh<_i1048.PulseNativePlatform>()),
    );
    gh.factory<_i30.PeriodicTicker>(() => _i30.TimerPeriodicTicker());
    gh.lazySingleton<_i329.ConflationScheduler>(
      () => _i329.TimerConflationScheduler(gh<_i207.AppConfig>()),
    );
    gh.lazySingleton<_i231.NetworkMonitor>(
      () => _i110.PulseNativeNetworkMonitor(gh<_i1048.PulseNativePlatform>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i812.AuthApi>(
      () => _i812.AuthApi(
        gh<_i497.HttpClient>(),
        gh<_i207.AppConfig>(),
        gh<_i215.Clock>(),
      ),
    );
    gh.lazySingleton<_i929.SseTransport>(
      () =>
          _i314.HttpSseTransport(gh<_i497.HttpClient>(), gh<_i207.AppConfig>()),
    );
    gh.lazySingleton<_i725.ReconnectPolicy>(
      () => _i725.ReconnectPolicy(gh<_i207.AppConfig>(), gh<_i407.Random>()),
    );
    gh.lazySingleton<_i484.InstrumentsApi>(
      () => _i484.InstrumentsApi(gh<_i497.HttpClient>(), gh<_i207.AppConfig>()),
    );
    gh.lazySingleton<_i344.AuthRepository>(
      () => _i344.AuthRepository(
        gh<_i812.AuthApi>(),
        gh<_i8.SecureStore>(),
        gh<_i215.Clock>(),
        gh<_i207.AppConfig>(),
      ),
    );
    gh.lazySingleton<_i397.PriceBloc>(
      () => _i397.PriceBloc(
        gh<_i207.AppConfig>(),
        gh<_i215.Clock>(),
        gh<_i329.ConflationScheduler>(),
        gh<_i30.PeriodicTicker>(),
      ),
    );
    gh.lazySingleton<_i408.InstrumentsRepository>(
      () => _i408.InstrumentsRepository(
        gh<_i484.InstrumentsApi>(),
        gh<_i344.AuthRepository>(),
      ),
    );
    gh.factory<_i929.WatchlistBloc>(
      () => _i929.WatchlistBloc(gh<_i408.InstrumentsRepository>()),
    );
    gh.factory<_i141.AuthBloc>(
      () => _i141.AuthBloc(gh<_i344.AuthRepository>()),
    );
    gh.lazySingleton<_i753.TickSink>(
      () => _i901.PriceBlocTickSink(gh<_i397.PriceBloc>()),
    );
    gh.factory<_i905.FeedConnectionBloc>(
      () => _i905.FeedConnectionBloc(
        gh<_i929.SseTransport>(),
        gh<_i344.AuthRepository>(),
        gh<_i753.TickSink>(),
        gh<_i231.NetworkMonitor>(),
        gh<_i725.ReconnectPolicy>(),
        gh<_i207.AppConfig>(),
        gh<_i215.Clock>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
