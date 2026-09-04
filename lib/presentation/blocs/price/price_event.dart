import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/feed/tick.dart';

part 'price_event.freezed.dart';

@freezed
sealed class PriceEvent with _$PriceEvent {
  /// One accepted-or-not tick off the wire. Handled synchronously and does
  /// **not** emit: it only runs the correctness filters and asks for a flush.
  const factory PriceEvent.tickReceived(Tick tick) = PriceTickReceived;

  /// An event we could not decode. Counted, never fatal.
  const factory PriceEvent.malformedReceived() = PriceMalformedReceived;

  /// Publish whatever survived the last window. Raised by the conflation
  /// scheduler, which collapses repeats, so this arrives at most once per
  /// window no matter how many ticks landed in it.
  const factory PriceEvent.flushRequested() = PriceFlushRequested;

  /// One-per-second sweep marking symbols that have gone quiet.
  const factory PriceEvent.stalenessChecked() = PriceStalenessChecked;
}
