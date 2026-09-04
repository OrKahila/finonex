// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'instrument.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Instrument {

 String get symbol; String get name; int get decimals;
/// Create a copy of Instrument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstrumentCopyWith<Instrument> get copyWith => _$InstrumentCopyWithImpl<Instrument>(this as Instrument, _$identity);

  /// Serializes this Instrument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Instrument&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.decimals, decimals) || other.decimals == decimals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,name,decimals);

@override
String toString() {
  return 'Instrument(symbol: $symbol, name: $name, decimals: $decimals)';
}


}

/// @nodoc
abstract mixin class $InstrumentCopyWith<$Res>  {
  factory $InstrumentCopyWith(Instrument value, $Res Function(Instrument) _then) = _$InstrumentCopyWithImpl;
@useResult
$Res call({
 String symbol, String name, int decimals
});




}
/// @nodoc
class _$InstrumentCopyWithImpl<$Res>
    implements $InstrumentCopyWith<$Res> {
  _$InstrumentCopyWithImpl(this._self, this._then);

  final Instrument _self;
  final $Res Function(Instrument) _then;

/// Create a copy of Instrument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? name = null,Object? decimals = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,decimals: null == decimals ? _self.decimals : decimals // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Instrument].
extension InstrumentPatterns on Instrument {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Instrument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Instrument() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Instrument value)  $default,){
final _that = this;
switch (_that) {
case _Instrument():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Instrument value)?  $default,){
final _that = this;
switch (_that) {
case _Instrument() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String name,  int decimals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Instrument() when $default != null:
return $default(_that.symbol,_that.name,_that.decimals);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String name,  int decimals)  $default,) {final _that = this;
switch (_that) {
case _Instrument():
return $default(_that.symbol,_that.name,_that.decimals);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String name,  int decimals)?  $default,) {final _that = this;
switch (_that) {
case _Instrument() when $default != null:
return $default(_that.symbol,_that.name,_that.decimals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Instrument implements Instrument {
  const _Instrument({required this.symbol, required this.name, required this.decimals});
  factory _Instrument.fromJson(Map<String, dynamic> json) => _$InstrumentFromJson(json);

@override final  String symbol;
@override final  String name;
@override final  int decimals;

/// Create a copy of Instrument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstrumentCopyWith<_Instrument> get copyWith => __$InstrumentCopyWithImpl<_Instrument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstrumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Instrument&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.decimals, decimals) || other.decimals == decimals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,name,decimals);

@override
String toString() {
  return 'Instrument(symbol: $symbol, name: $name, decimals: $decimals)';
}


}

/// @nodoc
abstract mixin class _$InstrumentCopyWith<$Res> implements $InstrumentCopyWith<$Res> {
  factory _$InstrumentCopyWith(_Instrument value, $Res Function(_Instrument) _then) = __$InstrumentCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String name, int decimals
});




}
/// @nodoc
class __$InstrumentCopyWithImpl<$Res>
    implements _$InstrumentCopyWith<$Res> {
  __$InstrumentCopyWithImpl(this._self, this._then);

  final _Instrument _self;
  final $Res Function(_Instrument) _then;

/// Create a copy of Instrument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? name = null,Object? decimals = null,}) {
  return _then(_Instrument(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,decimals: null == decimals ? _self.decimals : decimals // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
