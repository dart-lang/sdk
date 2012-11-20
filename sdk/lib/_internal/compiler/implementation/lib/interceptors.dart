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
  if (object is String) return const JSString();
  if (isJsArray(object)) return const JSArray();
  if (object is int) return const JSInt();
  if (object is double) return const JSDouble();
  if (object is bool) return const JSBool();
  if (object == null) return const JSNull();
  if (JS('String', 'typeof #', object) == 'function') return const JSFunction();
  return const ObjectInterceptor();
}

get$length(var receiver) {
  if (receiver is String || isJsArray(receiver)) {
    return JS('num', r'#.length', receiver);  // TODO(sra): Use 'int'?
  } else {
    return UNINTERCEPTED(receiver.length);
  }
}

set$length(receiver, newLength) {
  if (isJsArray(receiver)) {
    if (newLength is !int) throw new ArgumentError(newLength);
    if (newLength < 0) throw new RangeError.value(newLength);
    checkGrowable(receiver, 'set length');
    JS('void', r'#.length = #', receiver, newLength);
  } else {
    UNINTERCEPTED(receiver.length = newLength);
  }
  return newLength;
}

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
  int get hashCode => this ? 0x40377024 : 0xc18c0076;
  Type get runtimeType => createRuntimeType('bool');
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
