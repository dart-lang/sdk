// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_helper;

import 'dart:collection';

import 'dart:_foreign_helper' show
    JS,
    JS_STRING_CONCAT;

import 'dart:_interceptors';
import 'dart:_runtime';

part 'annotations.dart';
part 'native_helper.dart';
part 'regexp_helper.dart';
part 'string_helper.dart';
part 'js_rti.dart';

class _Patch {
  const _Patch();
}

const _Patch patch = const _Patch();

/// Marks the internal map in dart2js, so that internal libraries can is-check
// them.
abstract class InternalMap {
}

class Primitives {
  /// Isolate-unique ID for caching [JsClosureMirror.function].
  /// Note the initial value is used by the first isolate (or if there are no
  /// isolates), new isolates will update this value to avoid conflicts by
  /// calling [initializeStatics].
  static String mirrorFunctionCacheName = '\$cachedFunction';

  /// Isolate-unique ID for caching [JsInstanceMirror._invoke].
  static String mirrorInvokeCacheName = '\$cachedInvocation';

  /// Called when creating a new isolate (see _IsolateContext constructor in
  /// isolate_helper.dart).
  /// Please don't add complicated code to this method, as it will impact
  /// start-up performance.
  static void initializeStatics(int id) {
    // Benchmarking shows significant performance improvements if this is a
    // fixed value.
    mirrorFunctionCacheName += '_$id';
    mirrorInvokeCacheName += '_$id';
  }

  static int objectHashCode(object) {
    int hash = JS('int|Null', r'#.$identityHash', object);
    if (hash == null) {
      hash = JS('int', '(Math.random() * 0x3fffffff) | 0');
      JS('void', r'#.$identityHash = #', object, hash);
    }
    return JS('int', '#', hash);
  }

  static _throwFormatException(String string) {
    throw new FormatException(string);
  }

  static int parseInt(String source,
                      int radix,
                      int handleError(String source)) {
    // TODO(vsm): Make _throwFormatException generic and use directly
    // to avoid closure allocation.
    if (handleError == null) handleError = (s) => _throwFormatException(s);

    checkString(source);
    var match = JS('JSExtendableArray|Null',
        r'/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(#)',
        source);
    int digitsIndex = 1;
    int hexIndex = 2;
    int decimalIndex = 3;
    int nonDecimalHexIndex = 4;
    if (radix == null) {
      radix = 10;
      if (match != null) {
        if (match[hexIndex] != null) {
          // Cannot fail because we know that the digits are all hex.
          return JS('int', r'parseInt(#, 16)', source);
        }
        if (match[decimalIndex] != null) {
          // Cannot fail because we know that the digits are all decimal.
          return JS('int', r'parseInt(#, 10)', source);
        }
        return handleError(source);
      }
    } else {
      if (radix is! int) throw new ArgumentError("Radix is not an integer");
      if (radix < 2 || radix > 36) {
        throw new RangeError("Radix $radix not in range 2..36");
      }
      if (match != null) {
        if (radix == 10 && match[decimalIndex] != null) {
          // Cannot fail because we know that the digits are all decimal.
          return JS('int', r'parseInt(#, 10)', source);
        }
        if (radix < 10 || match[decimalIndex] == null) {
          // We know that the characters must be ASCII as otherwise the
          // regexp wouldn't have matched. Lowercasing by doing `| 0x20` is thus
          // guaranteed to be a safe operation, since it preserves digits
          // and lower-cases ASCII letters.
          int maxCharCode;
          if (radix <= 10) {
            // Allow all digits less than the radix. For example 0, 1, 2 for
            // radix 3.
            // "0".codeUnitAt(0) + radix - 1;
            maxCharCode = 0x30 + radix - 1;
          } else {
            // Letters are located after the digits in ASCII. Therefore we
            // only check for the character code. The regexp above made already
            // sure that the string does not contain anything but digits or
            // letters.
            // "a".codeUnitAt(0) + (radix - 10) - 1;
            maxCharCode = 0x61 + radix - 10 - 1;
          }
          String digitsPart = match[digitsIndex];
          for (int i = 0; i < digitsPart.length; i++) {
            int characterCode = digitsPart.codeUnitAt(0) | 0x20;
            if (digitsPart.codeUnitAt(i) > maxCharCode) {
              return handleError(source);
            }
          }
        }
      }
    }
    if (match == null) return handleError(source);
    return JS('int', r'parseInt(#, #)', source, radix);
  }

  static double parseDouble(String source, double handleError(String source)) {
    checkString(source);
    // TODO(vsm): Make _throwFormatException generic and use directly
    // to avoid closure allocation.
    if (handleError == null) handleError = (s) => _throwFormatException(s);
    // Notice that JS parseFloat accepts garbage at the end of the string.
    // Accept only:
    // - [+/-]NaN
    // - [+/-]Infinity
    // - a Dart double literal
    // We do allow leading or trailing whitespace.
    if (!JS('bool',
            r'/^\s*[+-]?(?:Infinity|NaN|'
                r'(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(#)',
            source)) {
      return handleError(source);
    }
    var result = JS('num', r'parseFloat(#)', source);
    if (result.isNaN) {
      var trimmed = source.trim();
      if (trimmed == 'NaN' || trimmed == '+NaN' || trimmed == '-NaN') {
        return result;
      }
      return handleError(source);
    }
    return result;
  }

  /** [: r"$".codeUnitAt(0) :] */
  static const int DOLLAR_CHAR_VALUE = 36;

  /// Returns the type of [object] as a string (including type arguments).
  ///
  /// In minified mode, uses the unminified names if available.
  static String objectTypeName(Object object) {
    return getRuntimeType(object).toString();
  }

  /// In minified mode, uses the unminified names if available.
  static String objectToString(Object object) {
    // String name = objectTypeName(object);
    String name = JS('String', 'dart.typeName(dart.getReifiedType(#))', object);
    return "Instance of '$name'";
  }

  static int dateNow() => JS('int', r'Date.now()');

  static void initTicker() {
    if (timerFrequency != null) return;
    // Start with low-resolution. We overwrite the fields if we find better.
    timerFrequency = 1000;
    timerTicks = dateNow;
    if (JS('bool', 'typeof window == "undefined"')) return;
    var jsWindow = JS('var', 'window');
    if (jsWindow == null) return;
    var performance = JS('var', '#.performance', jsWindow);
    if (performance == null) return;
    if (JS('bool', 'typeof #.now != "function"', performance)) return;
    timerFrequency = 1000000;
    timerTicks = () => (1000 * JS('num', '#.now()', performance)).floor();
  }

  static int timerFrequency;
  static Function timerTicks;

  static bool get isD8 {
    return JS('bool',
              'typeof version == "function"'
              ' && typeof os == "object" && "system" in os');
  }

  static bool get isJsshell {
    return JS('bool',
              'typeof version == "function" && typeof system == "function"');
  }

  static String currentUri() {
    // In a browser return self.location.href.
    if (JS('bool', '!!self.location')) {
      return JS('String', 'self.location.href');
    }

    return null;
  }

  // This is to avoid stack overflows due to very large argument arrays in
  // apply().  It fixes http://dartbug.com/6919
  static String _fromCharCodeApply(List<int> array) {
    String result = "";
    const kMaxApply = 500;
    int end = array.length;
    for (var i = 0; i < end; i += kMaxApply) {
      var subarray;
      if (end <= kMaxApply) {
        subarray = array;
      } else {
        subarray = JS('JSExtendableArray', r'#.slice(#, #)', array,
                      i, i + kMaxApply < end ? i + kMaxApply : end);
      }
      result = JS('String', '# + String.fromCharCode.apply(#, #)',
                  result, null, subarray);
    }
    return result;
  }

  static String stringFromCodePoints(codePoints) {
    List<int> a = <int>[];
    for (var i in codePoints) {
      if (i is !int) throw new ArgumentError(i);
      if (i <= 0xffff) {
        a.add(i);
      } else if (i <= 0x10ffff) {
        a.add(0xd800 + ((((i - 0x10000) >> 10) & 0x3ff)));
        a.add(0xdc00 + (i & 0x3ff));
      } else {
        throw new ArgumentError(i);
      }
    }
    return _fromCharCodeApply(a);
  }

  static String stringFromCharCodes(charCodes) {
    for (var i in charCodes) {
      if (i is !int) throw new ArgumentError(i);
      if (i < 0) throw new ArgumentError(i);
      if (i > 0xffff) return stringFromCodePoints(charCodes);
    }
    return _fromCharCodeApply(charCodes);
  }

  static String stringFromCharCode(charCode) {
    if (0 <= charCode) {
      if (charCode <= 0xffff) {
        return JS('String', 'String.fromCharCode(#)', charCode);
      }
      if (charCode <= 0x10ffff) {
        var bits = charCode - 0x10000;
        var low = 0xDC00 | (bits & 0x3ff);
        var high = 0xD800 | (bits >> 10);
        return  JS('String', 'String.fromCharCode(#, #)', high, low);
      }
    }
    throw new RangeError.range(charCode, 0, 0x10ffff);
  }

  static String stringConcatUnchecked(String string1, String string2) {
    return JS_STRING_CONCAT(string1, string2);
  }

  static String flattenString(String str) {
    return JS('String', "#.charCodeAt(0) == 0 ? # : #", str, str, str);
  }

  static String getTimeZoneName(receiver) {
    // Firefox and Chrome emit the timezone in parenthesis.
    // Example: "Wed May 16 2012 21:13:00 GMT+0200 (CEST)".
    // We extract this name using a regexp.
    var d = lazyAsJsDate(receiver);
    List match = JS('JSArray|Null', r'/\((.*)\)/.exec(#.toString())', d);
    if (match != null) return match[1];

    // Internet Explorer 10+ emits the zone name without parenthesis:
    // Example: Thu Oct 31 14:07:44 PDT 2013
    match = JS('JSArray|Null',
                // Thu followed by a space.
                r'/^[A-Z,a-z]{3}\s'
                // Oct 31 followed by space.
                r'[A-Z,a-z]{3}\s\d+\s'
                // Time followed by a space.
                r'\d{2}:\d{2}:\d{2}\s'
                // The time zone name followed by a space.
                r'([A-Z]{3,5})\s'
                // The year.
                r'\d{4}$/'
                '.exec(#.toString())',
                d);
    if (match != null) return match[1];

    // IE 9 and Opera don't provide the zone name. We fall back to emitting the
    // UTC/GMT offset.
    // Example (IE9): Wed Nov 20 09:51:00 UTC+0100 2013
    //       (Opera): Wed Nov 20 2013 11:03:38 GMT+0100
    match = JS('JSArray|Null', r'/(?:GMT|UTC)[+-]\d{4}/.exec(#.toString())', d);
    if (match != null) return match[0];
    return "";
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
      return null;
    }
    if (years <= 0 || years < 100) return patchUpY2K(value, years, isUtc);
    return value;
  }

  static patchUpY2K(value, years, isUtc) {
    var date = JS('', r'new Date(#)', value);
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
    return JS('var', r'#.date', receiver);
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
    if (str is !String) throw new ArgumentError(str);
    var value = JS('num', r'Date.parse(#)', str);
    if (value.isNaN) throw new ArgumentError(str);
    return value;
  }

  static getProperty(object, key) {
    if (object == null || object is bool || object is num || object is String) {
      throw new ArgumentError(object);
    }
    return JS('var', '#[#]', object, key);
  }

  static void setProperty(object, key, value) {
    if (object == null || object is bool || object is num || object is String) {
      throw new ArgumentError(object);
    }
    JS('void', '#[#] = #', object, key, value);
  }

  static bool identicalImplementation(a, b) {
    return JS('bool', '# == null', a)
      ? JS('bool', '# == null', b)
      : JS('bool', '# === #', a, b);
  }

  static StackTrace extractStackTrace(Error error) {
    return getTraceFromException(JS('', r'#.$thrownJsError', error));
  }
}

stringLastIndexOfUnchecked(receiver, element, start)
  => JS('int', r'#.lastIndexOf(#, #)', receiver, element, start);


checkNull(object) {
  if (object == null) throw new ArgumentError(null);
  return object;
}

checkNum(value) {
  if (value is !num) {
    throw new ArgumentError(value);
  }
  return value;
}

checkInt(value) {
  if (value is !int) {
    throw new ArgumentError(value);
  }
  return value;
}

checkBool(value) {
  if (value is !bool) {
    throw new ArgumentError(value);
  }
  return value;
}

checkString(value) {
  if (value is !String) {
    throw new ArgumentError(value);
  }
  return value;
}

throwRuntimeError(message) {
  throw new RuntimeError(message);
}

throwAbstractClassInstantiationError(className) {
  throw new AbstractClassInstantiationError(className);
}

class NullError extends Error implements NoSuchMethodError {
  final String _message;
  final String _method;

  NullError(this._message, match)
      : _method = match == null ? null : JS('', '#.method', match);

  String toString() {
    if (_method == null) return 'NullError: $_message';
    return 'NullError: Cannot call "$_method" on null';
  }
}

class JsNoSuchMethodError extends Error implements NoSuchMethodError {
  final String _message;
  final String _method;
  final String _receiver;

  JsNoSuchMethodError(this._message, match)
      : _method = match == null ? null : JS('String|Null', '#.method', match),
        _receiver =
            match == null ? null : JS('String|Null', '#.receiver', match);

  String toString() {
    if (_method == null) return 'NoSuchMethodError: $_message';
    if (_receiver == null) {
      return 'NoSuchMethodError: Cannot call "$_method" ($_message)';
    }
    return 'NoSuchMethodError: Cannot call "$_method" on "$_receiver" '
        '($_message)';
  }
}

class UnknownJsTypeError extends Error {
  final String _message;

  UnknownJsTypeError(this._message);

  String toString() => _message.isEmpty ? 'Error' : 'Error: $_message';
}

/**
 * Called by generated code to fetch the stack trace from an
 * exception. Should never return null.
 */
StackTrace getTraceFromException(exception) => new _StackTrace(exception);

class _StackTrace implements StackTrace {
  var _exception;
  String _trace;
  _StackTrace(this._exception);

  String toString() {
    if (_trace != null) return _trace;

    String trace;
    if (JS('bool', 'typeof # === "object"', _exception)) {
      trace = JS("String|Null", r"#.stack", _exception);
    }
    return _trace = (trace == null) ? '' : trace;
  }
}

int objectHashCode(var object) {
  if (object == null || JS('bool', "typeof # != 'object'", object)) {
    return object.hashCode;
  } else {
    return Primitives.objectHashCode(object);
  }
}

/**
 * Called by generated code to build a map literal. [keyValuePairs] is
 * a list of key, value, key, value, ..., etc.
 */
fillLiteralMap(keyValuePairs, Map result) {
  // TODO(johnniwinther): Use JSArray to optimize this code instead of calling
  // [getLength] and [getIndex].
  int index = 0;
  int length = getLength(keyValuePairs);
  while (index < length) {
    var key = getIndex(keyValuePairs, index++);
    var value = getIndex(keyValuePairs, index++);
    result[key] = value;
  }
  return result;
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
getFallThroughError() => new FallThroughErrorImplementation();

/**
 * A metadata annotation describing the types instantiated by a native element.
 *
 * The annotation is valid on a native method and a field of a native class.
 *
 * By default, a field of a native class is seen as an instantiation point for
 * all native classes that are a subtype of the field's type, and a native
 * method is seen as an instantiation point fo all native classes that are a
 * subtype of the method's return type, or the argument types of the declared
 * type of the method's callback parameter.
 *
 * An @[Creates] annotation overrides the default set of instantiated types.  If
 * one or more @[Creates] annotations are present, the type of the native
 * element is ignored, and the union of @[Creates] annotations is used instead.
 * The names in the strings are resolved and the program will fail to compile
 * with dart2js if they do not name types.
 *
 * The argument to [Creates] is a string.  The string is parsed as the names of
 * one or more types, separated by vertical bars `|`.  There are some special
 * names:
 *
 * * `=Object`. This means 'exactly Object', which is a plain JavaScript object
 *   with properties and none of the subtypes of Object.
 *
 * Example: we may know that a method always returns a specific implementation:
 *
 *     @Creates('_NodeList')
 *     List<Node> getElementsByTagName(String tag) native;
 *
 * Useful trick: A method can be marked as not instantiating any native classes
 * with the annotation `@Creates('Null')`.  This is useful for fields on native
 * classes that are used only in Dart code.
 *
 *     @Creates('Null')
 *     var _cachedFoo;
 */
class Creates {
  final String types;
  const Creates(this.types);
}

/**
 * A metadata annotation describing the types returned or yielded by a native
 * element.
 *
 * The annotation is valid on a native method and a field of a native class.
 *
 * By default, a native method or field is seen as returning or yielding all
 * subtypes if the method return type or field type.  This annotation allows a
 * more precise set of types to be specified.
 *
 * See [Creates] for the syntax of the argument.
 *
 * Example: IndexedDB keys are numbers, strings and JavaScript Arrays of keys.
 *
 *     @Returns('String|num|JSExtendableArray')
 *     dynamic key;
 *
 *     // Equivalent:
 *     @Returns('String') @Returns('num') @Returns('JSExtendableArray')
 *     dynamic key;
 */
class Returns {
  final String types;
  const Returns(this.types);
}

/**
 * A metadata annotation placed on native methods and fields of native classes
 * to specify the JavaScript name.
 *
 * This example declares a Dart field + getter + setter called `$dom_title` that
 * corresponds to the JavaScript property `title`.
 *
 *     class Docmument native "*Foo" {
 *       @JSName('title')
 *       String $dom_title;
 *     }
 */
class JSName {
  final String name;
  const JSName(this.name);
}

/**
 * Special interface recognized by the compiler and implemented by DOM
 * objects that support integer indexing. This interface is not
 * visible to anyone, and is only injected into special libraries.
 */
abstract class JavaScriptIndexingBehavior extends JSMutableIndexable {
}

// TODO(lrn): These exceptions should be implemented in core.
// When they are, remove the 'Implementation' here.

/** Thrown by type assertions that fail. */
class TypeErrorImplementation extends Error implements TypeError {
  final String message;

  /**
   * Normal type error caused by a failed subtype test.
   */
  TypeErrorImplementation(Object value, String type)
      : message = "type '${Primitives.objectTypeName(value)}' is not a subtype "
                  "of type '$type'";

  TypeErrorImplementation.fromMessage(String this.message);

  String toString() => message;
}

/** Thrown by the 'as' operator if the cast isn't valid. */
class CastErrorImplementation extends Error implements CastError {
  // TODO(lrn): Rename to CastError (and move implementation into core).
  final String message;

  /**
   * Normal cast error caused by a failed type cast.
   */
  CastErrorImplementation(Object actualType, Object expectedType)
      : message = "CastError: Casting value of type $actualType to"
                  " incompatible type $expectedType";

  String toString() => message;
}

class FallThroughErrorImplementation extends FallThroughError {
  FallThroughErrorImplementation();
  String toString() => "Switch case fall-through.";
}

/**
 * Error thrown when a runtime error occurs.
 */
class RuntimeError extends Error {
  final message;
  RuntimeError(this.message);
  String toString() => "RuntimeError: $message";
}

/**
 * Creates a random number with 64 bits of randomness.
 *
 * This will be truncated to the 53 bits available in a double.
 */
int random64() {
  // TODO(lrn): Use a secure random source.
  int int32a = JS("int", "(Math.random() * 0x100000000) >>> 0");
  int int32b = JS("int", "(Math.random() * 0x100000000) >>> 0");
  return int32a + int32b * 0x100000000;
}

String jsonEncodeNative(String string) {
  return JS("String", "JSON.stringify(#)", string);
}


// TODO(jmesserly): this adapter is to work around:
// https://github.com/dart-lang/dev_compiler/issues/247
class SyncIterator<E> implements Iterator<E> {
  final dynamic _jsIterator;
  E _current;

  SyncIterator(this._jsIterator);

  E get current => _current;

  bool moveNext() {
    final ret = JS('', '#.next()', _jsIterator);
    _current = JS('', '#.value', ret);
    return JS('bool', '!#.done', ret);
  }
}

class SyncIterable<E> extends IterableBase<E> {
  final dynamic _generator;
  final dynamic _args;

  SyncIterable(this._generator, this._args);

  // TODO(jmesserly): this should be [Symbol.iterator]() method. Unfortunately
  // we have no way of telling the compiler yet, so it will generate an extra
  // layer of indirection that wraps the SyncIterator.
  _jsIterator() => JS('', '#(...#)', _generator, _args);

  Iterator<E> get iterator => new SyncIterator<E>(_jsIterator());
}
