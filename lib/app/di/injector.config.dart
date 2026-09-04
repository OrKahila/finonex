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
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
