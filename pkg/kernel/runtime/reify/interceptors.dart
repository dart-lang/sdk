// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.reify.runtime.interceptors;

import 'types.dart' show ReifiedType;

/// Helper method that generates a [ReifiedType] corresponding to the literal
/// type [type].
///
/// Calls to this method are recognized in the transformation and replaced by
/// code that constructs the correct type.
ReifiedType reify(Type type) {
  throw "This method should never be called in translated code";
}

/// Marker interface to indicate that we can extract the runtime type using
/// a property getter.
abstract class HasRuntimeTypeGetter {
  ReifiedType get $type;
}

/// Interceptor to safely access the type of an object.
///
/// For native objects that do not have the `$type` field on them, the
/// interceptor directly returns the type, otherwise the value of the field is
/// returned.
ReifiedType type(dynamic o) {
  if (o == null) {
    return reify(Null);
  } else if (o is HasRuntimeTypeGetter) {
    return o.$type;
  } else if (o is bool) {
    return reify(bool);
  } else if (o is String) {
    return reify(String);
  } else if (o is int) {
    return reify(int);
  } else if (o is double) {
    return reify(double);
  } else if (o is Type) {
    return reify(Type);
  } else if (o is AbstractClassInstantiationError) {
    return reify(AbstractClassInstantiationError);
  } else if (o is NoSuchMethodError) {
    return reify(NoSuchMethodError);
  } else if (o is CyclicInitializationError) {
    return reify(CyclicInitializationError);
  } else if (o is UnsupportedError) {
    return reify(UnsupportedError);
  } else if (o is IntegerDivisionByZeroException) {
    return reify(IntegerDivisionByZeroException);
  } else if (o is RangeError) {
    return reify(RangeError);
  } else if (o is ArgumentError) {
    return reify(ArgumentError);
  }
  ReifiedType type = _type[o];
  if (type != null) {
    return type;
  }
  throw 'Unable to get runtime type of ${o.runtimeType}';
}

// This constructor call is not intercepted with [attachType] since the runtime
// library is currently never transformed.
final Expando _type = new Expando();

dynamic attachType(Object o, ReifiedType t) {
  _type[o] = t;
  return o;
}
