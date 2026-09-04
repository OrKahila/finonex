// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'watchlist_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WatchlistEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchlistEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WatchlistEvent()';
}


}

/// @nodoc
class $WatchlistEventCopyWith<$Res>  {
$WatchlistEventCopyWith(WatchlistEvent _, $Res Function(WatchlistEvent) __);
}


/// Adds pattern-matching-related methods to [WatchlistEvent].
extension WatchlistEventPatterns on WatchlistEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WatchlistRequested value)?  requested,TResult Function( WatchlistRetried value)?  retried,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WatchlistRequested() when requested != null:
return requested(_that);case WatchlistRetried() when retried != null:
return retried(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WatchlistRequested value)  requested,required TResult Function( WatchlistRetried value)  retried,}){
final _that = this;
switch (_that) {
case WatchlistRequested():
return requested(_that);case WatchlistRetried():
return retried(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WatchlistRequested value)?  requested,TResult? Function( WatchlistRetried value)?  retried,}){
final _that = this;
switch (_that) {
case WatchlistRequested() when requested != null:
return requested(_that);case WatchlistRetried() when retried != null:
return retried(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  requested,TResult Function()?  retried,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WatchlistRequested() when requested != null:
return requested();case WatchlistRetried() when retried != null:
return retried();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  requested,required TResult Function()  retried,}) {final _that = this;
switch (_that) {
case WatchlistRequested():
return requested();case WatchlistRetried():
return retried();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  requested,TResult? Function()?  retried,}) {final _that = this;
switch (_that) {
case WatchlistRequested() when requested != null:
return requested();case WatchlistRetried() when retried != null:
return retried();case _:
  return null;

}
}

}

/// @nodoc


class WatchlistRequested implements WatchlistEvent {
  const WatchlistRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchlistRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WatchlistEvent.requested()';
}


}




/// @nodoc


class WatchlistRetried implements WatchlistEvent {
  const WatchlistRetried();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchlistRetried);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WatchlistEvent.retried()';
}


}




// dart format on
