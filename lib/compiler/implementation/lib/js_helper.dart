// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('js_helper');

#import('coreimpl.dart');

#source('constant_map.dart');
#source('native_helper.dart');
#source('regexp_helper.dart');
#source('string_helper.dart');

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

add(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# + #', a, b);
  } else if (a is String) {
    // TODO(lrn): Remove when we disable String.operator+
    b = b.toString();
    if (b is String) {
      return JS('String', @'# + #', a, b);
    }
    checkNull(b);
    throw new IllegalArgumentException(b);
  }
  return UNINTERCEPTED(a + b);
}

div(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# / #', a, b);
  }
  return UNINTERCEPTED(a / b);
}

mul(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# * #', a, b);
  }
  return UNINTERCEPTED(a * b);
}

sub(var a, var b) {
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
    if (b < 0) {
      return result - b;
    } else {
      return result + b;
    }
  }
  return UNINTERCEPTED(a % b);
}

tdiv(var a, var b) {
  if (checkNumbers(a, b)) {
    return (a / b).truncate();
  }
  return UNINTERCEPTED(a ~/ b);
}

eq(var a, var b) {
  if (JS('bool', @'typeof # === "object"', a)) {
    if (JS_HAS_EQUALS(a)) {
      return UNINTERCEPTED(a == b);
    } else {
      return JS('bool', @'# === #', a, b);
    }
  }
  // TODO(lrn): is NaN === NaN ? Is -0.0 === 0.0 ?
  return JS('bool', @'# === #', a, b);
}

bool eqB(var a, var b) => eq(a, b) === true;

eqq(var a, var b) {
  return JS('bool', @'# === #', a, b);
}

eqNull(var a) {
  if (JS('bool', @'typeof # === "object"', a)) {
    if (JS_HAS_EQUALS(a)) {
      return UNINTERCEPTED(a == null);
    } else {
      return false;
    }
  } else {
    return JS('bool', @'typeof # === "undefined"', a);
  }
}

bool eqNullB(var a) => eqNull(a) === true;

gt(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# > #', a, b);
  }
  return UNINTERCEPTED(a > b);
}

bool gtB(var a, var b) => gt(a, b) === true;

ge(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# >= #', a, b);
  }
  return UNINTERCEPTED(a >= b);
}

bool geB(var a, var b) => ge(a, b) === true;

lt(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# < #', a, b);
  }
  return UNINTERCEPTED(a < b);
}

bool ltB(var a, var b) => lt(a, b) === true;

le(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# <= #', a, b);
  }
  return UNINTERCEPTED(a <= b);
}

bool leB(var a, var b) => le(a, b) === true;

shl(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    if (b < 0) throw new IllegalArgumentException(b);
    return JS('num', @'# << #', a, b);
  }
  return UNINTERCEPTED(a << b);
}

shr(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    if (b < 0) throw new IllegalArgumentException(b);
    return JS('num', @'# >> #', a, b);
  }
  return UNINTERCEPTED(a >> b);
}

and(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', @'# & #', a, b);
  }
  return UNINTERCEPTED(a & b);
}

or(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', @'# | #', a, b);
  }
  return UNINTERCEPTED(a | b);
}

xor(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', @'# ^ #', a, b);
  }
  return UNINTERCEPTED(a ^ b);
}

not(var a) {
  if (JS('bool', @'typeof # === "number"', a)) return JS('num', @'~#', a);
  return UNINTERCEPTED(~a);
}

neg(var a) {
  if (JS('bool', @'typeof # === "number"', a)) return JS('num', @'-#', a);
  return UNINTERCEPTED(-a);
}

index(var a, var index) {
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

void indexSet(var a, var index, var value) {
  if (isJsArray(a)) {
    if (!(index is int)) {
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

String stringToString(value) {
  var res = value.toString();
  if (res is !String) throw new IllegalArgumentException(value);
  return res;
}

String stringConcat(String receiver, String other) {
  assert(receiver is String);
  assert(other is String);
  return JS('String', @'# + #', receiver, other);
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
  static void printString(String string) {
    var hasConsole = JS('bool', @'typeof console == "object"');
    if (hasConsole) {
      JS('void', @'console.log(#)', string);
    } else {
      JS('void', @'write(#)', string);
      JS('void', @'write("\n")');
    }
  }

  /** [: @"$".charCodeAt(0) :] */
  static final int DOLLAR_CHAR_VALUE = 36;

  static String objectToString(Object object) {
    String name = JS('String', @'#.constructor.name', object);
    if (name === null) {
      name = JS('String', @'#.match(/^\s*function\s*\$?(\S*)\s*\(/)[1]',
                JS('String', @'#.constructor.toString()', object));
    } else {
      if (name.charCodeAt(0) === DOLLAR_CHAR_VALUE) name = name.substring(1);
    }
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

  static valueFromDecomposedDate(years, month, day, hours, minutes, seconds,
                                 milliseconds, isUtc) {
    checkInt(years);
    checkInt(month);
    if (month < 1 || 12 < month) throw new IllegalArgumentException(month);
    checkInt(day);
    if (day < 1 || 31 < day) throw new IllegalArgumentException(day);
    checkInt(hours);
    if (hours < 0 || 24 < hours) throw new IllegalArgumentException(hours);
    checkInt(minutes);
    if (minutes < 0 || 59 < minutes) {
      throw new IllegalArgumentException(minutes);
    }
    checkInt(seconds);
    if (seconds < 0 || 59 < seconds) {
      // TODO(ahe): Leap seconds?
      throw new IllegalArgumentException(seconds);
    }
    checkInt(milliseconds);
    if (milliseconds < 0 || 999 < milliseconds) {
      throw new IllegalArgumentException(milliseconds);
    }
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
    if (value.isNaN()) throw new IllegalArgumentException('');
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
      JS('void', @'#.date = new Date(#)', receiver, receiver.value);
    }
    return JS('Date', @'#.date', receiver);
  }

  static getYear(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCFullYear()', lazyAsJsDate(receiver))
      : JS('int', @'#.getFullYear()', lazyAsJsDate(receiver));
  }

  static getMonth(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCMonth()', lazyAsJsDate(receiver)) + 1
      : JS('int', @'#.getMonth()', lazyAsJsDate(receiver)) + 1;
  }

  static getDay(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCDate()', lazyAsJsDate(receiver))
      : JS('int', @'#.getDate()', lazyAsJsDate(receiver));
  }

  static getHours(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCHours()', lazyAsJsDate(receiver))
      : JS('int', @'#.getHours()', lazyAsJsDate(receiver));
  }

  static getMinutes(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCMinutes()', lazyAsJsDate(receiver))
      : JS('int', @'#.getMinutes()', lazyAsJsDate(receiver));
  }

  static getSeconds(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCSeconds()', lazyAsJsDate(receiver))
      : JS('int', @'#.getSeconds()', lazyAsJsDate(receiver));
  }

  static getMilliseconds(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCMilliseconds()', lazyAsJsDate(receiver))
      : JS('int', @'#.getMilliseconds()', lazyAsJsDate(receiver));
  }

  static getWeekday(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCDay()', lazyAsJsDate(receiver))
      : JS('int', @'#.getDay()', lazyAsJsDate(receiver));
  }

  static valueFromDateString(str) {
    checkNull(str);
    if (str is !String) throw new IllegalArgumentException(str);
    var value = JS('num', @'Date.parse(#)', str);
    if (value.isNaN()) throw new IllegalArgumentException(str);
    return value;
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
      throw new BadNumberFormatException(str);
    }
    var trimmed = str.trim();
    var base = 10;;
    if ((trimmed.length > 2 && (trimmed[1] == 'x' || trimmed[1] == 'X')) ||
        (trimmed.length > 3 && (trimmed[2] == 'x' || trimmed[2] == 'X'))) {
      base = 16;
    }
    var ret = JS('num', @'parseInt(#, #)', trimmed, base);
    if (ret.isNaN()) throw new BadNumberFormatException(str);
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
      throw new BadNumberFormatException(str);
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
 * Called by generated code to capture the stacktrace before throwing
 * an exception.
 */
captureStackTrace(ex) {
  var jsError = JS('Object', @'new Error()');
  JS('void', @'#.dartException = #', jsError, ex);
  JS('void', @'''#.toString = #''', jsError,
     DART_CLOSURE_TO_JS(toStringWrapper));
  return jsError;
}

/**
 * This method is installed as JavaScript toString method on exception
 * objects in [captureStackTrace]. So JavaScript 'this' binds to an
 * instance of JavaScript Error to which we have added a property
 * 'dartException' which holds a Dart object.
 */
toStringWrapper() => JS('Object', @'this.dartException').toString();

makeLiteralListConst(list) {
  JS('bool', @'#.immutable$list = #', list, true);
  JS('bool', @'#.fixed$length = #', list, true);
  return list;
}

/**
 * Called from catch blocks in generated code to extract the Dart
 * exception from the thrown value. The thrown value may have been
 * created by [captureStackTrace] or it may be a 'native' JS
 * exception.
 *
 * Some native exceptions are mapped to new Dart instances, others are
 * returned unmodified.
 */
unwrapException(ex) {
  // Note that we are checking if the object has the property. If it
  // has, it could be set to null if the thrown value is null.
  if (JS('bool', @'"dartException" in #', ex)) {
    return JS('Object', @'#.dartException', ex);
  } else if (JS('bool', @'# instanceof TypeError', ex)) {
    // TODO(ahe): ex.type is Chrome specific.
    var type = JS('String', @'#.type', ex);
    var jsArguments = JS('Object', @'#.arguments', ex);
    var name = jsArguments[0];
    if (type == 'property_not_function' ||
        type == 'called_non_callable' ||
        type == 'non_object_property_call' ||
        type == 'non_object_property_load') {
      if (name !== null && name.startsWith(@'$call$')) {
        return new ObjectNotClosureException();
      } else {
        return new NullPointerException();
      }
    } else if (type == 'undefined_method') {
      if (name is String && name.startsWith(@'$call$')) {
        return new ObjectNotClosureException();
      } else {
        return new NoSuchMethodException('', name, []);
      }
    }
  } else if (JS('bool', @'# instanceof RangeError', ex)) {
    var message = JS('String', @'#.message', ex);
    if (message.contains('call stack')) {
      return new StackOverflowException();
    }
  }
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
convertDartClosureToJS(closure) {
  if (closure === null) return null;
  var function = JS('var', @'#.$identity', closure);
  if (JS('bool', @'!!#', function)) return function;

  function = JS("var", @"""function() {
    return #(#, #, arguments.length, arguments[0], arguments[1]);
  }""",
  DART_CLOSURE_TO_JS(invokeClosure),
  closure,
  JS_CURRENT_ISOLATE());

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
getFallThroughError() => const FallThroughError();

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
  return JS('var', @'#.builtin$typeInfo', target);
}
