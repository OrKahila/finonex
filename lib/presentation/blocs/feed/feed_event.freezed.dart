// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FeedEvent()';
}


}

/// @nodoc
class $FeedEventCopyWith<$Res>  {
$FeedEventCopyWith(FeedEvent _, $Res Function(FeedEvent) __);
}


/// Adds pattern-matching-related methods to [FeedEvent].
extension FeedEventPatterns on FeedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FeedStarted value)?  started,TResult Function( FeedStopped value)?  stopped,TResult Function( FeedConnectRequested value)?  connectRequested,TResult Function( FeedMessageReceived value)?  messageReceived,TResult Function( FeedStreamClosed value)?  streamClosed,TResult Function( FeedWatchdogTicked value)?  watchdogTicked,TResult Function( FeedNetworkStatusChanged value)?  networkStatusChanged,TResult Function( FeedTokenRefreshRequested value)?  tokenRefreshRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FeedStarted() when started != null:
return started(_that);case FeedStopped() when stopped != null:
return stopped(_that);case FeedConnectRequested() when connectRequested != null:
return connectRequested(_that);case FeedMessageReceived() when messageReceived != null:
return messageReceived(_that);case FeedStreamClosed() when streamClosed != null:
return streamClosed(_that);case FeedWatchdogTicked() when watchdogTicked != null:
return watchdogTicked(_that);case FeedNetworkStatusChanged() when networkStatusChanged != null:
return networkStatusChanged(_that);case FeedTokenRefreshRequested() when tokenRefreshRequested != null:
return tokenRefreshRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FeedStarted value)  started,required TResult Function( FeedStopped value)  stopped,required TResult Function( FeedConnectRequested value)  connectRequested,required TResult Function( FeedMessageReceived value)  messageReceived,required TResult Function( FeedStreamClosed value)  streamClosed,required TResult Function( FeedWatchdogTicked value)  watchdogTicked,required TResult Function( FeedNetworkStatusChanged value)  networkStatusChanged,required TResult Function( FeedTokenRefreshRequested value)  tokenRefreshRequested,}){
final _that = this;
switch (_that) {
case FeedStarted():
return started(_that);case FeedStopped():
return stopped(_that);case FeedConnectRequested():
return connectRequested(_that);case FeedMessageReceived():
return messageReceived(_that);case FeedStreamClosed():
return streamClosed(_that);case FeedWatchdogTicked():
return watchdogTicked(_that);case FeedNetworkStatusChanged():
return networkStatusChanged(_that);case FeedTokenRefreshRequested():
return tokenRefreshRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FeedStarted value)?  started,TResult? Function( FeedStopped value)?  stopped,TResult? Function( FeedConnectRequested value)?  connectRequested,TResult? Function( FeedMessageReceived value)?  messageReceived,TResult? Function( FeedStreamClosed value)?  streamClosed,TResult? Function( FeedWatchdogTicked value)?  watchdogTicked,TResult? Function( FeedNetworkStatusChanged value)?  networkStatusChanged,TResult? Function( FeedTokenRefreshRequested value)?  tokenRefreshRequested,}){
final _that = this;
switch (_that) {
case FeedStarted() when started != null:
return started(_that);case FeedStopped() when stopped != null:
return stopped(_that);case FeedConnectRequested() when connectRequested != null:
return connectRequested(_that);case FeedMessageReceived() when messageReceived != null:
return messageReceived(_that);case FeedStreamClosed() when streamClosed != null:
return streamClosed(_that);case FeedWatchdogTicked() when watchdogTicked != null:
return watchdogTicked(_that);case FeedNetworkStatusChanged() when networkStatusChanged != null:
return networkStatusChanged(_that);case FeedTokenRefreshRequested() when tokenRefreshRequested != null:
return tokenRefreshRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  stopped,TResult Function()?  connectRequested,TResult Function( SseMessage message)?  messageReceived,TResult Function( Object? error)?  streamClosed,TResult Function()?  watchdogTicked,TResult Function( NetworkStatus status)?  networkStatusChanged,TResult Function()?  tokenRefreshRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FeedStarted() when started != null:
return started();case FeedStopped() when stopped != null:
return stopped();case FeedConnectRequested() when connectRequested != null:
return connectRequested();case FeedMessageReceived() when messageReceived != null:
return messageReceived(_that.message);case FeedStreamClosed() when streamClosed != null:
return streamClosed(_that.error);case FeedWatchdogTicked() when watchdogTicked != null:
return watchdogTicked();case FeedNetworkStatusChanged() when networkStatusChanged != null:
return networkStatusChanged(_that.status);case FeedTokenRefreshRequested() when tokenRefreshRequested != null:
return tokenRefreshRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  stopped,required TResult Function()  connectRequested,required TResult Function( SseMessage message)  messageReceived,required TResult Function( Object? error)  streamClosed,required TResult Function()  watchdogTicked,required TResult Function( NetworkStatus status)  networkStatusChanged,required TResult Function()  tokenRefreshRequested,}) {final _that = this;
switch (_that) {
case FeedStarted():
return started();case FeedStopped():
return stopped();case FeedConnectRequested():
return connectRequested();case FeedMessageReceived():
return messageReceived(_that.message);case FeedStreamClosed():
return streamClosed(_that.error);case FeedWatchdogTicked():
return watchdogTicked();case FeedNetworkStatusChanged():
return networkStatusChanged(_that.status);case FeedTokenRefreshRequested():
return tokenRefreshRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  stopped,TResult? Function()?  connectRequested,TResult? Function( SseMessage message)?  messageReceived,TResult? Function( Object? error)?  streamClosed,TResult? Function()?  watchdogTicked,TResult? Function( NetworkStatus status)?  networkStatusChanged,TResult? Function()?  tokenRefreshRequested,}) {final _that = this;
switch (_that) {
case FeedStarted() when started != null:
return started();case FeedStopped() when stopped != null:
return stopped();case FeedConnectRequested() when connectRequested != null:
return connectRequested();case FeedMessageReceived() when messageReceived != null:
return messageReceived(_that.message);case FeedStreamClosed() when streamClosed != null:
return streamClosed(_that.error);case FeedWatchdogTicked() when watchdogTicked != null:
return watchdogTicked();case FeedNetworkStatusChanged() when networkStatusChanged != null:
return networkStatusChanged(_that.status);case FeedTokenRefreshRequested() when tokenRefreshRequested != null:
return tokenRefreshRequested();case _:
  return null;

}
}

}

/// @nodoc


class FeedStarted implements FeedEvent {
  const FeedStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FeedEvent.started()';
}


}




/// @nodoc


class FeedStopped implements FeedEvent {
  const FeedStopped();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedStopped);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FeedEvent.stopped()';
}


}




/// @nodoc


class FeedConnectRequested implements FeedEvent {
  const FeedConnectRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedConnectRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FeedEvent.connectRequested()';
}


}




/// @nodoc


class FeedMessageReceived implements FeedEvent {
  const FeedMessageReceived(this.message);
  

 final  SseMessage message;

/// Create a copy of FeedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedMessageReceivedCopyWith<FeedMessageReceived> get copyWith => _$FeedMessageReceivedCopyWithImpl<FeedMessageReceived>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedMessageReceived&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'FeedEvent.messageReceived(message: $message)';
}


}

/// @nodoc
abstract mixin class $FeedMessageReceivedCopyWith<$Res> implements $FeedEventCopyWith<$Res> {
  factory $FeedMessageReceivedCopyWith(FeedMessageReceived value, $Res Function(FeedMessageReceived) _then) = _$FeedMessageReceivedCopyWithImpl;
@useResult
$Res call({
 SseMessage message
});




}
/// @nodoc
class _$FeedMessageReceivedCopyWithImpl<$Res>
    implements $FeedMessageReceivedCopyWith<$Res> {
  _$FeedMessageReceivedCopyWithImpl(this._self, this._then);

  final FeedMessageReceived _self;
  final $Res Function(FeedMessageReceived) _then;

/// Create a copy of FeedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(FeedMessageReceived(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as SseMessage,
  ));
}


}

/// @nodoc


class FeedStreamClosed implements FeedEvent {
  const FeedStreamClosed({this.error});
  

 final  Object? error;

/// Create a copy of FeedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedStreamClosedCopyWith<FeedStreamClosed> get copyWith => _$FeedStreamClosedCopyWithImpl<FeedStreamClosed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedStreamClosed&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'FeedEvent.streamClosed(error: $error)';
}


}

/// @nodoc
abstract mixin class $FeedStreamClosedCopyWith<$Res> implements $FeedEventCopyWith<$Res> {
  factory $FeedStreamClosedCopyWith(FeedStreamClosed value, $Res Function(FeedStreamClosed) _then) = _$FeedStreamClosedCopyWithImpl;
@useResult
$Res call({
 Object? error
});




}
/// @nodoc
class _$FeedStreamClosedCopyWithImpl<$Res>
    implements $FeedStreamClosedCopyWith<$Res> {
  _$FeedStreamClosedCopyWithImpl(this._self, this._then);

  final FeedStreamClosed _self;
  final $Res Function(FeedStreamClosed) _then;

/// Create a copy of FeedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = freezed,}) {
  return _then(FeedStreamClosed(
error: freezed == error ? _self.error : error ,
  ));
}


}

/// @nodoc


class FeedWatchdogTicked implements FeedEvent {
  const FeedWatchdogTicked();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedWatchdogTicked);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FeedEvent.watchdogTicked()';
}


}




/// @nodoc


class FeedNetworkStatusChanged implements FeedEvent {
  const FeedNetworkStatusChanged(this.status);
  

 final  NetworkStatus status;

/// Create a copy of FeedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedNetworkStatusChangedCopyWith<FeedNetworkStatusChanged> get copyWith => _$FeedNetworkStatusChangedCopyWithImpl<FeedNetworkStatusChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedNetworkStatusChanged&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'FeedEvent.networkStatusChanged(status: $status)';
}


}

/// @nodoc
abstract mixin class $FeedNetworkStatusChangedCopyWith<$Res> implements $FeedEventCopyWith<$Res> {
  factory $FeedNetworkStatusChangedCopyWith(FeedNetworkStatusChanged value, $Res Function(FeedNetworkStatusChanged) _then) = _$FeedNetworkStatusChangedCopyWithImpl;
@useResult
$Res call({
 NetworkStatus status
});




}
/// @nodoc
class _$FeedNetworkStatusChangedCopyWithImpl<$Res>
    implements $FeedNetworkStatusChangedCopyWith<$Res> {
  _$FeedNetworkStatusChangedCopyWithImpl(this._self, this._then);

  final FeedNetworkStatusChanged _self;
  final $Res Function(FeedNetworkStatusChanged) _then;

/// Create a copy of FeedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = null,}) {
  return _then(FeedNetworkStatusChanged(
null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as NetworkStatus,
  ));
}


}

/// @nodoc


class FeedTokenRefreshRequested implements FeedEvent {
  const FeedTokenRefreshRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedTokenRefreshRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FeedEvent.tokenRefreshRequested()';
}


}




// dart format on
