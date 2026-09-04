// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedState {

 ConnectionPhase get phase;/// How many consecutive reconnect attempts have been scheduled.
 int get attempt;/// When the current silence began. Drives the "no data for Ns" readout.
 DateTime? get silentSince;/// When the pending backoff timer fires. Drives the countdown.
 DateTime? get nextAttemptAt;/// How many times the server told us our resume point was too old. Each
/// one is a hole in history we can never fill.
 int get gapCount; String? get message;
/// Create a copy of FeedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedStateCopyWith<FeedState> get copyWith => _$FeedStateCopyWithImpl<FeedState>(this as FeedState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.silentSince, silentSince) || other.silentSince == silentSince)&&(identical(other.nextAttemptAt, nextAttemptAt) || other.nextAttemptAt == nextAttemptAt)&&(identical(other.gapCount, gapCount) || other.gapCount == gapCount)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,phase,attempt,silentSince,nextAttemptAt,gapCount,message);

@override
String toString() {
  return 'FeedState(phase: $phase, attempt: $attempt, silentSince: $silentSince, nextAttemptAt: $nextAttemptAt, gapCount: $gapCount, message: $message)';
}


}

/// @nodoc
abstract mixin class $FeedStateCopyWith<$Res>  {
  factory $FeedStateCopyWith(FeedState value, $Res Function(FeedState) _then) = _$FeedStateCopyWithImpl;
@useResult
$Res call({
 ConnectionPhase phase, int attempt, DateTime? silentSince, DateTime? nextAttemptAt, int gapCount, String? message
});




}
/// @nodoc
class _$FeedStateCopyWithImpl<$Res>
    implements $FeedStateCopyWith<$Res> {
  _$FeedStateCopyWithImpl(this._self, this._then);

  final FeedState _self;
  final $Res Function(FeedState) _then;

/// Create a copy of FeedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? attempt = null,Object? silentSince = freezed,Object? nextAttemptAt = freezed,Object? gapCount = null,Object? message = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ConnectionPhase,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,silentSince: freezed == silentSince ? _self.silentSince : silentSince // ignore: cast_nullable_to_non_nullable
as DateTime?,nextAttemptAt: freezed == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,gapCount: null == gapCount ? _self.gapCount : gapCount // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedState].
extension FeedStatePatterns on FeedState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedState value)  $default,){
final _that = this;
switch (_that) {
case _FeedState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedState value)?  $default,){
final _that = this;
switch (_that) {
case _FeedState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ConnectionPhase phase,  int attempt,  DateTime? silentSince,  DateTime? nextAttemptAt,  int gapCount,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedState() when $default != null:
return $default(_that.phase,_that.attempt,_that.silentSince,_that.nextAttemptAt,_that.gapCount,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ConnectionPhase phase,  int attempt,  DateTime? silentSince,  DateTime? nextAttemptAt,  int gapCount,  String? message)  $default,) {final _that = this;
switch (_that) {
case _FeedState():
return $default(_that.phase,_that.attempt,_that.silentSince,_that.nextAttemptAt,_that.gapCount,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ConnectionPhase phase,  int attempt,  DateTime? silentSince,  DateTime? nextAttemptAt,  int gapCount,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _FeedState() when $default != null:
return $default(_that.phase,_that.attempt,_that.silentSince,_that.nextAttemptAt,_that.gapCount,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _FeedState extends FeedState {
  const _FeedState({this.phase = ConnectionPhase.idle, this.attempt = 0, this.silentSince, this.nextAttemptAt, this.gapCount = 0, this.message}): super._();
  

@override@JsonKey() final  ConnectionPhase phase;
/// How many consecutive reconnect attempts have been scheduled.
@override@JsonKey() final  int attempt;
/// When the current silence began. Drives the "no data for Ns" readout.
@override final  DateTime? silentSince;
/// When the pending backoff timer fires. Drives the countdown.
@override final  DateTime? nextAttemptAt;
/// How many times the server told us our resume point was too old. Each
/// one is a hole in history we can never fill.
@override@JsonKey() final  int gapCount;
@override final  String? message;

/// Create a copy of FeedState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedStateCopyWith<_FeedState> get copyWith => __$FeedStateCopyWithImpl<_FeedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.silentSince, silentSince) || other.silentSince == silentSince)&&(identical(other.nextAttemptAt, nextAttemptAt) || other.nextAttemptAt == nextAttemptAt)&&(identical(other.gapCount, gapCount) || other.gapCount == gapCount)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,phase,attempt,silentSince,nextAttemptAt,gapCount,message);

@override
String toString() {
  return 'FeedState(phase: $phase, attempt: $attempt, silentSince: $silentSince, nextAttemptAt: $nextAttemptAt, gapCount: $gapCount, message: $message)';
}


}

/// @nodoc
abstract mixin class _$FeedStateCopyWith<$Res> implements $FeedStateCopyWith<$Res> {
  factory _$FeedStateCopyWith(_FeedState value, $Res Function(_FeedState) _then) = __$FeedStateCopyWithImpl;
@override @useResult
$Res call({
 ConnectionPhase phase, int attempt, DateTime? silentSince, DateTime? nextAttemptAt, int gapCount, String? message
});




}
/// @nodoc
class __$FeedStateCopyWithImpl<$Res>
    implements _$FeedStateCopyWith<$Res> {
  __$FeedStateCopyWithImpl(this._self, this._then);

  final _FeedState _self;
  final $Res Function(_FeedState) _then;

/// Create a copy of FeedState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? attempt = null,Object? silentSince = freezed,Object? nextAttemptAt = freezed,Object? gapCount = null,Object? message = freezed,}) {
  return _then(_FeedState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ConnectionPhase,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,silentSince: freezed == silentSince ? _self.silentSince : silentSince // ignore: cast_nullable_to_non_nullable
as DateTime?,nextAttemptAt: freezed == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,gapCount: null == gapCount ? _self.gapCount : gapCount // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
