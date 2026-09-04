import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/errors.dart';
import '../../../data/auth/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Owns "is there a usable session", nothing more.
///
/// Note what is *not* here: token refresh scheduling. Refresh is the feed's
/// concern because the feed is what suffers when a token dies mid-stream.
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState.initial()) {
    on<AuthBootstrapRequested>(_onBootstrap);
    on<AuthCredentialsSubmitted>(_onCredentialsSubmitted);
    on<AuthSessionRejected>(_onSessionRejected);
    on<AuthLogOutRequested>(_onLogOut);
  }

  final AuthRepository _repository;

  bool get isSecureStorageNative => _repository.isSecureStorageNative;

  Future<void> _onBootstrap(
    AuthBootstrapRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.restoring());

    if (!await _repository.hasStoredCredentials()) {
      emit(const AuthState.unauthenticated());
      return;
    }

    try {
      await _repository.restore();
      emit(const AuthState.authenticated());
    } on InvalidCredentialsException {
      // Stored credentials no longer work. This is the one case where we have
      // to bother the user again.
      await _repository.logOut();
      emit(const AuthState.unauthenticated(
        errorMessage: 'Saved credentials were rejected. Please sign in again.',
      ));
    } on NoStoredCredentialsException {
      emit(const AuthState.unauthenticated());
    } on Object {
      // The server is unreachable right now. That is a feed problem, not an
      // auth problem: go through to the watchlist and let the connection
      // layer retry with backoff rather than dumping the user on a login form
      // they cannot get past anyway.
      emit(const AuthState.authenticated());
    }
  }

  Future<void> _onCredentialsSubmitted(
    AuthCredentialsSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.authenticating());
    try {
      await _repository.logIn(
        username: event.username,
        password: event.password,
      );
      emit(const AuthState.authenticated());
    } on InvalidCredentialsException {
      emit(const AuthState.unauthenticated(
        errorMessage: 'Invalid username or password.',
      ));
    } on TransportException catch (error) {
      emit(AuthState.unauthenticated(
        errorMessage: 'Cannot reach the feed server (${error.message}).',
      ));
    } on Object catch (error) {
      emit(AuthState.unauthenticated(errorMessage: 'Sign-in failed: $error'));
    }
  }

  Future<void> _onSessionRejected(
    AuthSessionRejected event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logOut();
    emit(const AuthState.unauthenticated(
      errorMessage: 'Session rejected by the server. Please sign in again.',
    ));
  }

  Future<void> _onLogOut(
    AuthLogOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logOut();
    emit(const AuthState.unauthenticated());
  }
}
