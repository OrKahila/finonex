import 'package:injectable/injectable.dart';

import '../../core/errors.dart';
import '../auth/auth_repository.dart';
import '../auth/models/session.dart';
import 'instruments_api.dart';
import 'models/instrument.dart';

@lazySingleton
class InstrumentsRepository {
  InstrumentsRepository(this._api, this._auth);

  final InstrumentsApi _api;
  final AuthRepository _auth;

  /// Loads the instrument list, refreshing the token once if the server says
  /// ours is dead. Tokens live 60 seconds, so a 401 here is routine rather
  /// than exceptional.
  Future<List<Instrument>> load() async {
    try {
      return await _api.fetch(await _auth.validToken());
    } on UnauthorizedException {
      final Session session = await _auth.refresh();
      return _api.fetch(session.token);
    }
  }
}
