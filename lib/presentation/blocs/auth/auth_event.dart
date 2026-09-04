import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  /// Fired once at startup: log back in silently if we have stored credentials.
  const factory AuthEvent.bootstrapRequested() = AuthBootstrapRequested;

  const factory AuthEvent.credentialsSubmitted({
    required String username,
    required String password,
  }) = AuthCredentialsSubmitted;

  /// The feed gave up authenticating with the credentials we hold. This is the
  /// only path that puts the user back in front of a login form.
  const factory AuthEvent.sessionRejected() = AuthSessionRejected;

  const factory AuthEvent.logOutRequested() = AuthLogOutRequested;
}
