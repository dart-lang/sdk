// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('dart:_js_helper');

#import('coreimpl.dart');

#source('constant_map.dart');
#source('native_helper.dart');
#source('regexp_helper.dart');
#source('string_helper.dart');

// Performance critical helper methods.
add(var a, var b) => (a is num && b is num)
    ? JS('num', @'# + #', a, b)
    : add$slow(a, b);

sub(var a, var b) => (a is num && b is num)
    ? JS('num', @'# - #', a, b)
    : sub$slow(a, b);

div(var a, var b) => (a is num && b is num)
    ? JS('num', @'# / #', a, b)
    : div$slow(a, b);

mul(var a, var b) => (a is num && b is num)
    ? JS('num', @'# * #', a, b)
    : mul$slow(a, b);

gt(var a, var b) => (a is num && b is num)
    ? JS('bool', @'# > #', a, b)
    : gt$slow(a, b);

ge(var a, var b) => (a is num && b is num)
    ? JS('bool', @'# >= #', a, b)
    : ge$slow(a, b);

lt(var a, var b) => (a is num && b is num)
    ? JS('bool', @'# < #', a, b)
    : lt$slow(a, b);

le(var a, var b) => (a is num && b is num)
    ? JS('bool', @'# <= #', a, b)
    : le$slow(a, b);

gtB(var a, var b) => (a is num && b is num)
    ? JS('bool', @'# > #', a, b)
    : gt$slow(a, b) === true;

geB(var a, var b) => (a is num && b is num)
    ? JS('bool', @'# >= #', a, b)
    : ge$slow(a, b) === true;

ltB(var a, var b) => (a is num && b is num)
    ? JS('bool', @'# < #', a, b)
    : lt$slow(a, b) === true;

leB(var a, var b) => (a is num && b is num)
    ? JS('bool', @'# <= #', a, b)
    : le$slow(a, b) === true;

index(var a, var index) {
  // The type test may cause a NullPointerException to be thrown but
  // that matches the specification of what the indexing operator is
  // supposed to do.
  bool isJsArrayOrString = JS('bool',
      @'typeof # == "string" || #.constructor === Array',
      a, a);
  if (isJsArrayOrString) {
    var key = JS('int', '# >>> 0', index);
    if (key === index && key < JS('int', @'#.length', a)) {
      return JS('var', @'#[#]', a, key);
    }
  }
  return index$slow(a, index);
}

indexSet(var a, var index, var value) {
  // The type test may cause a NullPointerException to be thrown but
  // that matches the specification of what the indexing operator is
  // supposed to do.
  bool isMutableJsArray = JS('bool',
      @'#.constructor === Array && !#.immutable$list',
      a, a);
  if (isMutableJsArray) {
    var key = JS('int', '# >>> 0', index);
    if (key === index && key < JS('int', @'#.length', a)) {
      JS('void', @'#[#] = #', a, key, value);
      return;
    }
  }
  indexSet$slow(a, index, value);
}

/**
 * Returns true if both arguments are numbers.
 *
 * If only the first argument is a number, an
 * [IllegalArgumentException] with the other argument is thrown.
 */
bool checkNumbers(var a, var b) {
  if (a is num) {
    if (b is num) {
      return true;
    } else {
      checkNull(b);
      throw new IllegalArgumentException(b);
    }
  }
  return false;
}

bool isJsArray(var value) {
  return value !== null && JS('bool', @'#.constructor === Array', value);
}

add$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# + #', a, b);
  }
  return UNINTERCEPTED(a + b);
}

div$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# / #', a, b);
  }
  return UNINTERCEPTED(a / b);
}

mul$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# * #', a, b);
  }
  return UNINTERCEPTED(a * b);
}

sub$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# - #', a, b);
  }
  return UNINTERCEPTED(a - b);
}

mod(var a, var b) {
  if (checkNumbers(a, b)) {
    // Euclidean Modulo.
    int result = JS('num', @'# % #', a, b);
    if (result == 0) return 0;  // Make sure we don't return -0.0.
    if (result > 0) return result;
    if (JS('num', '#', b) < 0) {
      return result - JS('num', '#', b);
    } else {
      return result + JS('num', '#', b);
    }
  }
  return UNINTERCEPTED(a % b);
}

tdiv(var a, var b) {
  if (checkNumbers(a, b)) {
    return (JS('num', @'# / #', a, b)).truncate();
  }
  return UNINTERCEPTED(a ~/ b);
}

eq(var a, var b) {
  if (JS('bool', @'# == null', a)) return JS('bool', @'# == null', b);
  if (JS('bool', @'# == null', b)) return false;
  if (JS('bool', @'typeof # === "object"', a)) {
    if (JS_HAS_EQUALS(a)) {
      return UNINTERCEPTED(a == b);
    }
  }
  // TODO(lrn): is NaN === NaN ? Is -0.0 === 0.0 ?
  return JS('bool', @'# === #', a, b);
}

bool eqB(var a, var b) {
  if (JS('bool', @'# == null', a)) return JS('bool', @'# == null', b);
  if (JS('bool', @'# == null', b)) return false;
  if (JS('bool', @'typeof # === "object"', a)) {
    if (JS_HAS_EQUALS(a)) {
      return UNINTERCEPTED(a == b) === true;
    }
  }
  // TODO(lrn): is NaN === NaN ? Is -0.0 === 0.0 ?
  return JS('bool', @'# === #', a, b);
}

eqq(var a, var b) {
  return JS('bool', @'# === #', a, b);
}

gt$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# > #', a, b);
  }
  return UNINTERCEPTED(a > b);
}

ge$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# >= #', a, b);
  }
  return UNINTERCEPTED(a >= b);
}

lt$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# < #', a, b);
  }
  return UNINTERCEPTED(a < b);
}

le$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# <= #', a, b);
  }
  return UNINTERCEPTED(a <= b);
}

shl(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    if (JS('num', '#', b) < 0) throw new IllegalArgumentException(b);
    // JavaScript only looks at the last 5 bits of the shift-amount. Shifting
    // by 33 is hence equivalent to a shift by 1.
    if (JS('bool', @'# > 31', b)) return 0;
    return JS('num', @'(# << #) >>> 0', a, b);
  }
  return UNINTERCEPTED(a << b);
}

shr(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    if (JS('num', '#', b) < 0) throw new IllegalArgumentException(b);
    if (JS('num', '#', a) > 0) {
      // JavaScript only looks at the last 5 bits of the shift-amount. In JS
      // shifting by 33 is hence equivalent to a shift by 1. Shortcut the
      // computation when that happens.
      if (JS('bool', @'# > 31', b)) return 0;
      // Given that 'a' is positive we must not use '>>'. Otherwise a number
      // that has the 31st bit set would be treated as negative and shift in
      // ones.
      return JS('num', @'# >>> #', a, b);
    }
    // For negative numbers we just clamp the shift-by amount. 'a' could be
    // negative but not have its 31st bit set. The ">>" would then shift in
    // 0s instead of 1s. Therefore we cannot simply return 0xFFFFFFFF.
    if (JS('num', '#', b) > 31) b = 31;
    return JS('num', @'(# >> #) >>> 0', a, b);
  }
  return UNINTERCEPTED(a >> b);
}

and(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', @'(# & #) >>> 0', a, b);
  }
  return UNINTERCEPTED(a & b);
}

or(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', @'(# | #) >>> 0', a, b);
  }
  return UNINTERCEPTED(a | b);
}

xor(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', @'(# ^ #) >>> 0', a, b);
  }
  return UNINTERCEPTED(a ^ b);
}

not(var a) {
  if (JS('bool', @'typeof # === "number"', a)) {
    return JS('num', @'(~#) >>> 0', a);
  }
  return UNINTERCEPTED(~a);
}

neg(var a) {
  if (JS('bool', @'typeof # === "number"', a)) return JS('num', @'-#', a);
  return UNINTERCEPTED(-a);
}

index$slow(var a, var index) {
  if (a is String || isJsArray(a)) {
    if (index is !int) {
      if (index is !num) throw new IllegalArgumentException(index);
      if (index.truncate() !== index) throw new IllegalArgumentException(index);
    }
    if (index < 0 || index >= a.length) {
      throw new IndexOutOfRangeException(index);
    }
    return JS('Object', @'#[#]', a, index);
  }
  return UNINTERCEPTED(a[index]);
}

void indexSet$slow(var a, var index, var value) {
  if (isJsArray(a)) {
    if (index is !int) {
      throw new IllegalArgumentException(index);
    }
    if (index < 0 || index >= a.length) {
      throw new IndexOutOfRangeException(index);
    }
    checkMutable(a, 'indexed set');
    JS('Object', @'#[#] = #', a, index, value);
    return;
  }
  UNINTERCEPTED(a[index] = value);
}

checkMutable(list, reason) {
  if (JS('bool', @'!!(#.immutable$list)', list)) {
    throw new UnsupportedOperationException(reason);
  }
}

checkGrowable(list, reason) {
  if (JS('bool', @'!!(#.fixed$length)', list)) {
    throw new UnsupportedOperationException(reason);
  }
}

String S(value) {
  var res = value.toString();
  if (res is !String) throw new IllegalArgumentException(value);
  return res;
}

class ListIterator<T> implements Iterator<T> {
  int i;
  List<T> list;
  ListIterator(List<T> this.list) : i = 0;
  bool hasNext() => i < JS('int', @'#.length', list);
  T next() {
    if (!hasNext()) throw new NoMoreElementsException();
    var value = JS('Object', @'#[#]', list, i);
    i += 1;
    return value;
  }
}

class Primitives {
  /**
   * This is the low-level method that is used to implement
   * [print]. It is possible to override this function from JavaScript
   * by defining a function in JavaScript called "dartPrint".
   */
  static void printString(String string) {
    var hasDartPrint = JS('bool', @'typeof dartPrint == "function"');
    if (hasDartPrint) {
      JS('void', @'dartPrint(#)', string);
      return;
    }

    var hasConsole = JS('bool', @'typeof console == "object"');
    if (hasConsole) {
      JS('void', @'console.log(#)', string);
      return;
    }

    var hasWrite = JS('bool', @'typeof write == "function"');
    if (hasWrite) {
      JS('void', @'write(#)', string);
      JS('void', @'write("\n")');
    }
  }

  /** [: @"$".charCodeAt(0) :] */
  static const int DOLLAR_CHAR_VALUE = 36;

  static String objectTypeName(Object object) {
    String name = constructorNameFallback(object);
    if (name == 'Object') {
      // Try to decompile the constructor by turning it into a string
      // and get the name out of that. If the decompiled name is a
      // string, we use that instead of the very generic 'Object'.
      var decompiled = JS('var', @'#.match(/^\s*function\s*(\S*)\s*\(/)[1]',
                          JS('var', @'String(#.constructor)', object));
      if (decompiled is String) name = decompiled;
    }
    // TODO(kasperl): If the namer gave us a fresh global name, we may
    // want to remove the numeric suffix that makes it unique too.
    if (name.charCodeAt(0) === DOLLAR_CHAR_VALUE) name = name.substring(1);
    return name;
  }

  static String objectToString(Object object) {
    String name = objectTypeName(object);
    return "Instance of '$name'";
  }

  static List newList(length) {
    if (length === null) return JS('Object', @'new Array()');
    if ((length is !int) || (length < 0)) {
      throw new IllegalArgumentException(length);
    }
    var result = JS('Object', @'new Array(#)', length);
    JS('void', @'#.fixed$length = #', result, true);
    return result;
  }

  static num dateNow() => JS('num', @'Date.now()');

  static String stringFromCharCodes(charCodes) {
    for (var i in charCodes) {
      if (i is !int) throw new IllegalArgumentException(i);
    }
    return JS('String', @'String.fromCharCode.apply(#, #)', null, charCodes);
  }

  static String getTimeZoneName(receiver) {
    // When calling toString on a Date it will emit the timezone in parenthesis.
    // Example: "Wed May 16 2012 21:13:00 GMT+0200 (CEST)".
    // We extract this name using a regexp.
    var d = lazyAsJsDate(receiver);
    return JS('String', @'/\((.*)\)/.exec(#.toString())[1]', d);
  }

  static int getTimeZoneOffsetInMinutes(receiver) {
    // Note that JS and Dart disagree on the sign of the offset.
    return -JS('int', @'#.getTimezoneOffset()', lazyAsJsDate(receiver));
  }

  static valueFromDecomposedDate(years, month, day, hours, minutes, seconds,
                                 milliseconds, isUtc) {
    final int MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;
    checkInt(years);
    checkInt(month);
    checkInt(day);
    checkInt(hours);
    checkInt(minutes);
    checkInt(seconds);
    checkInt(milliseconds);
    checkBool(isUtc);
    var jsMonth = month - 1;
    var value;
    if (isUtc) {
      value = JS('num', @'Date.UTC(#, #, #, #, #, #, #)',
                 years, jsMonth, day, hours, minutes, seconds, milliseconds);
    } else {
      value = JS('num', @'new Date(#, #, #, #, #, #, #).valueOf()',
                 years, jsMonth, day, hours, minutes, seconds, milliseconds);
    }
    if (value.isNaN() ||
        value < -MAX_MILLISECONDS_SINCE_EPOCH ||
        value > MAX_MILLISECONDS_SINCE_EPOCH) {
      throw new IllegalArgumentException();
    }
    if (years <= 0 || years < 100) return patchUpY2K(value, years, isUtc);
    return value;
  }

  static patchUpY2K(value, years, isUtc) {
    var date = JS('Object', @'new Date(#)', value);
    if (isUtc) {
      JS('num', @'#.setUTCFullYear(#)', date, years);
    } else {
      JS('num', @'#.setFullYear(#)', date, years);
    }
    return JS('num', @'#.valueOf()', date);
  }

  // Lazily keep a JS Date stored in the JS object.
  static lazyAsJsDate(receiver) {
    if (JS('bool', @'#.date === (void 0)', receiver)) {
      JS('void', @'#.date = new Date(#)', receiver,
         receiver.millisecondsSinceEpoch);
    }
    return JS('Date', @'#.date', receiver);
  }

  static getYear(receiver) {
    return (receiver.isUtc)
      ? JS('int', @'#.getUTCFullYear()', lazyAsJsDate(receiver))
      : JS('int', @'#.getFullYear()', lazyAsJsDate(receiver));
  }

  static getMonth(receiver) {
    return (receiver.isUtc)
      ? JS('int', @'#.getUTCMonth()', lazyAsJsDate(receiver)) + 1
      : JS('int', @'#.getMonth()', lazyAsJsDate(receiver)) + 1;
  }

  static getDay(receiver) {
    return (receiver.isUtc)
      ? JS('int', @'#.getUTCDate()', lazyAsJsDate(receiver))
      : JS('int', @'#.getDate()', lazyAsJsDate(receiver));
  }

  static getHours(receiver) {
    return (receiver.isUtc)
      ? JS('int', @'#.getUTCHours()', lazyAsJsDate(receiver))
      : JS('int', @'#.getHours()', lazyAsJsDate(receiver));
  }

  static getMinutes(receiver) {
    return (receiver.isUtc)
      ? JS('int', @'#.getUTCMinutes()', lazyAsJsDate(receiver))
      : JS('int', @'#.getMinutes()', lazyAsJsDate(receiver));
  }

  static getSeconds(receiver) {
    return (receiver.isUtc)
      ? JS('int', @'#.getUTCSeconds()', lazyAsJsDate(receiver))
      : JS('int', @'#.getSeconds()', lazyAsJsDate(receiver));
  }

  static getMilliseconds(receiver) {
    return (receiver.isUtc)
      ? JS('int', @'#.getUTCMilliseconds()', lazyAsJsDate(receiver))
      : JS('int', @'#.getMilliseconds()', lazyAsJsDate(receiver));
  }

  static getWeekday(receiver) {
    int weekday = (receiver.isUtc)
      ? JS('int', @'#.getUTCDay()', lazyAsJsDate(receiver))
      : JS('int', @'#.getDay()', lazyAsJsDate(receiver));
    // Adjust by one because JS weeks start on Sunday.
    return (weekday + 6) % 7 + 1;
  }

  static valueFromDateString(str) {
    checkNull(str);
    if (str is !String) throw new IllegalArgumentException(str);
    var value = JS('num', @'Date.parse(#)', str);
    if (value.isNaN()) throw new IllegalArgumentException(str);
    return value;
  }

  static getProperty(object, key) {
    checkNull(object);
    if (object is bool || object is num || object is String) {
      throw new IllegalArgumentException(object);
    }
    return JS('var', '#[#]', object, key);
  }

  static void setProperty(object, key, value) {
    checkNull(object);
    if (object is bool || object is num || object is String) {
      throw new IllegalArgumentException(object);
    }
    JS('void', '#[#] = #', object, key, value);
  }
}

/**
 * Called by generated code to throw an illegal-argument exception,
 * for example, if a non-integer index is given to an optimized
 * indexed access.
 */
iae(argument) {
  throw new IllegalArgumentException(argument);
}

/**
 * Called by generated code to throw an index-out-of-range exception,
 * for example, if a bounds check fails in an optimized indexed
 * access.
 */
ioore(index) {
  throw new IndexOutOfRangeException(index);
}

listInsertRange(receiver, start, length, initialValue) {
  if (length === 0) {
    return;
  }
  checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
  if (length is !int) throw new IllegalArgumentException(length);
  if (length < 0) throw new IllegalArgumentException(length);
  if (start is !int) throw new IllegalArgumentException(start);

  var receiverLength = JS('num', @'#.length', receiver);
  if (start < 0 || start > receiverLength) {
    throw new IndexOutOfRangeException(start);
  }
  receiver.length = receiverLength + length;
  Arrays.copy(receiver,
              start,
              receiver,
              start + length,
              receiverLength - start);
  if (initialValue !== null) {
    for (int i = start; i < start + length; i++) {
      receiver[i] = initialValue;
    }
  }
  receiver.length = receiverLength + length;
}

stringLastIndexOfUnchecked(receiver, element, start)
  => JS('int', @'#.lastIndexOf(#, #)', receiver, element, start);


checkNull(object) {
  if (object === null) throw new NullPointerException();
  return object;
}

checkNum(value) {
  if (value is !num) {
    checkNull(value);
    throw new IllegalArgumentException(value);
  }
  return value;
}

checkInt(value) {
  if (value is !int) {
    checkNull(value);
    throw new IllegalArgumentException(value);
  }
  return value;
}

checkBool(value) {
  if (value is !bool) {
    checkNull(value);
    throw new IllegalArgumentException(value);
  }
  return value;
}

checkString(value) {
  if (value is !String) {
    checkNull(value);
    throw new IllegalArgumentException(value);
  }
  return value;
}

substringUnchecked(receiver, startIndex, endIndex)
  => JS('String', @'#.substring(#, #)', receiver, startIndex, endIndex);

class MathNatives {
  static int parseInt(str) {
    checkString(str);
    if (!JS('bool',
            @'/^\s*[+-]?(?:0[xX][abcdefABCDEF0-9]+|\d+)\s*$/.test(#)',
            str)) {
      throw new FormatException(str);
    }
    var trimmed = str.trim();
    var base = 10;;
    if ((trimmed.length > 2 && (trimmed[1] == 'x' || trimmed[1] == 'X')) ||
        (trimmed.length > 3 && (trimmed[2] == 'x' || trimmed[2] == 'X'))) {
      base = 16;
    }
    var ret = JS('num', @'parseInt(#, #)', trimmed, base);
    if (ret.isNaN()) throw new FormatException(str);
    return ret;
  }

  static double parseDouble(String str) {
    checkString(str);
    var ret = JS('num', @'parseFloat(#)', str);
    if (ret == 0 && (str.startsWith("0x") || str.startsWith("0X"))) {
      // TODO(ahe): This is unspecified, but tested by co19.
      ret = JS('num', @'parseInt(#)', str);
    }
    if (ret.isNaN() && str != 'NaN' && str != '-NaN') {
      throw new FormatException(str);
    }
    return ret;
  }

  static double sqrt(num value)
    => JS('double', @'Math.sqrt(#)', checkNum(value));

  static double sin(num value)
    => JS('double', @'Math.sin(#)', checkNum(value));

  static double cos(num value)
    => JS('double', @'Math.cos(#)', checkNum(value));

  static double tan(num value)
    => JS('double', @'Math.tan(#)', checkNum(value));

  static double acos(num value)
    => JS('double', @'Math.acos(#)', checkNum(value));

  static double asin(num value)
    => JS('double', @'Math.asin(#)', checkNum(value));

  static double atan(num value)
    => JS('double', @'Math.atan(#)', checkNum(value));

  static double atan2(num a, num b)
    => JS('double', @'Math.atan2(#, #)', checkNum(a), checkNum(b));

  static double exp(num value)
    => JS('double', @'Math.exp(#)', checkNum(value));

  static double log(num value)
    => JS('double', @'Math.log(#)', checkNum(value));

  static num pow(num value, num exponent) {
    checkNum(value);
    checkNum(exponent);
    return JS('num', @'Math.pow(#, #)', value, exponent);
  }

  static double random() => JS('double', @'Math.random()');
}

/**
 * Throws the given Dart object as an exception by wrapping it in a
 * proper JavaScript error object and then throwing that. That gives
 * us a reasonable stack trace on most JavaScript implementations. The
 * code in [unwrapException] deals with getting the original Dart
 * object out of the wrapper again.
 */
$throw(ex) {
  if (ex === null) ex = const NullPointerException();
  var jsError = JS('Object', @'new Error()');
  JS('void', @'#.name = #', jsError, ex);
  JS('void', @'#.description = #', jsError, ex);
  JS('void', @'#.dartException = #', jsError, ex);
  JS('void', @'#.toString = #', jsError,
     DART_CLOSURE_TO_JS(toStringWrapper));
  JS('void', @'throw #', jsError);
}

/**
 * This method is installed as JavaScript toString method on exception
 * objects in [$throw]. So JavaScript 'this' binds to an instance of
 * JavaScript Error to which we have added a property 'dartException'
 * which holds a Dart object.
 */
toStringWrapper() => JS('Object', @'this.dartException').toString();

makeLiteralListConst(list) {
  JS('bool', @'#.immutable$list = #', list, true);
  JS('bool', @'#.fixed$length = #', list, true);
  return list;
}

throwRuntimeError(message) {
  throw new RuntimeError(message);
}

/**
 * Called from catch blocks in generated code to extract the Dart
 * exception from the thrown value. The thrown value may have been
 * created by [$throw] or it may be a 'native' JS exception.
 *
 * Some native exceptions are mapped to new Dart instances, others are
 * returned unmodified.
 */
unwrapException(ex) {
  // Note that we are checking if the object has the property. If it
  // has, it could be set to null if the thrown value is null.
  if (JS('bool', @'"dartException" in #', ex)) {
    return JS('Object', @'#.dartException', ex);
  }

  // Grab hold of the exception message. This field is available on
  // all supported browsers.
  var message = JS('var', @'#.message', ex);

  if (JS('bool', @'# instanceof TypeError', ex)) {
    // The type and arguments fields are Chrome specific but they
    // allow us to get very detailed information about what kind of
    // exception occurred.
    var type = JS('var', @'#.type', ex);
    var name = JS('var', @'#.arguments ? #.arguments[0] : ""', ex, ex);
    if (type == 'property_not_function' ||
        type == 'called_non_callable' ||
        type == 'non_object_property_call' ||
        type == 'non_object_property_load') {
      if (name is String && name.startsWith(@'call$')) {
        return new ObjectNotClosureException();
      } else {
        return new NullPointerException();
      }
    } else if (type == 'undefined_method') {
      if (name is String && name.startsWith(@'call$')) {
        return new ObjectNotClosureException();
      } else {
        return new NoSuchMethodException('', name, []);
      }
    }

    var ieErrorCode = JS('int', '#.number & 0xffff', ex);
    var ieFacilityNumber = JS('int', '#.number>>16 & 0x1FFF', ex);
    // If we cannot use [type] to determine what kind of exception
    // we're dealing with we fall back on looking at the exception
    // message if it is available and a string.
    if (message is String) {
      if (message.endsWith('is null') ||
          message.endsWith('is undefined') ||
          message.endsWith('is null or undefined')) {
        return new NullPointerException();
      } else if (message.contains(' is not a function') ||
                 (ieErrorCode == 438 && ieFacilityNumber == 10)) {
        // Examples:
        //  x.foo is not a function
        //  'undefined' is not a function (evaluating 'x.foo(1,2,3)')
        // Object doesn't support property or method 'foo' which sets the error 
        // code 438 in IE.
        // TODO(kasperl): Compute the right name if possible.
        return new NoSuchMethodException('', '<unknown>', []);
      }
    }

    // If we cannot determine what kind of error this is, we fall back
    // to reporting this as a generic exception. It's probably better
    // than nothing.
    return new Exception(message is String ? message : '');
  }

  if (JS('bool', @'# instanceof RangeError', ex)) {
    if (message is String && message.contains('call stack')) {
      return new StackOverflowException();
    }

    // In general, a RangeError is thrown when trying to pass a number
    // as an argument to a function that does not allow a range that
    // includes that number.
    return new IllegalArgumentException();
  }

  // Check for the Firefox specific stack overflow signal.
  if (JS('bool',
         @"typeof InternalError == 'function' && # instanceof InternalError",
         ex)) {
    if (message is String && message == 'too much recursion') {
      return new StackOverflowException();
    }
  }

  // Just return the exception. We should not wrap it because in case
  // the exception comes from the DOM, it is a JavaScript
  // object backed by a native Dart class.
  return ex;
}

/**
 * Called by generated code to fetch the stack trace from an
 * exception.
 */
StackTrace getTraceFromException(exception) {
  return new StackTrace(JS("var", @"#.stack", exception));
}

class StackTrace {
  var stack;
  StackTrace(this.stack);
  String toString() => stack != null ? stack : '';
}


/**
 * Called by generated code to build a map literal. [keyValuePairs] is
 * a list of key, value, key, value, ..., etc.
 */
makeLiteralMap(List keyValuePairs) {
  Iterator iterator = keyValuePairs.iterator();
  Map result = new LinkedHashMap();
  while (iterator.hasNext()) {
    String key = iterator.next();
    var value = iterator.next();
    result[key] = value;
  }
  return result;
}

invokeClosure(Function closure,
              var isolate,
              int numberOfArguments,
              var arg1,
              var arg2) {
  if (numberOfArguments == 0) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure());
  } else if (numberOfArguments == 1) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1));
  } else if (numberOfArguments == 2) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1, arg2));
  } else {
    throw new Exception(
        'Unsupported number of arguments for wrapped closure');
  }
}

/**
 * Called by generated code to convert a Dart closure to a JS
 * closure when the Dart closure is passed to the DOM.
 */
convertDartClosureToJS(closure, int arity) {
  if (closure === null) return null;
  var function = JS('var', @'#.$identity', closure);
  if (JS('bool', @'!!#', function)) return function;

  function = JS("var", @"""function() {
    return #(#, #, #, arguments[0], arguments[1]);
  }""",
  DART_CLOSURE_TO_JS(invokeClosure),
  closure,
  JS_CURRENT_ISOLATE(),
  arity);

  JS('void', @'#.$identity = #', closure, function);
  return function;
}

/**
 * Super class for Dart closures.
 */
class Closure implements Function {
  String toString() => "Closure";
}

bool jsHasOwnProperty(var jsObject, String property) {
  return JS('bool', @'#.hasOwnProperty(#)', jsObject, property);
}

jsPropertyAccess(var jsObject, String property) {
  return JS('var', @'#[#]', jsObject, property);
}

/**
 * Called at the end of unaborted switch cases to get the singleton
 * FallThroughError exception that will be thrown.
 */
getFallThroughError() => const FallThroughErrorImplementation();

/**
 * Represents the type Dynamic. The compiler treats this specially.
 */
interface Dynamic {
}

/**
 * Represents the type of Null. The compiler treats this specially.
 */
class Null {
  factory Null() {
    throw new UnsupportedOperationException('new Null()');
  }
}

setRuntimeTypeInfo(target, typeInfo) {
  // We have to check for null because factories may return null.
  if (target !== null) JS('var', @'#.builtin$typeInfo = #', target, typeInfo);
}

getRuntimeTypeInfo(target) {
  if (target === null) return null;
  var res = JS('var', @'#.builtin$typeInfo', target);
  // If the object does not have runtime type information, return an
  // empty literal, to avoid null checks.
  // TODO(ngeoffray): Make the object a top-level field to avoid
  // allocating a new object every single time.
  return (res == null) ? JS('var', '{}') : res;
}

/**
 * The following methods are called by the runtime to implement
 * checked mode and casts. We specialize each primitive type (eg int, bool), and
 * use the compiler's convention to do is-checks on regular objects.
 */
stringTypeCheck(value) {
  if (value === null) return value;
  if (value is String) return value;
  throw new TypeErrorImplementation('$value does not implement String');
}

stringTypeCast(value) {
  if (value is String || value === null) return value;
  // TODO(lrn): When reified types are available, pass value.class and String.
  throw new CastExceptionImplementation(
      Primitives.objectTypeName(value), 'String');
}

doubleTypeCheck(value) {
  if (value === null) return value;
  if (value is double) return value;
  throw new TypeErrorImplementation('$value does not implement double');
}

doubleTypeCast(value) {
  if (value is double || value === null) return value;
  throw new CastExceptionImplementation(
      Primitives.objectTypeName(value), 'double');
}

numTypeCheck(value) {
  if (value === null) return value;
  if (value is num) return value;
  throw new TypeErrorImplementation('$value does not implement num');
}

numTypeCast(value) {
  if (value is num || value === null) return value;
  throw new CastExceptionImplementation(
      Primitives.objectTypeName(value), 'num');
}

boolTypeCheck(value) {
  if (value === null) return value;
  if (value is bool) return value;
  throw new TypeErrorImplementation('$value does not implement bool');
}

boolTypeCast(value) {
  if (value is bool || value === null) return value;
  throw new CastExceptionImplementation(
      Primitives.objectTypeName(value), 'bool');
}

functionTypeCheck(value) {
  if (value === null) return value;
  if (value is Function) return value;
  throw new TypeErrorImplementation('$value does not implement Function');
}

functionTypeCast(value) {
  if (value is Function || value === null) return value;
  throw new CastExceptionImplementation(
      Primitives.objectTypeName(value), 'Function');
}

intTypeCheck(value) {
  if (value === null) return value;
  if (value is int) return value;
  throw new TypeErrorImplementation('$value does not implement int');
}

intTypeCast(value) {
  if (value is int || value === null) return value;
  throw new CastExceptionImplementation(
      Primitives.objectTypeName(value), 'int');
}

void propertyTypeError(value, property) {
  // Cuts the property name to the class name.
  String name = property.substring(3, property.length);
  throw new TypeErrorImplementation('$value does not implement $name');
}

void propertyTypeCastError(value, property) {
  // Cuts the property name to the class name.
  String actualType = Primitives.objectTypeName(value);
  String expectedType = property.substring(3, property.length);
  throw new CastExceptionImplementation(actualType, expectedType);
}

/**
 * For types that are not supertypes of native (eg DOM) types,
 * we emit a simple property check to check that an object implements
 * that type.
 */
propertyTypeCheck(value, property) {
  if (value === null) return value;
  if (JS('bool', '!!#[#]', value, property)) return value;
  propertyTypeError(value, property);
}

/**
 * For types that are not supertypes of native (eg DOM) types,
 * we emit a simple property check to check that an object implements
 * that type.
 */
propertyTypeCast(value, property) {
  if (value === null || JS('bool', '!!#[#]', value, property)) return value;
  propertyTypeCastError(value, property);
}

/**
 * For types that are supertypes of native (eg DOM) types, we emit a
 * call because we cannot add a JS property to their prototype at load
 * time.
 */
callTypeCheck(value, property) {
  if (value === null) return value;
  if ((JS('String', 'typeof #', value) === 'object')
      && JS('bool', '#[#]()', value, property)) {
    return value;
  }
  propertyTypeError(value, property);
}

/**
 * For types that are supertypes of native (eg DOM) types, we emit a
 * call because we cannot add a JS property to their prototype at load
 * time.
 */
callTypeCast(value, property) {
  if (value === null
      || ((JS('bool', 'typeof # === "object"', value))
          && JS('bool', '#[#]()', value, property))) {
    return value;
  }
  propertyTypeCastError(value, property);
}

/**
 * Specialization of the type check for String and its supertype
 * since [value] can be a JS primitive.
 */
stringSuperTypeCheck(value, property) {
  if (value === null) return value;
  if (value is String) return value;
  if (JS('bool', '!!#[#]', value, property)) return value;
  propertyTypeError(value, property);
}

stringSuperTypeCast(value, property) {
  if (value is String) return value;
  return propertyTypeCast(value, property);
}

stringSuperNativeTypeCheck(value, property) {
  if (value === null) return value;
  if (value is String) return value;
  if (JS('bool', '#[#]()', value, property)) return value;
  propertyTypeError(value, property);
}

stringSuperNativeTypeCast(value, property) {
  if (value is String || value === null) return value;
  if (JS('bool', '#[#]()', value, property)) return value;
  propertyTypeCastError(value, property);
}

/**
 * Specialization of the type check for List and its supertypes,
 * since [value] can be a JS array.
 */
listTypeCheck(value) {
  if (value === null) return value;
  if (value is List) return value;
  throw new TypeErrorImplementation('$value does not implement List');
}

listTypeCast(value) {
  if (value is List || value === null) return value;
  throw new CastExceptionImplementation(
      Primitives.objectTypeName(value), 'List');
}

listSuperTypeCheck(value, property) {
  if (value === null) return value;
  if (value is List) return value;
  if (JS('bool', '!!#[#]', value, property)) return value;
  propertyTypeError(value, property);
}

listSuperTypeCast(value, property) {
  if (value is List) return value;
  return propertyTypeCast(value, property);
}

listSuperNativeTypeCheck(value, property) {
  if (value === null) return value;
  if (value is List) return value;
  if (JS('bool', '#[#]()', value, property)) return value;
  propertyTypeError(value, property);
}

listSuperNativeTypeCast(value, property) {
  if (value is List || value === null) return value;
  if (JS('bool', '#[#]()', value, property)) return value;
  propertyTypeCastError(value, property);
}

/**
 * Special interface recognized by the compiler and implemented by DOM
 * objects that support integer indexing. This interface is not
 * visible to anyone, and is only injected into special libraries.
 */
interface JavaScriptIndexingBehavior {
}

/**
 * Called by generated code when a method that must be statically
 * resolved cannot be found.
 */
void throwNoSuchMethod(obj, name, arguments) {
  throw new NoSuchMethodException(obj, name, arguments);
}

/**
 * Called by generated code when a static field's initializer references the
 * field that is currently being initialized.
 */
void throwCyclicInit(String staticName) {
  throw new RuntimeError("Cyclic initialization for static $staticName");
}
