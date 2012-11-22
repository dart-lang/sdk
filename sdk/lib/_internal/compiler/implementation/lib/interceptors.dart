// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _interceptors;

import 'dart:collection';

part 'js_array.dart';
part 'js_number.dart';
part 'js_string.dart';

/**
 * The interceptor class for all non-primitive objects. All its
 * members are synthethized by the compiler's emitter.
 */
class ObjectInterceptor {
  const ObjectInterceptor();
}

/**
 * Get the interceptor for [object]. Called by the compiler when it needs
 * to emit a call to an intercepted method, that is a method that is
 * defined in an interceptor class.
 */
getInterceptor(object) {
  if (object is String) return stringInterceptor;
  if (isJsArray(object)) return arrayInterceptor;
  if (object is int) return intInterceptor;
  if (object is double) return doubleInterceptor;
  if (object is bool) return boolInterceptor;
  if (object == null) return nullInterceptor;
  if (JS('String', 'typeof #', object) == 'function') {
    return functionInterceptor;
  }
  return objectInterceptor;
}

final arrayInterceptor = const JSArray();
final boolInterceptor = const JSBool();
final doubleInterceptor = const JSDouble();
final intInterceptor = const JSInt();
final functionInterceptor = const JSFunction();
final nullInterceptor = const JSNull();
final numberInterceptor = const JSNumber();
final stringInterceptor = const JSString();
final objectInterceptor = const ObjectInterceptor();

/**
 * The interceptor class for tear-off static methods. Unlike
 * tear-off instance methods, tear-off static methods are just the JS
 * function, and methods inherited from Object must therefore be
 * intercepted.
 */
class JSFunction implements Function {
  const JSFunction();
  String toString() => 'Closure';
}

/**
 * The interceptor class for [bool].
 */
class JSBool implements bool {
  const JSBool();
  String toString() => JS('String', r'String(#)', this);

  // The values here are SMIs, co-prime and differ about half of the bit
  // positions, including the low bit, so they are different mod 2^k.
  int get hashCode => this ? (2 * 3 * 23 * 3761) : (269 * 811);

  Type get runtimeType => createRuntimeType('bool');
}

get$runtimeType(receiver) {
  if (receiver is int) {
    return int;
  } else if (receiver is String) {
    return String;
  } else if (receiver is double) {
    return double;
  } else if (receiver is bool) {
    return bool;
  } else if (receiver == null) {
    return createRuntimeType('Null');
  } else if (isJsArray(receiver)) {
    // Call getRuntimeTypeString to get the name including type arguments.
    return createRuntimeType(getRuntimeTypeString(receiver));
  } else {
    return UNINTERCEPTED(receiver.runtimeType);
  }
}

/**
 * The interceptor class for [Null].
 */
class JSNull implements Null {
  const JSNull();
  String toString() => 'null';
  int get hashCode => 0;
  Type get runtimeType => createRuntimeType('Null');
}
