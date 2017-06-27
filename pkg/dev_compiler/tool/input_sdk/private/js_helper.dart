// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_helper;

import 'dart:collection';

import 'dart:_debugger' show stackTraceMapper;

import 'dart:_foreign_helper' show JS, JS_STRING_CONCAT;

import 'dart:_interceptors';
import 'dart:_internal'
    show EfficientLengthIterable, MappedIterable, IterableElementError;

import 'dart:_native_typed_data';
import 'dart:_runtime' as dart;

part 'annotations.dart';
part 'linked_hash_map.dart';
part 'native_helper.dart';
part 'regexp_helper.dart';
part 'string_helper.dart';
part 'js_rti.dart';

final _identityHashCode = JS('', 'Symbol("_identityHashCode")');

class _Patch {
  const _Patch();
}

const _Patch patch = const _Patch();

/// Marks the internal map in dart2js, so that internal libraries can is-check
// them.
abstract class InternalMap<K, V> implements Map<K, V> {}

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
    int hash = JS('int|Null', r'#[#]', object, _identityHashCode);
    if (hash == null) {
      hash = JS('int', '(Math.random() * 0x3fffffff) | 0');
      JS('void', r'#[#] = #', object, _identityHashCode, hash);
    }
    return JS('int', '#', hash);
  }

  @NoInline()
  static int _parseIntError(String source, int handleError(String source)) {
    if (handleError == null) throw new FormatException(source);
    return handleError(source);
  }

  static int parseInt(
      String source, int radix, int handleError(String source)) {
    checkString(source);
    var re = JS('', r'/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i');
    var/*=JSArray<String>*/ match =
        JS('JSExtendableArray|Null', '#.exec(#)', re, source);
    int digitsIndex = 1;
    int hexIndex = 2;
    int decimalIndex = 3;
    int nonDecimalHexIndex = 4;
    if (match == null) {
      // TODO(sra): It might be that the match failed due to unrecognized U+0085
      // spaces.  We could replace them with U+0020 spaces and try matching
      // again.
      return _parseIntError(source, handleError);
    }
    String decimalMatch = match[decimalIndex];
    if (radix == null) {
      if (decimalMatch != null) {
        // Cannot fail because we know that the digits are all decimal.
        return JS('int', r'parseInt(#, 10)', source);
      }
      if (match[hexIndex] != null) {
        // Cannot fail because we know that the digits are all hex.
        return JS('int', r'parseInt(#, 16)', source);
      }
      return _parseIntError(source, handleError);
    }

    if (radix is! int) {
      throw new ArgumentError.value(radix, 'radix', 'is not an integer');
    }
    if (radix < 2 || radix > 36) {
      throw new RangeError.range(radix, 2, 36, 'radix');
    }
    if (radix == 10 && decimalMatch != null) {
      // Cannot fail because we know that the digits are all decimal.
      return JS('int', r'parseInt(#, 10)', source);
    }
    // If radix >= 10 and we have only decimal digits the string is safe.
    // Otherwise we need to check the digits.
    if (radix < 10 || decimalMatch == null) {
      // We know that the characters must be ASCII as otherwise the
      // regexp wouldn't have matched. Lowercasing by doing `| 0x20` is thus
      // guaranteed to be a safe operation, since it preserves digits
      // and lower-cases ASCII letters.
      int maxCharCode;
      if (radix <= 10) {
        // Allow all digits less than the radix. For example 0, 1, 2 for
        // radix 3.
        // "0".codeUnitAt(0) + radix - 1;
        maxCharCode = (0x30 - 1) + radix;
      } else {
        // Letters are located after the digits in ASCII. Therefore we
        // only check for the character code. The regexp above made already
        // sure that the string does not contain anything but digits or
        // letters.
        // "a".codeUnitAt(0) + (radix - 10) - 1;
        maxCharCode = (0x61 - 10 - 1) + radix;
      }
      assert(match[digitsIndex] is String);
      String digitsPart = JS('String', '#[#]', match, digitsIndex);
      for (int i = 0; i < digitsPart.length; i++) {
        int characterCode = digitsPart.codeUnitAt(i) | 0x20;
        if (characterCode > maxCharCode) {
          return _parseIntError(source, handleError);
        }
      }
    }
    // The above matching and checks ensures the source has at least one digits
    // and all digits are suitable for the radix, so parseInt cannot return NaN.
    return JS('int', r'parseInt(#, #)', source, radix);
  }

  @NoInline()
  static double _parseDoubleError(
      String source, double handleError(String source)) {
    if (handleError == null) {
      throw new FormatException('Invalid double', source);
    }
    return handleError(source);
  }

  static double parseDouble(String source, double handleError(String source)) {
    checkString(source);
    // Notice that JS parseFloat accepts garbage at the end of the string.
    // Accept only:
    // - [+/-]NaN
    // - [+/-]Infinity
    // - a Dart double literal
    // We do allow leading or trailing whitespace.
    if (!JS(
        'bool',
        r'/^\s*[+-]?(?:Infinity|NaN|'
        r'(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(#)',
        source)) {
      return _parseDoubleError(source, handleError);
    }
    var result = JS('num', r'parseFloat(#)', source);
    if (result.isNaN) {
      var trimmed = source.trim();
      if (trimmed == 'NaN' || trimmed == '+NaN' || trimmed == '-NaN') {
        return result;
      }
      return _parseDoubleError(source, handleError);
    }
    return result;
  }

  /** [: r"$".codeUnitAt(0) :] */
  static const int DOLLAR_CHAR_VALUE = 36;

  static String objectToString(Object object) {
    String name = dart.typeName(dart.getReifiedType(object));
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
    return JS(
        'bool',
        'typeof version == "function"'
        ' && typeof os == "object" && "system" in os');
  }

  static bool get isJsshell {
    return JS(
        'bool', 'typeof version == "function" && typeof system == "function"');
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
    const kMaxApply = 500;
    int end = array.length;
    if (end <= kMaxApply) {
      return JS('String', r'String.fromCharCode.apply(null, #)', array);
    }
    String result = '';
    for (int i = 0; i < end; i += kMaxApply) {
      int chunkEnd = (i + kMaxApply < end) ? i + kMaxApply : end;
      result = JS(
          'String',
          r'# + String.fromCharCode.apply(null, #.slice(#, #))',
          result,
          array,
          i,
          chunkEnd);
    }
    return result;
  }

  static String stringFromCodePoints(/*=JSArray<int>*/ codePoints) {
    List<int> a = <int>[];
    for (var i in codePoints) {
      if (i is! int) throw argumentErrorValue(i);
      if (i <= 0xffff) {
        a.add(i);
      } else if (i <= 0x10ffff) {
        a.add(0xd800 + ((((i - 0x10000) >> 10) & 0x3ff)));
        a.add(0xdc00 + (i & 0x3ff));
      } else {
        throw argumentErrorValue(i);
      }
    }
    return _fromCharCodeApply(a);
  }

  static String stringFromCharCodes(/*=JSArray<int>*/ charCodes) {
    for (var i in charCodes) {
      if (i is! int) throw argumentErrorValue(i);
      if (i < 0) throw argumentErrorValue(i);
      if (i > 0xffff) return stringFromCodePoints(charCodes);
    }
    return _fromCharCodeApply(charCodes);
  }

  // [start] and [end] are validated.
  static String stringFromNativeUint8List(
      NativeUint8List charCodes, int start, int end) {
    const kMaxApply = 500;
    if (end <= kMaxApply && start == 0 && end == charCodes.length) {
      return JS('String', r'String.fromCharCode.apply(null, #)', charCodes);
    }
    String result = '';
    for (int i = start; i < end; i += kMaxApply) {
      int chunkEnd = (i + kMaxApply < end) ? i + kMaxApply : end;
      result = JS(
          'String',
          r'# + String.fromCharCode.apply(null, #.subarray(#, #))',
          result,
          charCodes,
          i,
          chunkEnd);
    }
    return result;
  }

  static String stringFromCharCode(int charCode) {
    if (0 <= charCode) {
      if (charCode <= 0xffff) {
        return JS('String', 'String.fromCharCode(#)', charCode);
      }
      if (charCode <= 0x10ffff) {
        var bits = charCode - 0x10000;
        var low = 0xDC00 | (bits & 0x3ff);
        var high = 0xD800 | (bits >> 10);
        return JS('String', 'String.fromCharCode(#, #)', high, low);
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

  static String getTimeZoneName(DateTime receiver) {
    // Firefox and Chrome emit the timezone in parenthesis.
    // Example: "Wed May 16 2012 21:13:00 GMT+0200 (CEST)".
    // We extract this name using a regexp.
    var d = lazyAsJsDate(receiver);
    List match = JS('JSArray|Null', r'/\((.*)\)/.exec(#.toString())', d);
    if (match != null) return match[1];

    // Internet Explorer 10+ emits the zone name without parenthesis:
    // Example: Thu Oct 31 14:07:44 PDT 2013
    match = JS(
        'JSArray|Null',
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

  static int getTimeZoneOffsetInMinutes(DateTime receiver) {
    // Note that JS and Dart disagree on the sign of the offset.
    return -JS('int', r'#.getTimezoneOffset()', lazyAsJsDate(receiver));
  }

  static num valueFromDecomposedDate(int years, int month, int day, int hours,
      int minutes, int seconds, int milliseconds, bool isUtc) {
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
    num value;
    if (isUtc) {
      value = JS('num', r'Date.UTC(#, #, #, #, #, #, #)', years, jsMonth, day,
          hours, minutes, seconds, milliseconds);
    } else {
      value = JS('num', r'new Date(#, #, #, #, #, #, #).valueOf()', years,
          jsMonth, day, hours, minutes, seconds, milliseconds);
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
  static lazyAsJsDate(DateTime receiver) {
    if (JS('bool', r'#.date === (void 0)', receiver)) {
      JS('void', r'#.date = new Date(#)', receiver,
          receiver.millisecondsSinceEpoch);
    }
    return JS('var', r'#.date', receiver);
  }

  // The getters for date and time parts below add a positive integer to ensure
  // that the result is really an integer, because the JavaScript implementation
  // may return -0.0 instead of 0.

  static getYear(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('int', r'(#.getUTCFullYear() + 0)', lazyAsJsDate(receiver))
        : JS('int', r'(#.getFullYear() + 0)', lazyAsJsDate(receiver));
  }

  static getMonth(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('int', r'#.getUTCMonth() + 1', lazyAsJsDate(receiver))
        : JS('int', r'#.getMonth() + 1', lazyAsJsDate(receiver));
  }

  static getDay(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('int', r'(#.getUTCDate() + 0)', lazyAsJsDate(receiver))
        : JS('int', r'(#.getDate() + 0)', lazyAsJsDate(receiver));
  }

  static getHours(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('int', r'(#.getUTCHours() + 0)', lazyAsJsDate(receiver))
        : JS('int', r'(#.getHours() + 0)', lazyAsJsDate(receiver));
  }

  static getMinutes(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('int', r'(#.getUTCMinutes() + 0)', lazyAsJsDate(receiver))
        : JS('int', r'(#.getMinutes() + 0)', lazyAsJsDate(receiver));
  }

  static getSeconds(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('int', r'(#.getUTCSeconds() + 0)', lazyAsJsDate(receiver))
        : JS('int', r'(#.getSeconds() + 0)', lazyAsJsDate(receiver));
  }

  static getMilliseconds(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('int', r'(#.getUTCMilliseconds() + 0)', lazyAsJsDate(receiver))
        : JS('int', r'(#.getMilliseconds() + 0)', lazyAsJsDate(receiver));
  }

  static getWeekday(DateTime receiver) {
    int weekday = (receiver.isUtc)
        ? JS('int', r'#.getUTCDay() + 0', lazyAsJsDate(receiver))
        : JS('int', r'#.getDay() + 0', lazyAsJsDate(receiver));
    // Adjust by one because JS weeks start on Sunday.
    return (weekday + 6) % 7 + 1;
  }

  static valueFromDateString(str) {
    if (str is! String) throw argumentErrorValue(str);
    var value = JS('num', r'Date.parse(#)', str);
    if (value.isNaN) throw argumentErrorValue(str);
    return value;
  }

  static getProperty(object, key) {
    if (object == null || object is bool || object is num || object is String) {
      throw argumentErrorValue(object);
    }
    return JS('var', '#[#]', object, key);
  }

  static void setProperty(object, key, value) {
    if (object == null || object is bool || object is num || object is String) {
      throw argumentErrorValue(object);
    }
    JS('void', '#[#] = #', object, key, value);
  }

  static StackTrace extractStackTrace(Error error) =>
      getTraceFromException(error);
}

/**
 * Diagnoses an indexing error. Returns the ArgumentError or RangeError that
 * describes the problem.
 */
@NoInline()
Error diagnoseIndexError(indexable, index) {
  if (index is! int) return new ArgumentError.value(index, 'index');
  int length = indexable.length;
  // The following returns the same error that would be thrown by calling
  // [RangeError.checkValidIndex] with no optional parameters provided.
  if (index < 0 || index >= length) {
    return new RangeError.index(index, indexable, 'index', null, length);
  }
  // The above should always match, but if it does not, use the following.
  return new RangeError.value(index, 'index');
}

/**
 * Diagnoses a range error. Returns the ArgumentError or RangeError that
 * describes the problem.
 */
@NoInline()
Error diagnoseRangeError(start, end, length) {
  if (start is! int) {
    return new ArgumentError.value(start, 'start');
  }
  if (start < 0 || start > length) {
    return new RangeError.range(start, 0, length, 'start');
  }
  if (end != null) {
    if (end is! int) {
      return new ArgumentError.value(end, 'end');
    }
    if (end < start || end > length) {
      return new RangeError.range(end, start, length, 'end');
    }
  }
  // The above should always match, but if it does not, use the following.
  return new ArgumentError.value(end, "end");
}

stringLastIndexOfUnchecked(receiver, element, start) =>
    JS('int', r'#.lastIndexOf(#, #)', receiver, element, start);

/// 'factory' for constructing ArgumentError.value to keep the call sites small.
@NoInline()
ArgumentError argumentErrorValue(object) {
  return new ArgumentError.value(object);
}

checkNull(object) {
  if (object == null) throw argumentErrorValue(object);
  return object;
}

checkNum(value) {
  if (value is! num) throw argumentErrorValue(value);
  return value;
}

checkInt(value) {
  if (value is! int) throw argumentErrorValue(value);
  return value;
}

checkBool(value) {
  if (value is! bool) throw argumentErrorValue(value);
  return value;
}

checkString(value) {
  if (value is! String) throw argumentErrorValue(value);
  return value;
}

throwRuntimeError(message) {
  throw new RuntimeError(message);
}

throwAbstractClassInstantiationError(className) {
  throw new AbstractClassInstantiationError(className);
}

@NoInline()
throwConcurrentModificationError(collection) {
  throw new ConcurrentModificationError(collection);
}

class NullError extends Error implements NoSuchMethodError {
  final String _message;
  final String _method;

  NullError(this._message, match)
      : _method = match == null ? null : JS('', '#.method', match);

  String toString() {
    if (_method == null) return 'NullError: $_message';
    return "NullError: method not found: '$_method' on null";
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
      return "NoSuchMethodError: method not found: '$_method' ($_message)";
    }
    return "NoSuchMethodError: "
        "method not found: '$_method' on '$_receiver' ($_message)";
  }
}

class UnknownJsTypeError extends Error {
  final String _message;

  UnknownJsTypeError(this._message);

  String toString() => _message.isEmpty ? 'Error' : 'Error: $_message';
}

/**
 * Called by generated code to fetch the stack trace from a Dart
 * exception. Should never return null.
 */
final _stackTrace = JS('', 'Symbol("_stackTrace")');
StackTrace getTraceFromException(exception) {
  var error = JS('', 'dart.recordJsError(#)', exception);
  var trace = JS('StackTrace', '#[#]', error, _stackTrace);
  if (trace != null) return trace;
  trace = new _StackTrace(error);
  JS('', '#[#] = #', error, _stackTrace, trace);
  return trace;
}

class _StackTrace implements StackTrace {
  var _exception;
  String _trace;

  _StackTrace(this._exception);

  String toString() {
    if (_trace != null) return _trace;

    String trace;
    if (JS('bool', '# !== null', _exception) &&
        JS('bool', 'typeof # === "object"', _exception)) {
      trace = JS("String|Null", r"#.stack", _exception);
      if (trace != null && stackTraceMapper != null) {
        trace = stackTraceMapper(trace);
      }
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
 *     class Document native "*Foo" {
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
abstract class JavaScriptIndexingBehavior<E> {}

// TODO(lrn): These exceptions should be implemented in core.
// When they are, remove the 'Implementation' here.

/** Thrown by type assertions that fail. */
class TypeErrorImplementation extends Error implements TypeError {
  final String message;

  /**
   * Normal type error caused by a failed subtype test.
   */
  // TODO(sra): Include [value] in message.
  TypeErrorImplementation(Object value, Object actualType, Object expectedType)
      : message = "Type '${actualType}' is not a subtype "
            "of type '${expectedType}'";

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
  // TODO(sra): Include [value] in message.
  CastErrorImplementation(Object value, Object actualType, Object expectedType)
      : message = "CastError: Casting value of type '$actualType' to"
            " incompatible type '$expectedType'";

  String toString() => message;
}

/// Thrown by type assertions that fail in strong mode that would have passed in
/// standard Dart.
class StrongModeTypeError extends Error implements TypeError, StrongModeError {
  final String message;
  // TODO(sra): Include [value] in message.
  StrongModeTypeError(Object value, Object actualType, Object expectedType)
      : message = "Type '${actualType}' is not a subtype "
            "of type '${expectedType}' in strong mode";
  String toString() => message;
}

/// Thrown by casts that fail in strong mode that would have passed in standard
/// Dart.
class StrongModeCastError extends Error implements CastError, StrongModeError {
  final String message;
  // TODO(sra): Include [value] in message.
  StrongModeCastError(Object value, Object actualType, Object expectedType)
      : message = "CastError: Casting value of type '$actualType' to"
            " type '$expectedType' which is incompatible in strong mode";
  String toString() => message;
}

/// Used for Strong-mode errors other than type assertions and casts.
class StrongModeErrorImplementation extends Error implements StrongModeError {
  final String message;
  StrongModeErrorImplementation(this.message);
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
 * Error thrown when an assert() fails with a message:
 *
 *     assert(false, "Message here");
 */
class AssertionErrorWithMessage extends AssertionError {
  final Object _message;
  AssertionErrorWithMessage(this._message);
  String toString() => "Assertion failed: ${_message}";
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

// TODO(jmesserly): this adapter is to work around
// https://github.com/dart-lang/sdk/issues/28320
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

class BooleanConversionAssertionError extends AssertionError {
  toString() => 'Failed assertion: boolean expression must not be null';
}
