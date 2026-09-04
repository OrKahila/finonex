import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/di/injector.dart';
import '../../app/theme/pulse_theme.dart';
import '../../core/app_config.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

/// Shown exactly once in the app's lifetime. After a successful sign-in the
/// credentials live in the Keychain and every later start restores silently.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _username;
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    final AppConfig config = getIt<AppConfig>();
    _username = TextEditingController(text: config.username);
    _password = TextEditingController(text: config.password);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthEvent.credentialsSubmitted(
            username: _username.text.trim(),
            password: _password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (BuildContext context, AuthState state) {
                  final bool busy = state is AuthAuthenticating;
                  final String? error =
                      state is AuthUnauthenticated ? state.errorMessage : null;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Pulse',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Live market watchlist',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: PulseColors.textSecondary),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _username,
                        enabled: !busy,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        enabled: !busy,
                        obscureText: true,
                        onSubmitted: (_) => busy ? null : _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (error != null) ...<Widget>[
                        const SizedBox(height: 16),
                        Text(
                          error,
                          style: const TextStyle(color: PulseColors.offline),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy ? null : _submit,
                        child: busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign in'),
                      ),
                      if (!context.read<AuthBloc>().isSecureStorageNative) ...<Widget>[
                        const SizedBox(height: 24),
                        const Text(
                          'This platform has no native secure storage '
                          'implementation. Credentials will be kept in memory '
                          'only for this run.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: PulseColors.degraded,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
