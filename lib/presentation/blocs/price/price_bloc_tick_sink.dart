import 'package:injectable/injectable.dart';

import '../../../data/feed/tick.dart';
import '../../../domain/ports/tick_sink.dart';
import 'price_bloc.dart';
import 'price_event.dart';

/// Bridges the connection bloc's [TickSink] port to [PriceBloc].
///
/// The alternative - having FeedConnectionBloc hold a PriceBloc and call
/// `add` on it - couples two blocs directly, which is a worse smell than the
/// one this refactor set out to fix. Keeping the port also means the
/// connection bloc and its twenty tests are untouched by which state
/// management sits downstream of it.
@LazySingleton(as: TickSink)
class PriceBlocTickSink implements TickSink {
  PriceBlocTickSink(this._bloc);

  final PriceBloc _bloc;

  @override
  void add(Tick tick) {
    if (_bloc.isClosed) return;
    _bloc.add(PriceEvent.tickReceived(tick));
  }

  @override
  void noteMalformed() {
    if (_bloc.isClosed) return;
    _bloc.add(const PriceEvent.malformedReceived());
  }
}
