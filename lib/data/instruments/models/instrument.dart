import 'package:freezed_annotation/freezed_annotation.dart';

part 'instrument.freezed.dart';
part 'instrument.g.dart';

/// Static metadata from `GET /instruments`. Never changes during a session.
@freezed
abstract class Instrument with _$Instrument {
  const factory Instrument({
    required String symbol,
    required String name,
    required int decimals,
  }) = _Instrument;

  factory Instrument.fromJson(Map<String, dynamic> json) =>
      _$InstrumentFromJson(json);
}
