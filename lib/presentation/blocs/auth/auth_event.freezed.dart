// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent()';
}


}

/// @nodoc
class $AuthEventCopyWith<$Res>  {
$AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}


/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthBootstrapRequested value)?  bootstrapRequested,TResult Function( AuthCredentialsSubmitted value)?  credentialsSubmitted,TResult Function( AuthSessionRejected value)?  sessionRejected,TResult Function( AuthLogOutRequested value)?  logOutRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthBootstrapRequested() when bootstrapRequested != null:
return bootstrapRequested(_that);case AuthCredentialsSubmitted() when credentialsSubmitted != null:
return credentialsSubmitted(_that);case AuthSessionRejected() when sessionRejected != null:
return sessionRejected(_that);case AuthLogOutRequested() when logOutRequested != null:
return logOutRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthBootstrapRequested value)  bootstrapRequested,required TResult Function( AuthCredentialsSubmitted value)  credentialsSubmitted,required TResult Function( AuthSessionRejected value)  sessionRejected,required TResult Function( AuthLogOutRequested value)  logOutRequested,}){
final _that = this;
switch (_that) {
case AuthBootstrapRequested():
return bootstrapRequested(_that);case AuthCredentialsSubmitted():
return credentialsSubmitted(_that);case AuthSessionRejected():
return sessionRejected(_that);case AuthLogOutRequested():
return logOutRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthBootstrapRequested value)?  bootstrapRequested,TResult? Function( AuthCredentialsSubmitted value)?  credentialsSubmitted,TResult? Function( AuthSessionRejected value)?  sessionRejected,TResult? Function( AuthLogOutRequested value)?  logOutRequested,}){
final _that = this;
switch (_that) {
case AuthBootstrapRequested() when bootstrapRequested != null:
return bootstrapRequested(_that);case AuthCredentialsSubmitted() when credentialsSubmitted != null:
return credentialsSubmitted(_that);case AuthSessionRejected() when sessionRejected != null:
return sessionRejected(_that);case AuthLogOutRequested() when logOutRequested != null:
return logOutRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  bootstrapRequested,TResult Function( String username,  String password)?  credentialsSubmitted,TResult Function()?  sessionRejected,TResult Function()?  logOutRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthBootstrapRequested() when bootstrapRequested != null:
return bootstrapRequested();case AuthCredentialsSubmitted() when credentialsSubmitted != null:
return credentialsSubmitted(_that.username,_that.password);case AuthSessionRejected() when sessionRejected != null:
return sessionRejected();case AuthLogOutRequested() when logOutRequested != null:
return logOutRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  bootstrapRequested,required TResult Function( String username,  String password)  credentialsSubmitted,required TResult Function()  sessionRejected,required TResult Function()  logOutRequested,}) {final _that = this;
switch (_that) {
case AuthBootstrapRequested():
return bootstrapRequested();case AuthCredentialsSubmitted():
return credentialsSubmitted(_that.username,_that.password);case AuthSessionRejected():
return sessionRejected();case AuthLogOutRequested():
return logOutRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  bootstrapRequested,TResult? Function( String username,  String password)?  credentialsSubmitted,TResult? Function()?  sessionRejected,TResult? Function()?  logOutRequested,}) {final _that = this;
switch (_that) {
case AuthBootstrapRequested() when bootstrapRequested != null:
return bootstrapRequested();case AuthCredentialsSubmitted() when credentialsSubmitted != null:
return credentialsSubmitted(_that.username,_that.password);case AuthSessionRejected() when sessionRejected != null:
return sessionRejected();case AuthLogOutRequested() when logOutRequested != null:
return logOutRequested();case _:
  return null;

}
}

}

/// @nodoc


class AuthBootstrapRequested implements AuthEvent {
  const AuthBootstrapRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthBootstrapRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.bootstrapRequested()';
}


}




/// @nodoc


class AuthCredentialsSubmitted implements AuthEvent {
  const AuthCredentialsSubmitted({required this.username, required this.password});
  

 final  String username;
 final  String password;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthCredentialsSubmittedCopyWith<AuthCredentialsSubmitted> get copyWith => _$AuthCredentialsSubmittedCopyWithImpl<AuthCredentialsSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthCredentialsSubmitted&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,username,password);

@override
String toString() {
  return 'AuthEvent.credentialsSubmitted(username: $username, password: $password)';
}


}

/// @nodoc
abstract mixin class $AuthCredentialsSubmittedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthCredentialsSubmittedCopyWith(AuthCredentialsSubmitted value, $Res Function(AuthCredentialsSubmitted) _then) = _$AuthCredentialsSubmittedCopyWithImpl;
@useResult
$Res call({
 String username, String password
});




}
/// @nodoc
class _$AuthCredentialsSubmittedCopyWithImpl<$Res>
    implements $AuthCredentialsSubmittedCopyWith<$Res> {
  _$AuthCredentialsSubmittedCopyWithImpl(this._self, this._then);

  final AuthCredentialsSubmitted _self;
  final $Res Function(AuthCredentialsSubmitted) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? username = null,Object? password = null,}) {
  return _then(AuthCredentialsSubmitted(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthSessionRejected implements AuthEvent {
  const AuthSessionRejected();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSessionRejected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.sessionRejected()';
}


}




/// @nodoc


class AuthLogOutRequested implements AuthEvent {
  const AuthLogOutRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthLogOutRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.logOutRequested()';
}


}




// dart format on
