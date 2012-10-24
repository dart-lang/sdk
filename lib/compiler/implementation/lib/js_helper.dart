// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('dart:_js_helper');

#import('dart:coreimpl');

#source('constant_map.dart');
#source('native_helper.dart');
#source('regexp_helper.dart');
#source('string_helper.dart');

// Performance critical helper methods.
add(var a, var b) => (a is num && b is num)
    ? JS('num', r'# + #', a, b)
    : add$slow(a, b);

sub(var a, var b) => (a is num && b is num)
    ? JS('num', r'# - #', a, b)
    : sub$slow(a, b);

div(var a, var b) => (a is num && b is num)
    ? JS('num', r'# / #', a, b)
    : div$slow(a, b);

mul(var a, var b) => (a is num && b is num)
    ? JS('num', r'# * #', a, b)
    : mul$slow(a, b);

gt(var a, var b) => (a is num && b is num)
    ? JS('bool', r'# > #', a, b)
    : gt$slow(a, b);

ge(var a, var b) => (a is num && b is num)
    ? JS('bool', r'# >= #', a, b)
    : ge$slow(a, b);

lt(var a, var b) => (a is num && b is num)
    ? JS('bool', r'# < #', a, b)
    : lt$slow(a, b);

le(var a, var b) => (a is num && b is num)
    ? JS('bool', r'# <= #', a, b)
    : le$slow(a, b);

gtB(var a, var b) => (a is num && b is num)
    ? JS('bool', r'# > #', a, b)
    : identical(gt$slow(a, b), true);

geB(var a, var b) => (a is num && b is num)
    ? JS('bool', r'# >= #', a, b)
    : identical(ge$slow(a, b), true);

ltB(var a, var b) => (a is num && b is num)
    ? JS('bool', r'# < #', a, b)
    : identical(lt$slow(a, b), true);

leB(var a, var b) => (a is num && b is num)
    ? JS('bool', r'# <= #', a, b)
    : identical(le$slow(a, b), true);

index(var a, var index) {
  // The type test may cause a NullPointerException to be thrown but
  // that matches the specification of what the indexing operator is
  // supposed to do.
  bool isJsArrayOrString = JS('bool',
      r'typeof # == "string" || #.constructor === Array',
      a, a);
  if (isJsArrayOrString) {
    var key = JS('int', '# >>> 0', index);
    if (identical(key, index) && key < JS('int', r'#.length', a)) {
      return JS('var', r'#[#]', a, key);
    }
  }
  return index$slow(a, index);
}

indexSet(var a, var index, var value) {
  // The type test may cause a NullPointerException to be thrown but
  // that matches the specification of what the indexing operator is
  // supposed to do.
  bool isMutableJsArray = JS('bool',
      r'#.constructor === Array && !#.immutable$list',
      a, a);
  if (isMutableJsArray) {
    var key = JS('int', '# >>> 0', index);
    if (identical(key, index) && key < JS('int', r'#.length', a)) {
      JS('void', r'#[#] = #', a, key, value);
      return;
    }
  }
  indexSet$slow(a, index, value);
}

/**
 * Returns true if both arguments are numbers.
 *
 * If only the first argument is a number, an
 * [ArgumentError] with the other argument is thrown.
 */
bool checkNumbers(var a, var b) {
  if (a is num) {
    if (b is num) {
      return true;
    } else {
      checkNull(b);
      throw new ArgumentError(b);
    }
  }
  return false;
}

bool isJsArray(var value) {
  return value != null && JS('bool', r'#.constructor === Array', value);
}

add$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', r'# + #', a, b);
  }
  return UNINTERCEPTED(a + b);
}

div$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', r'# / #', a, b);
  }
  return UNINTERCEPTED(a / b);
}

mul$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', r'# * #', a, b);
  }
  return UNINTERCEPTED(a * b);
}

sub$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', r'# - #', a, b);
  }
  return UNINTERCEPTED(a - b);
}

mod(var a, var b) {
  if (checkNumbers(a, b)) {
    // Euclidean Modulo.
    num result = JS('num', r'# % #', a, b);
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
    return (JS('num', r'# / #', a, b)).truncate();
  }
  return UNINTERCEPTED(a ~/ b);
}

eq(var a, var b) {
  if (JS('bool', r'# == null', a)) return JS('bool', r'# == null', b);
  if (JS('bool', r'# == null', b)) return false;
  if (JS('bool', r'typeof # === "object"', a)) {
    if (JS_HAS_EQUALS(a)) {
      return UNINTERCEPTED(a == b);
    }
  }
  // TODO(lrn): is NaN === NaN ? Is -0.0 === 0.0 ?
  return JS('bool', r'# === #', a, b);
}

bool eqB(var a, var b) {
  if (JS('bool', r'# == null', a)) return JS('bool', r'# == null', b);
  if (JS('bool', r'# == null', b)) return false;
  if (JS('bool', r'typeof # === "object"', a)) {
    if (JS_HAS_EQUALS(a)) {
      return identical(UNINTERCEPTED(a == b), true);
    }
  }
  // TODO(lrn): is NaN === NaN ? Is -0.0 === 0.0 ?
  return JS('bool', r'# === #', a, b);
}

eqq(var a, var b) {
  return JS('bool', r'# === #', a, b);
}

gt$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', r'# > #', a, b);
  }
  return UNINTERCEPTED(a > b);
}

ge$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', r'# >= #', a, b);
  }
  return UNINTERCEPTED(a >= b);
}

lt$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', r'# < #', a, b);
  }
  return UNINTERCEPTED(a < b);
}

le$slow(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', r'# <= #', a, b);
  }
  return UNINTERCEPTED(a <= b);
}

shl(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    if (JS('num', '#', b) < 0) throw new ArgumentError(b);
    // JavaScript only looks at the last 5 bits of the shift-amount. Shifting
    // by 33 is hence equivalent to a shift by 1.
    if (JS('bool', r'# > 31', b)) return 0;
    return JS('num', r'(# << #) >>> 0', a, b);
  }
  return UNINTERCEPTED(a << b);
}

shr(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    if (JS('num', '#', b) < 0) throw new ArgumentError(b);
    if (JS('num', '#', a) > 0) {
      // JavaScript only looks at the last 5 bits of the shift-amount. In JS
      // shifting by 33 is hence equivalent to a shift by 1. Shortcut the
      // computation when that happens.
      if (JS('bool', r'# > 31', b)) return 0;
      // Given that 'a' is positive we must not use '>>'. Otherwise a number
      // that has the 31st bit set would be treated as negative and shift in
      // ones.
      return JS('num', r'# >>> #', a, b);
    }
    // For negative numbers we just clamp the shift-by amount. 'a' could be
    // negative but not have its 31st bit set. The ">>" would then shift in
    // 0s instead of 1s. Therefore we cannot simply return 0xFFFFFFFF.
    if (JS('num', '#', b) > 31) b = 31;
    return JS('num', r'(# >> #) >>> 0', a, b);
  }
  return UNINTERCEPTED(a >> b);
}

and(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', r'(# & #) >>> 0', a, b);
  }
  return UNINTERCEPTED(a & b);
}

or(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', r'(# | #) >>> 0', a, b);
  }
  return UNINTERCEPTED(a | b);
}

xor(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', r'(# ^ #) >>> 0', a, b);
  }
  return UNINTERCEPTED(a ^ b);
}

not(var a) {
  if (JS('bool', r'typeof # === "number"', a)) {
    return JS('num', r'(~#) >>> 0', a);
  }
  return UNINTERCEPTED(~a);
}

neg(var a) {
  if (JS('bool', r'typeof # === "number"', a)) return JS('num', r'-#', a);
  return UNINTERCEPTED(-a);
}

index$slow(var a, var index) {
  if (a is String || isJsArray(a)) {
    if (index is !int) {
      if (index is !num) throw new ArgumentError(index);
      if (!identical(index.truncate(), index)) throw new ArgumentError(index);
    }
    if (index < 0 || index >= a.length) {
      throw new IndexOutOfRangeException(index);
    }
    return JS('Object', r'#[#]', a, index);
  }
  return UNINTERCEPTED(a[index]);
}

void indexSet$slow(var a, var index, var value) {
  if (isJsArray(a)) {
    if (index is !int) {
      throw new ArgumentError(index);
    }
    if (index < 0 || index >= a.length) {
      throw new IndexOutOfRangeException(index);
    }
    checkMutable(a, 'indexed set');
    JS('Object', r'#[#] = #', a, index, value);
    return;
  }
  UNINTERCEPTED(a[index] = value);
}

checkMutable(list, reason) {
  if (JS('bool', r'!!(#.immutable$list)', list)) {
    throw new UnsupportedError(reason);
  }
}

checkGrowable(list, reason) {
  if (JS('bool', r'!!(#.fixed$length)', list)) {
    throw new UnsupportedError(reason);
  }
}

String S(value) {
  var res = value.toString();
  if (res is !String) throw new ArgumentError(value);
  return res;
}

class ListIterator<T> implements Iterator<T> {
  int i;
  List<T> list;
  ListIterator(List<T> this.list) : i = 0;
  bool hasNext() => i < JS('int', r'#.length', list);
  T next() {
    if (!hasNext()) throw new NoMoreElementsException();
    var value = JS('Object', r'#[#]', list, i);
    i += 1;
    return value;
  }
}

class Primitives {
  static int hashCodeSeed = 0;

  static int objectHashCode(object) {
    int hash = JS('var', r'#.$identityHash', object);
    if (hash == null) {
      // TOOD(ahe): We should probably randomize this somehow.
      hash = ++hashCodeSeed;
      JS('void', r'#.$identityHash = #', object, hash);
    }
    return hash;
  }

  /**
   * This is the low-level method that is used to implement
   * [print]. It is possible to override this function from JavaScript
   * by defining a function in JavaScript called "dartPrint".
   */
  static void printString(String string) {
    // Support overriding print from JavaScript.
    if (JS('bool', r'typeof dartPrint == "function"')) {
      JS('void', r'dartPrint(#)', string);
      return;
    }

    // Inside browser.
    if (JS('bool', r'typeof window == "object"')) {
      // On IE, the console is only defined if dev tools is open.
      if (JS('bool', r'typeof console == "object"')) {
        JS('void', r'console.log(#)', string);
      }
      return;
    }

    // Running in d8, the V8 developer shell, or in Firefox' js-shell.
    if (JS('bool', r'typeof print == "function"')) {
      JS('void', r'print(#)', string);
      return;
    }

    // This is somewhat nasty, but we don't want to drag in a bunch of
    // dependencies to handle a situation that cannot happen. So we
    // avoid using Dart [:throw:] and Dart [toString].
    JS('void', "throw 'Unable to print message: ' + String(#)", string);
  }

  static int parseInt(String string) {
    checkString(string);
    var match = JS('List',
                   r'/^\s*[+-]?(?:0(x)[a-f0-9]+|\d+)\s*$/i.exec(#)',
                   string);
    if (match == null) {
      throw new FormatException(string);
    }
    var base = 10;
    if (match[1] != null) base = 16;
    var result = JS('num', r'parseInt(#, #)', string, base);
    if (result.isNaN) throw new FormatException(string);
    return result;
  }

  static double parseDouble(String string) {
    checkString(string);
    // Notice that JS parseFloat accepts garbage at the end of the string.
    // Accept, ignoring leading and trailing whitespace:
    // - NaN
    // - [+/-]Infinity
    // -  a Dart double literal
    if (!JS('bool',
            r'/^\s*(?:NaN|[+-]?(?:Infinity|'
                r'(?:\.\d+|\d+(?:\.\d+)?)(?:[eE][+-]?\d+)?))\s*$/.test(#)',
            string)) {
      throw new FormatException(string);
    }
    var result = JS('num', r'parseFloat(#)', string);
    if (result.isNaN && string != 'NaN') {
      throw new FormatException(string);
    }
    return result;
  }

  /** [: r"$".charCodeAt(0) :] */
  static const int DOLLAR_CHAR_VALUE = 36;

  static String objectTypeName(Object object) {
    String name = constructorNameFallback(object);
    if (name == 'Object') {
      // Try to decompile the constructor by turning it into a string
      // and get the name out of that. If the decompiled name is a
      // string, we use that instead of the very generic 'Object'.
      var decompiled = JS('var', r'#.match(/^\s*function\s*(\S*)\s*\(/)[1]',
                          JS('var', r'String(#.constructor)', object));
      if (decompiled is String) name = decompiled;
    }
    // TODO(kasperl): If the namer gave us a fresh global name, we may
    // want to remove the numeric suffix that makes it unique too.
    if (identical(name.charCodeAt(0), DOLLAR_CHAR_VALUE)) name = name.substring(1);
    return name;
  }

  static String objectToString(Object object) {
    String name = objectTypeName(object);
    return "Instance of '$name'";
  }

  static List newList(length) {
    if (length == null) return JS('Object', r'new Array()');
    if ((length is !int) || (length < 0)) {
      throw new ArgumentError(length);
    }
    var result = JS('Object', r'new Array(#)', length);
    JS('void', r'#.fixed$length = #', result, true);
    return result;
  }

  static num dateNow() => JS('num', r'Date.now()');

  static String stringFromCharCodes(charCodes) {
    for (var i in charCodes) {
      if (i is !int) throw new ArgumentError(i);
    }
    return JS('String', r'String.fromCharCode.apply(#, #)', null, charCodes);
  }

  static String getTimeZoneName(receiver) {
    // When calling toString on a Date it will emit the timezone in parenthesis.
    // Example: "Wed May 16 2012 21:13:00 GMT+0200 (CEST)".
    // We extract this name using a regexp.
    var d = lazyAsJsDate(receiver);
    return JS('String', r'/\((.*)\)/.exec(#.toString())[1]', d);
  }

  static int getTimeZoneOffsetInMinutes(receiver) {
    // Note that JS and Dart disagree on the sign of the offset.
    return -JS('int', r'#.getTimezoneOffset()', lazyAsJsDate(receiver));
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
      value = JS('num', r'Date.UTC(#, #, #, #, #, #, #)',
                 years, jsMonth, day, hours, minutes, seconds, milliseconds);
    } else {
      value = JS('num', r'new Date(#, #, #, #, #, #, #).valueOf()',
                 years, jsMonth, day, hours, minutes, seconds, milliseconds);
    }
    if (value.isNaN ||
        value < -MAX_MILLISECONDS_SINCE_EPOCH ||
        value > MAX_MILLISECONDS_SINCE_EPOCH) {
      throw new ArgumentError();
    }
    if (years <= 0 || years < 100) return patchUpY2K(value, years, isUtc);
    return value;
  }

  static patchUpY2K(value, years, isUtc) {
    var date = JS('Object', r'new Date(#)', value);
    if (isUtc) {
      JS('num', r'#.setUTCFullYear(#)', date, years);
    } else {
      JS('num', r'#.setFullYear(#)', date, years);
    }
    return JS('num', r'#.valueOf()', date);
  }

  // Lazily keep a JS Date stored in the JS object.
  static lazyAsJsDate(receiver) {
    if (JS('bool', r'#.date === (void 0)', receiver)) {
      JS('void', r'#.date = new Date(#)', receiver,
         receiver.millisecondsSinceEpoch);
    }
    return JS('Date', r'#.date', receiver);
  }

  // The getters for date and time parts below add a positive integer to ensure
  // that the result is really an integer, because the JavaScript implementation
  // may return -0.0 instead of 0.

  static getYear(receiver) {
    return (receiver.isUtc)
      ? JS('int', r'(#.getUTCFullYear() + 0)', lazyAsJsDate(receiver))
      : JS('int', r'(#.getFullYear() + 0)', lazyAsJsDate(receiver));
  }

  static getMonth(receiver) {
    return (receiver.isUtc)
      ? JS('int', r'#.getUTCMonth() + 1', lazyAsJsDate(receiver))
      : JS('int', r'#.getMonth() + 1', lazyAsJsDate(receiver));
  }

  static getDay(receiver) {
    return (receiver.isUtc)
      ? JS('int', r'(#.getUTCDate() + 0)', lazyAsJsDate(receiver))
      : JS('int', r'(#.getDate() + 0)', lazyAsJsDate(receiver));
  }

  static getHours(receiver) {
    return (receiver.isUtc)
      ? JS('int', r'(#.getUTCHours() + 0)', lazyAsJsDate(receiver))
      : JS('int', r'(#.getHours() + 0)', lazyAsJsDate(receiver));
  }

  static getMinutes(receiver) {
    return (receiver.isUtc)
      ? JS('int', r'(#.getUTCMinutes() + 0)', lazyAsJsDate(receiver))
      : JS('int', r'(#.getMinutes() + 0)', lazyAsJsDate(receiver));
  }

  static getSeconds(receiver) {
    return (receiver.isUtc)
      ? JS('int', r'(#.getUTCSeconds() + 0)', lazyAsJsDate(receiver))
      : JS('int', r'(#.getSeconds() + 0)', lazyAsJsDate(receiver));
  }

  static getMilliseconds(receiver) {
    return (receiver.isUtc)
      ? JS('int', r'(#.getUTCMilliseconds() + 0)', lazyAsJsDate(receiver))
      : JS('int', r'(#.getMilliseconds() + 0)', lazyAsJsDate(receiver));
  }

  static getWeekday(receiver) {
    int weekday = (receiver.isUtc)
      ? JS('int', r'#.getUTCDay() + 0', lazyAsJsDate(receiver))
      : JS('int', r'#.getDay() + 0', lazyAsJsDate(receiver));
    // Adjust by one because JS weeks start on Sunday.
    return (weekday + 6) % 7 + 1;
  }

  static valueFromDateString(str) {
    checkNull(str);
    if (str is !String) throw new ArgumentError(str);
    var value = JS('num', r'Date.parse(#)', str);
    if (value.isNaN) throw new ArgumentError(str);
    return value;
  }

  static getProperty(object, key) {
    checkNull(object);
    if (object is bool || object is num || object is String) {
      throw new ArgumentError(object);
    }
    return JS('var', '#[#]', object, key);
  }

  static void setProperty(object, key, value) {
    checkNull(object);
    if (object is bool || object is num || object is String) {
      throw new ArgumentError(object);
    }
    JS('void', '#[#] = #', object, key, value);
  }

  static applyFunction(Function function,
                       List positionalArguments,
                       Map<String, Dynamic> namedArguments) {
    int argumentCount = 0;
    StringBuffer buffer = new StringBuffer();
    List arguments = [];

    if (positionalArguments != null) {
      argumentCount += positionalArguments.length;
      arguments.addAll(positionalArguments);
    }

    // Sort the named arguments to get the right selector name and
    // arguments order.
    if (namedArguments != null && !namedArguments.isEmpty()) {
      // Call new List.from to make sure we get a JavaScript array.
      List<String> listOfNamedArguments =
          new List<String>.from(namedArguments.getKeys());
      argumentCount += namedArguments.length;
      // We're sorting on strings, and the behavior is the same between
      // Dart string sort and JS string sort. To avoid needing the Dart
      // sort implementation, we use the JavaScript one instead.
      JS('void', '#.sort()', listOfNamedArguments);
      listOfNamedArguments.forEach((String name) {
        buffer.add('\$$name');
        arguments.add(namedArguments[name]);
      });
    }

    String selectorName = 'call\$$argumentCount$buffer';
    var jsFunction = JS('var', '#[#]', function, selectorName);
    if (jsFunction == null) {
      throw new NoSuchMethodError(function, selectorName, arguments);
    }
    // We bound 'this' to [function] because of how we compile
    // closures: escaped local variables are stored and accessed through
    // [function].
    return JS('var', '#.apply(#, #)', jsFunction, function, arguments);
  }
}

/**
 * Called by generated code to throw an illegal-argument exception,
 * for example, if a non-integer index is given to an optimized
 * indexed access.
 */
iae(argument) {
  throw new ArgumentError(argument);
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
  if (length == 0) {
    return;
  }
  checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
  if (length is !int) throw new ArgumentError(length);
  if (length < 0) throw new ArgumentError(length);
  if (start is !int) throw new ArgumentError(start);

  var receiverLength = JS('num', r'#.length', receiver);
  if (start < 0 || start > receiverLength) {
    throw new IndexOutOfRangeException(start);
  }
  receiver.length = receiverLength + length;
  Arrays.copy(receiver,
              start,
              receiver,
              start + length,
              receiverLength - start);
  if (initialValue != null) {
    for (int i = start; i < start + length; i++) {
      receiver[i] = initialValue;
    }
  }
  receiver.length = receiverLength + length;
}

stringLastIndexOfUnchecked(receiver, element, start)
  => JS('int', r'#.lastIndexOf(#, #)', receiver, element, start);


checkNull(object) {
  if (object == null) throw new NullPointerException();
  return object;
}

checkNum(value) {
  if (value is !num) {
    checkNull(value);
    throw new ArgumentError(value);
  }
  return value;
}

checkInt(value) {
  if (value is !int) {
    checkNull(value);
    throw new ArgumentError(value);
  }
  return value;
}

checkBool(value) {
  if (value is !bool) {
    checkNull(value);
    throw new ArgumentError(value);
  }
  return value;
}

checkString(value) {
  if (value is !String) {
    checkNull(value);
    throw new ArgumentError(value);
  }
  return value;
}

substringUnchecked(receiver, startIndex, endIndex)
  => JS('String', r'#.substring(#, #)', receiver, startIndex, endIndex);

class MathNatives {
  static int parseInt(str) {
    checkString(str);
    if (!JS('bool',
            r'/^\s*[+-]?(?:0[xX][abcdefABCDEF0-9]+|\d+)\s*$/.test(#)',
            str)) {
      throw new FormatException(str);
    }
    var trimmed = str.trim();
    var base = 10;;
    if ((trimmed.length > 2 && (trimmed[1] == 'x' || trimmed[1] == 'X')) ||
        (trimmed.length > 3 && (trimmed[2] == 'x' || trimmed[2] == 'X'))) {
      base = 16;
    }
    var ret = JS('num', r'parseInt(#, #)', trimmed, base);
    if (ret.isNaN) throw new FormatException(str);
    return ret;
  }

  static double parseDouble(String str) {
    checkString(str);
    var ret = JS('num', r'parseFloat(#)', str);
    if (ret == 0 && (str.startsWith("0x") || str.startsWith("0X"))) {
      // TODO(ahe): This is unspecified, but tested by co19.
      ret = JS('num', r'parseInt(#)', str);
    }
    if (ret.isNaN && str != 'NaN' && str != '-NaN') {
      throw new FormatException(str);
    }
    return ret;
  }

  static double sqrt(num value)
    => JS('double', r'Math.sqrt(#)', checkNum(value));

  static double sin(num value)
    => JS('double', r'Math.sin(#)', checkNum(value));

  static double cos(num value)
    => JS('double', r'Math.cos(#)', checkNum(value));

  static double tan(num value)
    => JS('double', r'Math.tan(#)', checkNum(value));

  static double acos(num value)
    => JS('double', r'Math.acos(#)', checkNum(value));

  static double asin(num value)
    => JS('double', r'Math.asin(#)', checkNum(value));

  static double atan(num value)
    => JS('double', r'Math.atan(#)', checkNum(value));

  static double atan2(num a, num b)
    => JS('double', r'Math.atan2(#, #)', checkNum(a), checkNum(b));

  static double exp(num value)
    => JS('double', r'Math.exp(#)', checkNum(value));

  static double log(num value)
    => JS('double', r'Math.log(#)', checkNum(value));

  static num pow(num value, num exponent) {
    checkNum(value);
    checkNum(exponent);
    return JS('num', r'Math.pow(#, #)', value, exponent);
  }

  static double random() => JS('double', r'Math.random()');
}

/**
 * Throws the given Dart object as an exception by wrapping it in a
 * proper JavaScript error object and then throwing that. That gives
 * us a reasonable stack trace on most JavaScript implementations. The
 * code in [unwrapException] deals with getting the original Dart
 * object out of the wrapper again.
 */
$throw(ex) {
  if (ex == null) ex = const NullPointerException();
  var jsError = JS('Object', r'new Error()');
  JS('void', r'#.name = #', jsError, ex);
  JS('void', r'#.description = #', jsError, ex);
  JS('void', r'#.dartException = #', jsError, ex);
  JS('void', r'#.toString = #', jsError,
     DART_CLOSURE_TO_JS(toStringWrapper));
  JS('void', r'throw #', jsError);
}

/**
 * This method is installed as JavaScript toString method on exception
 * objects in [$throw]. So JavaScript 'this' binds to an instance of
 * JavaScript Error to which we have added a property 'dartException'
 * which holds a Dart object.
 */
toStringWrapper() => JS('Object', r'this.dartException').toString();

makeLiteralListConst(list) {
  JS('bool', r'#.immutable$list = #', list, true);
  JS('bool', r'#.fixed$length = #', list, true);
  return list;
}

throwRuntimeError(message) {
  throw new RuntimeError(message);
}

throwAbstractClassInstantiationError(className) {
  throw new AbstractClassInstantiationError(className);
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
  if (JS('bool', r'"dartException" in #', ex)) {
    return JS('Object', r'#.dartException', ex);
  }

  // Grab hold of the exception message. This field is available on
  // all supported browsers.
  var message = JS('var', r'#.message', ex);

  if (JS('bool', r'# instanceof TypeError', ex)) {
    // The type and arguments fields are Chrome specific but they
    // allow us to get very detailed information about what kind of
    // exception occurred.
    var type = JS('var', r'#.type', ex);
    var name = JS('var', r'#.arguments ? #.arguments[0] : ""', ex, ex);
    if (type == 'property_not_function' ||
        type == 'called_non_callable' ||
        type == 'non_object_property_call' ||
        type == 'non_object_property_load') {
      return new NullPointerException();
    } else if (type == 'undefined_method') {
      return new NoSuchMethodError('', name, []);
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
        return new NoSuchMethodError('', '<unknown>', []);
      }
    }

    // If we cannot determine what kind of error this is, we fall back
    // to reporting this as a generic exception. It's probably better
    // than nothing.
    return new Exception(message is String ? message : '');
  }

  if (JS('bool', r'# instanceof RangeError', ex)) {
    if (message is String && message.contains('call stack')) {
      return new StackOverflowError();
    }

    // In general, a RangeError is thrown when trying to pass a number
    // as an argument to a function that does not allow a range that
    // includes that number.
    return new ArgumentError();
  }

  // Check for the Firefox specific stack overflow signal.
  if (JS('bool',
         r"typeof InternalError == 'function' && # instanceof InternalError",
         ex)) {
    if (message is String && message == 'too much recursion') {
      return new StackOverflowError();
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
  return new StackTrace(JS("var", r"#.stack", exception));
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
  if (closure == null) return null;
  var function = JS('var', r'#.$identity', closure);
  if (JS('bool', r'!!#', function)) return function;

  function = JS("var", r"""function() {
    return #(#, #, #, arguments[0], arguments[1]);
  }""",
  DART_CLOSURE_TO_JS(invokeClosure),
  closure,
  JS_CURRENT_ISOLATE(),
  arity);

  JS('void', r'#.$identity = #', closure, function);
  return function;
}

/**
 * Super class for Dart closures.
 */
class Closure implements Function {
  String toString() => "Closure";
}

bool jsHasOwnProperty(var jsObject, String property) {
  return JS('bool', r'#.hasOwnProperty(#)', jsObject, property);
}

jsPropertyAccess(var jsObject, String property) {
  return JS('var', r'#[#]', jsObject, property);
}

/**
 * Called at the end of unaborted switch cases to get the singleton
 * FallThroughError exception that will be thrown.
 */
getFallThroughError() => const FallThroughErrorImplementation();

/**
 * Represents the type Dynamic. The compiler treats this specially.
 */
abstract class Dynamic_ {
}

/**
 * Represents the type of Null. The compiler treats this specially.
 * TODO(lrn): Null should be defined in core. It's a class, like int.
 * It just happens to act differently in assignability tests and,
 * like int, can't be extended or implemented.
 */
class Null {
  factory Null() {
    throw new UnsupportedError('new Null()');
  }
}

setRuntimeTypeInfo(target, typeInfo) {
  // We have to check for null because factories may return null.
  if (target != null) JS('var', r'#.builtin$typeInfo = #', target, typeInfo);
}

getRuntimeTypeInfo(target) {
  if (target == null) return null;
  var res = JS('var', r'#.builtin$typeInfo', target);
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
boolConversionCheck(value) {
  boolTypeCheck(value);
  assert(value != null);
  return value;
}

stringTypeCheck(value) {
  if (value == null) return value;
  if (value is String) return value;
  throw new TypeErrorImplementation(value, 'String');
}

stringTypeCast(value) {
  if (value is String || value == null) return value;
  // TODO(lrn): When reified types are available, pass value.class and String.
  throw new CastErrorImplementation(
      Primitives.objectTypeName(value), 'String');
}

doubleTypeCheck(value) {
  if (value == null) return value;
  if (value is double) return value;
  throw new TypeErrorImplementation(value, 'double');
}

doubleTypeCast(value) {
  if (value is double || value == null) return value;
  throw new CastErrorImplementation(
      Primitives.objectTypeName(value), 'double');
}

numTypeCheck(value) {
  if (value == null) return value;
  if (value is num) return value;
  throw new TypeErrorImplementation(value, 'num');
}

numTypeCast(value) {
  if (value is num || value == null) return value;
  throw new CastErrorImplementation(
      Primitives.objectTypeName(value), 'num');
}

boolTypeCheck(value) {
  if (value == null) return value;
  if (value is bool) return value;
  throw new TypeErrorImplementation(value, 'bool');
}

boolTypeCast(value) {
  if (value is bool || value == null) return value;
  throw new CastErrorImplementation(
      Primitives.objectTypeName(value), 'bool');
}

functionTypeCheck(value) {
  if (value == null) return value;
  if (value is Function) return value;
  throw new TypeErrorImplementation(value, 'Function');
}

functionTypeCast(value) {
  if (value is Function || value == null) return value;
  throw new CastErrorImplementation(
      Primitives.objectTypeName(value), 'Function');
}

intTypeCheck(value) {
  if (value == null) return value;
  if (value is int) return value;
  throw new TypeErrorImplementation(value, 'int');
}

intTypeCast(value) {
  if (value is int || value == null) return value;
  throw new CastErrorImplementation(
      Primitives.objectTypeName(value), 'int');
}

void propertyTypeError(value, property) {
  // Cuts the property name to the class name.
  String name = property.substring(3, property.length);
  throw new TypeErrorImplementation(value, name);
}

void propertyTypeCastError(value, property) {
  // Cuts the property name to the class name.
  String actualType = Primitives.objectTypeName(value);
  String expectedType = property.substring(3, property.length);
  throw new CastErrorImplementation(actualType, expectedType);
}

/**
 * For types that are not supertypes of native (eg DOM) types,
 * we emit a simple property check to check that an object implements
 * that type.
 */
propertyTypeCheck(value, property) {
  if (value == null) return value;
  if (JS('bool', '!!#[#]', value, property)) return value;
  propertyTypeError(value, property);
}

/**
 * For types that are not supertypes of native (eg DOM) types,
 * we emit a simple property check to check that an object implements
 * that type.
 */
propertyTypeCast(value, property) {
  if (value == null || JS('bool', '!!#[#]', value, property)) return value;
  propertyTypeCastError(value, property);
}

/**
 * For types that are supertypes of native (eg DOM) types, we emit a
 * call because we cannot add a JS property to their prototype at load
 * time.
 */
callTypeCheck(value, property) {
  if (value == null) return value;
  if ((identical(JS('String', 'typeof #', value), 'object'))
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
  if (value == null
      || ((JS('bool', 'typeof # === "object"', value))
          && JS('bool', '#[#]()', value, property))) {
    return value;
  }
  propertyTypeCastError(value, property);
}

/**
 * Specialization of the type check for num and String and their
 * supertype since [value] can be a JS primitive.
 */
numberOrStringSuperTypeCheck(value, property) {
  if (value == null) return value;
  if (value is String) return value;
  if (value is num) return value;
  if (JS('bool', '!!#[#]', value, property)) return value;
  propertyTypeError(value, property);
}

numberOrStringSuperTypeCast(value, property) {
  if (value is String) return value;
  if (value is num) return value;
  return propertyTypeCast(value, property);
}

numberOrStringSuperNativeTypeCheck(value, property) {
  if (value == null) return value;
  if (value is String) return value;
  if (value is num) return value;
  if (JS('bool', '#[#]()', value, property)) return value;
  propertyTypeError(value, property);
}

numberOrStringSuperNativeTypeCast(value, property) {
  if (value == null) return value;
  if (value is String) return value;
  if (value is num) return value;
  if (JS('bool', '#[#]()', value, property)) return value;
  propertyTypeCastError(value, property);
}

/**
 * Specialization of the type check for String and its supertype
 * since [value] can be a JS primitive.
 */
stringSuperTypeCheck(value, property) {
  if (value == null) return value;
  if (value is String) return value;
  if (JS('bool', '!!#[#]', value, property)) return value;
  propertyTypeError(value, property);
}

stringSuperTypeCast(value, property) {
  if (value is String) return value;
  return propertyTypeCast(value, property);
}

stringSuperNativeTypeCheck(value, property) {
  if (value == null) return value;
  if (value is String) return value;
  if (JS('bool', '#[#]()', value, property)) return value;
  propertyTypeError(value, property);
}

stringSuperNativeTypeCast(value, property) {
  if (value is String || value == null) return value;
  if (JS('bool', '#[#]()', value, property)) return value;
  propertyTypeCastError(value, property);
}

/**
 * Specialization of the type check for List and its supertypes,
 * since [value] can be a JS array.
 */
listTypeCheck(value) {
  if (value == null) return value;
  if (value is List) return value;
  throw new TypeErrorImplementation(value, 'List');
}

listTypeCast(value) {
  if (value is List || value == null) return value;
  throw new CastErrorImplementation(
      Primitives.objectTypeName(value), 'List');
}

listSuperTypeCheck(value, property) {
  if (value == null) return value;
  if (value is List) return value;
  if (JS('bool', '!!#[#]', value, property)) return value;
  propertyTypeError(value, property);
}

listSuperTypeCast(value, property) {
  if (value is List) return value;
  return propertyTypeCast(value, property);
}

listSuperNativeTypeCheck(value, property) {
  if (value == null) return value;
  if (value is List) return value;
  if (JS('bool', '#[#]()', value, property)) return value;
  propertyTypeError(value, property);
}

listSuperNativeTypeCast(value, property) {
  if (value is List || value == null) return value;
  if (JS('bool', '#[#]()', value, property)) return value;
  propertyTypeCastError(value, property);
}

/**
 * Special interface recognized by the compiler and implemented by DOM
 * objects that support integer indexing. This interface is not
 * visible to anyone, and is only injected into special libraries.
 */
abstract class JavaScriptIndexingBehavior {
}

// TODO(lrn): These exceptions should be implemented in core.
// When they are, remove the 'Implementation' here.

/** Thrown by type assertions that fail. */
class TypeErrorImplementation implements TypeError {
  final String message;
  TypeErrorImplementation(Object value, String type)
    : message = "type '${Primitives.objectTypeName(value)}' is not a subtype "
                "of type '$type'";
  String toString() => message;
}

/** Thrown by the 'as' operator if the cast isn't valid. */
class CastErrorImplementation implements CastError {
  // TODO(lrn): Rename to CastError (and move implementation into core).
  // TODO(lrn): Change actualType and expectedType to "Type" when reified
  // types are available.
  final Object actualType;
  final Object expectedType;

  CastErrorImplementation(this.actualType, this.expectedType);

  String toString() {
    return "CastError: Casting value of type $actualType to"
           " incompatible type $expectedType";
  }
}

class FallThroughErrorImplementation implements FallThroughError {
  const FallThroughErrorImplementation();
  String toString() => "Switch case fall-through.";
}

/**
 * Helper function for implementing asserts. The compiler treats this specially.
 */
void assertHelper(condition) {
  if (condition is Function) condition = condition();
  if (condition is !bool) {
    throw new TypeErrorImplementation(condition, 'bool');
  }
  // Compare to true to avoid boolean conversion check in checked
  // mode.
  if (!identical(condition, true)) throw new AssertionError();
}

/**
 * Called by generated code when a method that must be statically
 * resolved cannot be found.
 */
void throwNoSuchMethod(obj, name, arguments) {
  throw new NoSuchMethodError(obj, name, arguments);
}

/**
 * Called by generated code when a static field's initializer references the
 * field that is currently being initialized.
 */
void throwCyclicInit(String staticName) {
  throw new RuntimeError("Cyclic initialization for static $staticName");
}

class TypeImpl implements Type {
  final String typeName;
  TypeImpl(this.typeName);
  toString() => typeName;
}

Type getOrCreateCachedRuntimeType(String key) {
  Type runtimeType =
      JS('Type', r'#.runtimeTypeCache[#]', JS_CURRENT_ISOLATE(), key);
  if (runtimeType == null) {
    runtimeType = new TypeImpl(key);
    JS('void', r'#.runtimeTypeCache[#] = #', JS_CURRENT_ISOLATE(), key,
       runtimeType);
  }
  return runtimeType;
}

String getRuntimeTypeString(var object) {
  var typeInfo = JS('Object', r'#.builtin$typeInfo', object);
  return JS('String', r'#.runtimeType', typeInfo);
}
