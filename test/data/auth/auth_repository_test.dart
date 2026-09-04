import 'package:finonex/core/app_config.dart';
import 'package:finonex/core/errors.dart';
import 'package:finonex/data/auth/auth_repository.dart';
import 'package:finonex/data/auth/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const AppConfig config = AppConfig();

  late MutableClock clock;
  late FakeSecureStore store;
  late FakeAuthApi api;
  late AuthRepository repository;

  setUp(() {
    clock = MutableClock(DateTime.utc(2026, 1, 1, 12));
    store = FakeSecureStore();
    api = FakeAuthApi(clock);
    repository = AuthRepository(api, store, clock, config);
  });

  void storeCredentials() {
    store.values[AuthRepository.keyUsername] = 'trader';
    store.values[AuthRepository.keyPassword] = 'password123';
  }

  group('logging in', () {
    test('persists credentials and token to secure storage', () async {
      await repository.logIn(username: 'trader', password: 'password123');

      expect(store.values[AuthRepository.keyUsername], 'trader');
      expect(store.values[AuthRepository.keyPassword], 'password123');
      expect(store.values[AuthRepository.keyToken], 'token-1');
      expect(store.values[AuthRepository.keyTokenExpiresAt], isNotNull);
    });

    test('bad credentials are not persisted', () async {
      await expectLater(
        repository.logIn(username: 'trader', password: 'wrong'),
        throwsA(isA<InvalidCredentialsException>()),
      );

      expect(store.values, isEmpty);
    });
  });

  group('restoring on cold start', () {
    test('reuses a persisted token that is somehow still alive', () async {
      storeCredentials();
      store.values[AuthRepository.keyToken] = 'persisted';
      store.values[AuthRepository.keyTokenExpiresAt] =
          clock.now().add(const Duration(seconds: 30)).toIso8601String();

      final Session session = await repository.restore();

      expect(session.token, 'persisted');
      expect(api.calls, 0, reason: 'no need to log in again');
    });

    test('logs in again silently when the persisted token has expired', () async {
      storeCredentials();
      store.values[AuthRepository.keyToken] = 'expired';
      store.values[AuthRepository.keyTokenExpiresAt] =
          clock.now().subtract(const Duration(seconds: 1)).toIso8601String();

      final Session session = await repository.restore();

      // This is the case that actually happens: tokens live 60s, so a cold
      // start almost always finds a dead one. The user still sees no login.
      expect(session.token, 'token-1');
      expect(api.calls, 1);
    });

    test('without stored credentials there is nothing to restore', () async {
      await expectLater(
        repository.restore(),
        throwsA(isA<NoStoredCredentialsException>()),
      );
    });

    test('a token about to expire is treated as already dead', () async {
      storeCredentials();
      store.values[AuthRepository.keyToken] = 'almost-gone';
      store.values[AuthRepository.keyTokenExpiresAt] = clock
          .now()
          .add(config.tokenExpiryGrace - const Duration(seconds: 1))
          .toIso8601String();

      final Session session = await repository.restore();

      expect(session.token, 'token-1',
          reason: 'never open a stream with a token that dies mid-handshake');
    });

    test('a corrupt expiry in storage is ignored rather than trusted', () async {
      storeCredentials();
      store.values[AuthRepository.keyToken] = 'whatever';
      store.values[AuthRepository.keyTokenExpiresAt] = 'not-a-date';

      final Session session = await repository.restore();

      expect(session.token, 'token-1');
    });
  });

  group('validToken', () {
    test('returns the cached token while it is alive', () async {
      storeCredentials();
      await repository.restore();

      expect(await repository.validToken(), 'token-1');
      expect(await repository.validToken(), 'token-1');
      expect(api.calls, 1);
    });

    test('refreshes once the token lapses', () async {
      storeCredentials();
      await repository.restore();

      clock.advance(const Duration(seconds: 61));

      expect(await repository.validToken(), 'token-2');
      expect(api.calls, 2);
    });
  });

  test('concurrent refreshes collapse into one login', () async {
    storeCredentials();

    // The proactive refresh timer and a 401 handler can fire together; two
    // logins would race over which token wins.
    final List<Session> sessions = await Future.wait<Session>(<Future<Session>>[
      repository.refresh(),
      repository.refresh(),
      repository.refresh(),
    ]);

    expect(api.calls, 1);
    expect(sessions.map((Session s) => s.token).toSet(), <String>{'token-1'});
  });

  test('logging out clears every stored secret', () async {
    await repository.logIn(username: 'trader', password: 'password123');
    await repository.logOut();

    expect(store.values, isEmpty);
    expect(repository.currentSession, isNull);
  });
}
