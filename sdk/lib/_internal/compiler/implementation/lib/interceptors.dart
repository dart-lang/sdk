// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _interceptors;

import 'dart:collection';

part 'js_array.dart';
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
    checkNull(newLength); // TODO(ahe): This is not specified but co19 tests it.
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

compareTo(a, b) {
  if (checkNumbers(a, b)) {
    if (a < b) {
      return -1;
    } else if (a > b) {
      return 1;
    } else if (a == b) {
      if (a == 0) {
        bool aIsNegative = a.isNegative;
        bool bIsNegative = b.isNegative;
        if (aIsNegative == bIsNegative) return 0;
        if (aIsNegative) return -1;
        return 1;
      }
      return 0;
    } else if (a.isNaN) {
      if (b.isNaN) {
        return 0;
      }
      return 1;
    } else {
      return -1;
    }
  } else if (a is String) {
    if (b is !String) throw new ArgumentError(b);
    return JS('bool', r'# == #', a, b) ? 0
      : JS('bool', r'# < #', a, b) ? -1 : 1;
  } else {
    return UNINTERCEPTED(a.compareTo(b));
  }
}

get$isNegative(receiver) {
  if (receiver is num) {
    return (receiver == 0) ? (1 / receiver) < 0 : receiver < 0;
  } else {
    return UNINTERCEPTED(receiver.isNegative);
  }
}

get$isNaN(receiver) {
  if (receiver is num) {
    return JS('bool', r'isNaN(#)', receiver);
  } else {
    return UNINTERCEPTED(receiver.isNaN);
  }
}

remainder(a, b) {
  if (checkNumbers(a, b)) {
    return JS('num', r'# % #', a, b);
  } else {
    return UNINTERCEPTED(a.remainder(b));
  }
}

abs(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.abs());

  return JS('num', r'Math.abs(#)', receiver);
}

toInt(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.toInt());

  if (receiver.isNaN) throw new FormatException('NaN');

  if (receiver.isInfinite) throw new FormatException('Infinity');

  var truncated = receiver.truncate();
  return JS('bool', r'# == -0.0', truncated) ? 0 : truncated;
}

ceil(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.ceil());

  return JS('num', r'Math.ceil(#)', receiver);
}

floor(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.floor());

  return JS('num', r'Math.floor(#)', receiver);
}

get$isInfinite(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.isInfinite);

  return JS('bool', r'# == Infinity', receiver)
    || JS('bool', r'# == -Infinity', receiver);
}

round(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.round());

  if (JS('bool', r'# < 0', receiver)) {
    return JS('num', r'-Math.round(-#)', receiver);
  } else {
    return JS('num', r'Math.round(#)', receiver);
  }
}

toDouble(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.toDouble());

  return receiver;
}

truncate(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.truncate());

  return receiver < 0 ? receiver.ceil() : receiver.floor();
}

toStringAsFixed(receiver, fractionDigits) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toStringAsFixed(fractionDigits));
  }
  checkNum(fractionDigits);

  String result = JS('String', r'#.toFixed(#)', receiver, fractionDigits);
  if (receiver == 0 && receiver.isNegative) return "-$result";
  return result;
}

toStringAsExponential(receiver, fractionDigits) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toStringAsExponential(fractionDigits));
  }
  String result;
  if (fractionDigits != null) {
    checkNum(fractionDigits);
    result = JS('String', r'#.toExponential(#)', receiver, fractionDigits);
  } else {
    result = JS('String', r'#.toExponential()', receiver);
  }
  if (receiver == 0 && receiver.isNegative) return "-$result";
  return result;
}

toStringAsPrecision(receiver, fractionDigits) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toStringAsPrecision(fractionDigits));
  }
  checkNum(fractionDigits);

  String result = JS('String', r'#.toPrecision(#)',
                     receiver, fractionDigits);
  if (receiver == 0 && receiver.isNegative) return "-$result";
  return result;
}

toRadixString(receiver, radix) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toRadixString(radix));
  }
  checkNum(radix);
  if (radix < 2 || radix > 36) throw new ArgumentError(radix);
  return JS('String', r'#.toString(#)', receiver, radix);
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

get$isEven(receiver) {
  if (receiver is !int) return UNINTERCEPTED(receiver.isEven);
  return (receiver & 1) == 0;
}

get$isOdd(receiver) {
  if (receiver is !int) return UNINTERCEPTED(receiver.isOdd);
  return (receiver & 1) == 1;
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
