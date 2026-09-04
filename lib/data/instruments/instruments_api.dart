import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../core/app_config.dart';
import '../../core/errors.dart';
import 'models/instrument.dart';

@lazySingleton
class InstrumentsApi {
  InstrumentsApi(this._client, this._config);

  static const Duration _timeout = Duration(seconds: 10);

  final HttpClient _client;
  final AppConfig _config;

  Future<List<Instrument>> fetch(String token) async {
    final HttpClientResponse response;
    final String body;
    try {
      final HttpClientRequest request = await _client
          .getUrl(_config.endpoint('/instruments'))
          .timeout(_timeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      response = await request.close().timeout(_timeout);
      body = await utf8.decodeStream(response).timeout(_timeout);
    } on Object catch (error) {
      throw TransportException('Could not load instruments: $error');
    }

    if (response.statusCode == HttpStatus.unauthorized) {
      throw const UnauthorizedException();
    }
    if (response.statusCode != HttpStatus.ok) {
      throw TransportException(
        'Instruments request failed',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const TransportException('Instruments response was not a list');
    }

    return <Instrument>[
      for (final Object? entry in decoded)
        if (entry is Map<String, dynamic>) Instrument.fromJson(entry),
    ];
  }
}
