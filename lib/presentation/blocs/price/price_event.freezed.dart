// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PriceEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PriceEvent()';
}


}

/// @nodoc
class $PriceEventCopyWith<$Res>  {
$PriceEventCopyWith(PriceEvent _, $Res Function(PriceEvent) __);
}


/// Adds pattern-matching-related methods to [PriceEvent].
extension PriceEventPatterns on PriceEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PriceTickReceived value)?  tickReceived,TResult Function( PriceMalformedReceived value)?  malformedReceived,TResult Function( PriceFlushRequested value)?  flushRequested,TResult Function( PriceStalenessChecked value)?  stalenessChecked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PriceTickReceived() when tickReceived != null:
return tickReceived(_that);case PriceMalformedReceived() when malformedReceived != null:
return malformedReceived(_that);case PriceFlushRequested() when flushRequested != null:
return flushRequested(_that);case PriceStalenessChecked() when stalenessChecked != null:
return stalenessChecked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PriceTickReceived value)  tickReceived,required TResult Function( PriceMalformedReceived value)  malformedReceived,required TResult Function( PriceFlushRequested value)  flushRequested,required TResult Function( PriceStalenessChecked value)  stalenessChecked,}){
final _that = this;
switch (_that) {
case PriceTickReceived():
return tickReceived(_that);case PriceMalformedReceived():
return malformedReceived(_that);case PriceFlushRequested():
return flushRequested(_that);case PriceStalenessChecked():
return stalenessChecked(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PriceTickReceived value)?  tickReceived,TResult? Function( PriceMalformedReceived value)?  malformedReceived,TResult? Function( PriceFlushRequested value)?  flushRequested,TResult? Function( PriceStalenessChecked value)?  stalenessChecked,}){
final _that = this;
switch (_that) {
case PriceTickReceived() when tickReceived != null:
return tickReceived(_that);case PriceMalformedReceived() when malformedReceived != null:
return malformedReceived(_that);case PriceFlushRequested() when flushRequested != null:
return flushRequested(_that);case PriceStalenessChecked() when stalenessChecked != null:
return stalenessChecked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Tick tick)?  tickReceived,TResult Function()?  malformedReceived,TResult Function()?  flushRequested,TResult Function()?  stalenessChecked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PriceTickReceived() when tickReceived != null:
return tickReceived(_that.tick);case PriceMalformedReceived() when malformedReceived != null:
return malformedReceived();case PriceFlushRequested() when flushRequested != null:
return flushRequested();case PriceStalenessChecked() when stalenessChecked != null:
return stalenessChecked();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Tick tick)  tickReceived,required TResult Function()  malformedReceived,required TResult Function()  flushRequested,required TResult Function()  stalenessChecked,}) {final _that = this;
switch (_that) {
case PriceTickReceived():
return tickReceived(_that.tick);case PriceMalformedReceived():
return malformedReceived();case PriceFlushRequested():
return flushRequested();case PriceStalenessChecked():
return stalenessChecked();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Tick tick)?  tickReceived,TResult? Function()?  malformedReceived,TResult? Function()?  flushRequested,TResult? Function()?  stalenessChecked,}) {final _that = this;
switch (_that) {
case PriceTickReceived() when tickReceived != null:
return tickReceived(_that.tick);case PriceMalformedReceived() when malformedReceived != null:
return malformedReceived();case PriceFlushRequested() when flushRequested != null:
return flushRequested();case PriceStalenessChecked() when stalenessChecked != null:
return stalenessChecked();case _:
  return null;

}
}

}

/// @nodoc


class PriceTickReceived implements PriceEvent {
  const PriceTickReceived(this.tick);
  

 final  Tick tick;

/// Create a copy of PriceEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceTickReceivedCopyWith<PriceTickReceived> get copyWith => _$PriceTickReceivedCopyWithImpl<PriceTickReceived>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceTickReceived&&(identical(other.tick, tick) || other.tick == tick));
}


@override
int get hashCode => Object.hash(runtimeType,tick);

@override
String toString() {
  return 'PriceEvent.tickReceived(tick: $tick)';
}


}

/// @nodoc
abstract mixin class $PriceTickReceivedCopyWith<$Res> implements $PriceEventCopyWith<$Res> {
  factory $PriceTickReceivedCopyWith(PriceTickReceived value, $Res Function(PriceTickReceived) _then) = _$PriceTickReceivedCopyWithImpl;
@useResult
$Res call({
 Tick tick
});




}
/// @nodoc
class _$PriceTickReceivedCopyWithImpl<$Res>
    implements $PriceTickReceivedCopyWith<$Res> {
  _$PriceTickReceivedCopyWithImpl(this._self, this._then);

  final PriceTickReceived _self;
  final $Res Function(PriceTickReceived) _then;

/// Create a copy of PriceEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tick = null,}) {
  return _then(PriceTickReceived(
null == tick ? _self.tick : tick // ignore: cast_nullable_to_non_nullable
as Tick,
  ));
}


}

/// @nodoc


class PriceMalformedReceived implements PriceEvent {
  const PriceMalformedReceived();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceMalformedReceived);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PriceEvent.malformedReceived()';
}


}




/// @nodoc


class PriceFlushRequested implements PriceEvent {
  const PriceFlushRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceFlushRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PriceEvent.flushRequested()';
}


}




/// @nodoc


class PriceStalenessChecked implements PriceEvent {
  const PriceStalenessChecked();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceStalenessChecked);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PriceEvent.stalenessChecked()';
}


}




// dart format on
