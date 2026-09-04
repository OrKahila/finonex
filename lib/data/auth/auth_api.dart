import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../core/app_config.dart';
import '../../core/clock.dart';
import '../../core/errors.dart';
import 'models/session.dart';

/// `POST /login`. The only unauthenticated endpoint.
@lazySingleton
class AuthApi {
  AuthApi(this._client, this._config, this._clock);

  static const Duration _timeout = Duration(seconds: 10);

  final HttpClient _client;
  final AppConfig _config;
  final Clock _clock;

  Future<Session> login({
    required String username,
    required String password,
  }) async {
    try {
      final HttpClientRequest request =
          await _client.postUrl(_config.endpoint('/login')).timeout(_timeout);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode(<String, String>{'username': username, 'password': password}),
      );

      final HttpClientResponse response = await request.close().timeout(_timeout);
      final String body =
          await utf8.decodeStream(response).timeout(_timeout);

      if (response.statusCode == HttpStatus.unauthorized) {
        throw const InvalidCredentialsException();
      }
      if (response.statusCode != HttpStatus.ok) {
        throw TransportException(
          'Login failed',
          statusCode: response.statusCode,
        );
      }

      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const TransportException('Login response was not an object');
      }
      final Object? token = decoded['token'];
      final Object? expiresIn = decoded['expiresIn'];
      if (token is! String || expiresIn is! num) {
        throw const TransportException('Login response was missing fields');
      }

      return Session(
        token: token,
        expiresAt: _clock.now().add(Duration(seconds: expiresIn.toInt())),
      );
    } on InvalidCredentialsException {
      rethrow;
    } on TransportException {
      rethrow;
    } on Object catch (error) {
      // Socket errors, timeouts, malformed JSON - all the same to the caller.
      throw TransportException('Login failed: $error');
    }
  }
}
