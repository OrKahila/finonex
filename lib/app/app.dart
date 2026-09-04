import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/auth/auth_event.dart';
import '../presentation/blocs/auth/auth_state.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/watchlist_screen.dart';
import 'di/injector.dart';
import 'theme/pulse_theme.dart';

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: buildPulseTheme(),
      home: BlocProvider<AuthBloc>(
        create: (_) => getIt<AuthBloc>()..add(const AuthEvent.bootstrapRequested()),
        child: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (BuildContext context, AuthState state) {
        return switch (state) {
          AuthInitial() || AuthRestoring() => const _Splash(),
          AuthUnauthenticated() || AuthAuthenticating() => const LoginScreen(),
          AuthAuthenticated() => const WatchlistScreen(),
        };
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
