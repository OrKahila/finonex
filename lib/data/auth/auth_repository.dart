import 'package:injectable/injectable.dart';

import '../../core/app_config.dart';
import '../../core/clock.dart';
import '../../core/errors.dart';
import '../../domain/ports/secure_store.dart';
import 'auth_api.dart';
import 'models/session.dart';

class Credentials {
  const Credentials(this.username, this.password);

  final String username;
  final String password;
}

/// Owns the token lifecycle and everything that touches secure storage.
///
/// Deliberately passive: it has no timers. Callers ask for a token and get a
/// live one, refreshing transparently if needed. All scheduling lives in
/// FeedConnectionBloc so there is exactly one place where time-based behaviour
/// has to be reasoned about.
@lazySingleton
class AuthRepository {
  AuthRepository(this._api, this._store, this._clock, this._config);

  static const String keyToken = 'pulse.token';
  static const String keyTokenExpiresAt = 'pulse.token_expires_at';
  static const String keyUsername = 'pulse.username';
  static const String keyPassword = 'pulse.password';

  final AuthApi _api;
  final SecureStore _store;
  final Clock _clock;
  final AppConfig _config;

  Session? _session;

  /// Coalesces concurrent refreshes. The proactive refresh timer and a 401
  /// handler can easily fire at the same moment; without this we would burn
  /// two logins and race over which token wins.
  Future<Session>? _refreshInFlight;

  Session? get currentSession => _session;

  bool get isSecureStorageNative => _store.isBackedByPlatform;

  /// Interactive login. This is the only place the user is ever asked.
  Future<Session> logIn({
    required String username,
    required String password,
  }) async {
    final Session session =
        await _api.login(username: username, password: password);
    await _store.write(keyUsername, username);
    await _store.write(keyPassword, password);
    await _persist(session);
    _session = session;
    return session;
  }

  Future<bool> hasStoredCredentials() async =>
      (await _readCredentials()) != null;

  /// Cold start. Reuses a persisted token when it is somehow still alive
  /// (60s TTL makes that rare), otherwise logs in again from stored
  /// credentials. Either way the user sees no login screen.
  Future<Session> restore() async {
    final Session? persisted = await _readPersistedSession();
    if (persisted != null &&
        persisted.isUsableAt(_clock.now(), _config.tokenExpiryGrace)) {
      _session = persisted;
      return persisted;
    }
    return refresh();
  }

  /// A token guaranteed live for at least [AppConfig.tokenExpiryGrace].
  Future<String> validToken() async {
    final Session? session = _session;
    if (session != null &&
        session.isUsableAt(_clock.now(), _config.tokenExpiryGrace)) {
      return session.token;
    }
    return (await refresh()).token;
  }

  /// Forces a new token from stored credentials.
  Future<Session> refresh() {
    return _refreshInFlight ??=
        _refresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<Session> _refresh() async {
    final Credentials? credentials = await _readCredentials();
    if (credentials == null) throw const NoStoredCredentialsException();

    final Session session = await _api.login(
      username: credentials.username,
      password: credentials.password,
    );
    await _persist(session);
    _session = session;
    return session;
  }

  Future<void> logOut() async {
    _session = null;
    _refreshInFlight = null;
    await _store.deleteAll();
  }

  Future<void> _persist(Session session) async {
    await _store.write(keyToken, session.token);
    await _store.write(
      keyTokenExpiresAt,
      session.expiresAt.toIso8601String(),
    );
  }

  Future<Session?> _readPersistedSession() async {
    final String? token = await _store.read(keyToken);
    final String? expiresAt = await _store.read(keyTokenExpiresAt);
    if (token == null || expiresAt == null) return null;

    final DateTime? parsed = DateTime.tryParse(expiresAt);
    if (parsed == null) return null;

    return Session(token: token, expiresAt: parsed);
  }

  Future<Credentials?> _readCredentials() async {
    final String? username = await _store.read(keyUsername);
    final String? password = await _store.read(keyPassword);
    if (username == null || password == null) return null;
    return Credentials(username, password);
  }
}
