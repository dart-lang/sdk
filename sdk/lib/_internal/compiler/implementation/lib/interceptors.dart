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

iterator(receiver) {
  if (isJsArray(receiver)) {
    return new ListIterator(receiver);
  }
  return UNINTERCEPTED(receiver.iterator());
}

toString(var value) {
  if (JS('bool', r'typeof # == "object" && # != null', value, value)) {
    if (isJsArray(value)) {
      return Collections.collectionToString(value);
    } else {
      return UNINTERCEPTED(value.toString());
    }
  }
  if (JS('bool', r'# === 0 && (1 / #) < 0', value, value)) {
    return '-0.0';
  }
  if (value == null) return 'null';
  if (JS('bool', r'typeof # == "function"', value)) {
    return 'Closure';
  }
  return JS('String', r'String(#)', value);
}

/**
 * This is the [Jenkins hash function][1] but using masking to keep
 * values in SMI range.
 *
 * [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
 */
get$hashCode(receiver) {
  // TODO(ahe): This method shouldn't have to use JS. Update when our
  // optimizations are smarter.
  if (receiver == null) return 0;
  if (receiver is num) return receiver & 0x1FFFFFFF;
  if (receiver is bool) return receiver ? 0x40377024 : 0xc18c0076;
  if (isJsArray(receiver)) return Primitives.objectHashCode(receiver);
  if (receiver is !String) return UNINTERCEPTED(receiver.hashCode);
  int hash = 0;
  int length = receiver.length;
  for (int i = 0; i < length; i++) {
    hash = 0x1fffffff & (hash + JS('int', r'#.charCodeAt(#)', receiver, i));
    hash = 0x1fffffff & (hash + (0x0007ffff & hash) << 10);
    hash = JS('int', '# ^ (# >> 6)', hash, hash);
  }
  hash = 0x1fffffff & (hash + (0x03ffffff & hash) <<  3);
  hash = JS('int', '# ^ (# >> 11)', hash, hash);
  return 0x1fffffff & (hash + (0x00003fff & hash) << 15);
}

get$runtimeType(receiver) {
  if (receiver is int) {
    return createRuntimeType('int');
  } else if (receiver is String) {
    return createRuntimeType('String');
  } else if (receiver is double) {
    return createRuntimeType('double');
  } else if (receiver is bool) {
    return createRuntimeType('bool');
  } else if (receiver == null) {
    return createRuntimeType('Null');
  } else if (isJsArray(receiver)) {
    return createRuntimeType('List');
  } else {
    return UNINTERCEPTED(receiver.runtimeType);
  }
}

// TODO(lrn): These getters should be generated automatically for all
// intercepted methods.
get$toString(receiver) => () => toString(receiver);
