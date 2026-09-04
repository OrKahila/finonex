import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true, asExtension: true)
void configureDependencies() => getIt.init();
