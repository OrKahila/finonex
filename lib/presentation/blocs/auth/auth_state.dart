import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;

  /// Cold start: checking secure storage, possibly logging in again.
  const factory AuthState.restoring() = AuthRestoring;

  const factory AuthState.unauthenticated({String? errorMessage}) =
      AuthUnauthenticated;

  const factory AuthState.authenticating() = AuthAuthenticating;

  const factory AuthState.authenticated() = AuthAuthenticated;
}
