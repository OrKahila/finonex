// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instrument.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Instrument _$InstrumentFromJson(Map<String, dynamic> json) => _Instrument(
  symbol: json['symbol'] as String,
  name: json['name'] as String,
  decimals: (json['decimals'] as num).toInt(),
);

Map<String, dynamic> _$InstrumentToJson(_Instrument instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'name': instance.name,
      'decimals': instance.decimals,
    };
