// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _js_helper;

import 'dart:collection';
import 'dart:collection-dev';
import 'dart:_foreign_helper' show DART_CLOSURE_TO_JS,
                                   JS,
                                   JS_CALL_IN_ISOLATE,
                                   JS_CURRENT_ISOLATE,
                                   JS_OPERATOR_IS_PREFIX,
                                   JS_HAS_EQUALS,
                                   RAW_DART_FUNCTION_REF,
                                   UNINTERCEPTED;

part 'constant_map.dart';
part 'native_helper.dart';
part 'regexp_helper.dart';
part 'string_helper.dart';

bool isJsArray(var value) {
  return value != null && JS('bool', r'#.constructor === Array', value);
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
  if (value is String) return value;
  if ((value is num && value != 0) || value is bool) {
    return JS('String', r'String(#)', value);
  }
  if (value == null) return 'null';
  var res = value.toString();
  if (res is !String) throw new ArgumentError(value);
  return res;
}

createInvocationMirror(name, internalName, type, arguments, argumentNames) =>
    new JSInvocationMirror(name, internalName, type, arguments, argumentNames);

class JSInvocationMirror implements InvocationMirror {
  static const METHOD = 0;
  static const GETTER = 1;
  static const SETTER = 2;

  final String memberName;
  final String _internalName;
  final int _kind;
  final List _arguments;
  final List _namedArgumentNames;
  /** Map from argument name to index in _arguments. */
  Map<String,dynamic> _namedIndices = null;

  JSInvocationMirror(this.memberName,
                     this._internalName,
                     this._kind,
                     this._arguments,
                     this._namedArgumentNames);

  bool get isMethod => _kind == METHOD;
  bool get isGetter => _kind == GETTER;
  bool get isSetter => _kind == SETTER;
  bool get isAccessor => _kind != METHOD;

  List get positionalArguments {
    if (isGetter) return null;
    var list = [];
    var argumentCount =
        _arguments.length - _namedArgumentNames.length;
    for (var index = 0 ; index < argumentCount ; index++) {
      list.add(_arguments[index]);
    }
    return list;
  }

  Map<String,dynamic> get namedArguments {
    if (isAccessor) return null;
    var map = <String,dynamic>{};
    int namedArgumentCount = _namedArgumentNames.length;
    int namedArgumentsStartIndex = _arguments.length - namedArgumentCount;
    for (int i = 0; i < namedArgumentCount; i++) {
      map[_namedArgumentNames[i]] = _arguments[namedArgumentsStartIndex + i];
    }
    return map;
  }

  invokeOn(Object object) {
    List arguments = _arguments;
    if (!isJsArray(arguments)) arguments = new List.from(arguments);
    return JS("var", "#[#].apply(#, #)",
              object, _internalName, object, arguments);
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
    if (JS('bool', r'typeof dartPrint == "function"')) {
      // Support overriding print from JavaScript.
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

  static void _throwFormatException(String string) {
    throw new FormatException(string);
  }

  static int parseInt(String source,
                      int radix,
                      int handleError(String source)) {
    if (handleError == null) handleError = _throwFormatException;

    checkString(source);
    var match = JS('=List|Null',
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
          return JS('num', r'parseInt(#, 16)', source);
        }
        if (match[decimalIndex] != null) {
          // Cannot fail because we know that the digits are all decimal.
          return JS('num', r'parseInt(#, 10)', source);
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
          return JS('num', r'parseInt(#, 10)', source);
        }
        if (radix < 10 || match[decimalIndex] == null) {
          // We know that the characters must be ASCII as otherwise the
          // regexp wouldn't have matched. Calling toLowerCase is thus
          // guaranteed to be a safe operation. If it wasn't ASCII, then
          // "İ" would become "i", and we would accept it for radices greater
          // than 18.
          int maxCharCode;
          if (radix <= 10) {
            // Allow all digits less than the radix. For example 0, 1, 2 for
            // radix 3.
            // "0".charCodeAt(0) + radix - 1;
            maxCharCode = 0x30 + radix - 1;
          } else {
            // Characters are located after the digits in ASCII. Therefore we
            // only check for the character code. The regexp above made already
            // sure that the string does not contain anything but digits or
            // characters.
            // "0".charCodeAt(0) + radix - 1;
            maxCharCode = 0x61 + radix - 10 - 1;
          }
          String digitsPart = match[digitsIndex].toLowerCase();
          for (int i = 0; i < digitsPart.length; i++) {
            if (digitsPart.charCodeAt(i) > maxCharCode) {
              return handleError(source);
            }
          }
        }
      }
    }
    if (match == null) return handleError(source);
    return JS('num', r'parseInt(#, #)', source, radix);
  }

  static double parseDouble(String source, int handleError(String source)) {
    checkString(source);
    if (handleError == null) handleError = _throwFormatException;
    // Notice that JS parseFloat accepts garbage at the end of the string.
    // Accept only:
    // - NaN
    // - [+/-]Infinity
    // - a Dart double literal
    // We do not allow leading or trailing whitespace.
    if (!JS('bool',
            r'/^\s*(?:NaN|[+-]?(?:Infinity|'
                r'(?:\.\d+|\d+(?:\.\d+)?)(?:[eE][+-]?\d+)?))\s*$/.test(#)',
            source)) {
      return handleError(source);
    }
    var result = JS('num', r'parseFloat(#)', source);
    if (result.isNaN && source != 'NaN') {
      return handleError(source);
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

  static List newGrowableList(length) {
    return JS('=List', r'new Array(#)', length);
  }

  static List newFixedList(length) {
    var result = JS('=List', r'new Array(#)', length);
    JS('void', r'#.fixed$length = #', result, true);
    return result;
  }

  static num dateNow() => JS('num', r'Date.now()');

  static num numMicroseconds() {
    if (JS('bool', 'typeof window != "undefined" && window !== null')) {
      var performance = JS('var', 'window.performance');
      if (performance != null &&
          JS('bool', 'typeof #.webkitNow == "function"', performance)) {
        return (1000 * JS('num', '#.webkitNow()', performance)).floor();
      }
    }
    return 1000 * dateNow();
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
        subarray = JS('=List', r'#.slice(#, #)', array,
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

  static applyFunction(Function function,
                       List positionalArguments,
                       Map<String, dynamic> namedArguments) {
    int argumentCount = 0;
    StringBuffer buffer = new StringBuffer();
    List arguments = [];

    if (positionalArguments != null) {
      argumentCount += positionalArguments.length;
      arguments.addAll(positionalArguments);
    }

    // Sort the named arguments to get the right selector name and
    // arguments order.
    if (namedArguments != null && !namedArguments.isEmpty) {
      // Call new List.from to make sure we get a JavaScript array.
      List<String> listOfNamedArguments =
          new List<String>.from(namedArguments.keys);
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
      throw new NoSuchMethodError(function, selectorName, arguments, {});
    }
    // We bound 'this' to [function] because of how we compile
    // closures: escaped local variables are stored and accessed through
    // [function].
    return JS('var', '#.apply(#, #)', jsFunction, function, arguments);
  }

  static getConstructor(String className) {
    // TODO(ahe): How to safely access $?
    return JS('var', r'$[#]', className);
  }

  static bool identicalImplementation(a, b) {
    return JS('bool', '# == null', a)
      ? JS('bool', '# == null', b)
      : JS('bool', '# === #', a, b);
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
  throw new RangeError.value(index);
}

listInsertRange(receiver, start, length, initialValue) {
  if (length == 0) {
    return;
  }
  if (length is !int) throw new ArgumentError(length);
  if (length < 0) throw new ArgumentError(length);
  if (start is !int) throw new ArgumentError(start);

  var receiverLength = JS('num', r'#.length', receiver);
  if (start < 0 || start > receiverLength) {
    throw new RangeError.value(start);
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

class MathNatives {
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
 * Wrap the given Dart object and record a stack trace.
 *
 * The code in [unwrapException] deals with getting the original Dart
 * object out of the wrapper again.
 */
$throw(ex) {
  if (ex == null) ex = const NullThrownError();
  var wrapper = new DartError(ex);

  if (JS('bool', '!!Error.captureStackTrace')) {
    // Use V8 API for recording a "fast" stack trace (this installs a
    // "stack" property getter on [wrapper]).
    JS('void', r'Error.captureStackTrace(#, #)',
       wrapper, RAW_DART_FUNCTION_REF($throw));
  } else {
    // Otherwise, produce a stack trace and record it in the wrapper.
    // This is a slower way to create a stack trace which works on
    // some browsers, but may simply evaluate to null.
    String stackTrace = JS('', 'new Error().stack');
    JS('void', '#.stack = #', wrapper, stackTrace);
  }
  return wrapper;
}

/**
 * Wrapper class for throwing exceptions.
 */
class DartError {
  /// The Dart object (or primitive JavaScript value) which was thrown is
  /// attached to this object as a field named 'dartException'.  We do this
  /// only in raw JS so that we can use the 'in' operator and so that the
  /// minifier does not rename the field.  Therefore it is not declared as a
  /// real field.

  DartError(var dartException) {
    JS('void', '#.dartException = #', this, dartException);
    // Install a toString method that the JavaScript system will call
    // to format uncaught exceptions.
    JS('void', '#.toString = #', this, DART_CLOSURE_TO_JS(toStringWrapper));
  }

  /**
   * V8/Chrome installs a property getter, "stack", when calling
   * Error.captureStackTrace (see [$throw]). In [$throw], we make sure
   * that this property is always set.
   */
  String get stack => JS('', '#.stack', this);

  /**
   * This method can be invoked by calling toString from
   * JavaScript. See the constructor of this class.
   *
   * We only expect this method to be called (indirectly) by the
   * browser when an uncaught exception occurs. Instance of this class
   * should never escape into Dart code (except for [$throw] above).
   */
  String toString() {
    // If Error.captureStackTrace is available, accessing stack from
    // this method would cause recursion because the stack property
    // (on this object) is actually a getter which calls toString on
    // this object (via the wrapper installed in this class'
    // constructor). Fortunately, both Chrome and d8 prints the stack
    // trace and Chrome even applies source maps to the stack
    // trace. Remeber, this method is only ever invoked by the browser
    // when an uncaught exception occurs.
    var dartException = JS('var', r'#.dartException', this);
    if (JS('bool', '!!Error.captureStackTrace') || (stack == null)) {
      return dartException.toString();
    } else {
      return '$dartException\n$stack';
    }
  }

  /**
   * This method is installed as JavaScript toString method on
   * [DartError].  So JavaScript 'this' binds to an instance of
   * DartError.
   */
  static toStringWrapper() => JS('', r'this').toString();
}

makeLiteralListConst(list) {
  JS('bool', r'#.immutable$list = #', list, true);
  JS('bool', r'#.fixed$length = #', list, true);
  return list;
}

throwRuntimeError(message) {
  throw new RuntimeError(message);
}

/**
 * The SSA builder generates a call to this method when a malformed type is used
 * in a subtype test.
 */
throwMalformedSubtypeError(value, type, reasons) {
  throw new TypeErrorImplementation.malformedSubtype(value, type, reasons);
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
    return JS('', r'#.dartException', ex);
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
    if (contains(message, 'JSNull') ||
        type == 'property_not_function' ||
        type == 'called_non_callable' ||
        type == 'non_object_property_call' ||
        type == 'non_object_property_load') {
      return new NoSuchMethodError(null, name, [], {});
    } else if (type == 'undefined_method') {
      return new NoSuchMethodError('', name, [], {});
    }

    var ieErrorCode = JS('int', '#.number & 0xffff', ex);
    var ieFacilityNumber = JS('int', '#.number>>16 & 0x1FFF', ex);
    // If we cannot use [type] to determine what kind of exception
    // we're dealing with we fall back on looking at the exception
    // message if it is available and a string.
    if (message is String) {
      if (message.endsWith('is null') ||
          message.endsWith('is undefined') ||
          message.endsWith('is null or undefined') ||
          message.endsWith('of undefined') ||
          message.endsWith('of null')) {
        return new NoSuchMethodError(null, '<unknown>', [], {});
      } else if (contains(message, ' has no method ') ||
                 contains(message, ' is not a function') ||
                 (ieErrorCode == 438 && ieFacilityNumber == 10)) {
        // Examples:
        //  x.foo is not a function
        //  'undefined' is not a function (evaluating 'x.foo(1,2,3)')
        // Object doesn't support property or method 'foo' which sets the error
        // code 438 in IE.
        // TODO(kasperl): Compute the right name if possible.
        return new NoSuchMethodError('', '<unknown>', [], {});
      }
    }

    // If we cannot determine what kind of error this is, we fall back
    // to reporting this as a generic exception. It's probably better
    // than nothing.
    return new Exception(message is String ? message : '');
  }

  if (JS('bool', r'# instanceof RangeError', ex)) {
    if (message is String && contains(message, 'call stack')) {
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
  Iterator iterator = keyValuePairs.iterator;
  Map result = new LinkedHashMap();
  while (iterator.moveNext()) {
    String key = iterator.current;
    iterator.moveNext();
    var value = iterator.current;
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
  // By fetching the current isolate before creating the JavaScript
  // function, we prevent the compiler from inlining its use in
  // the JavaScript function below (the compiler generates code for
  // fetching the isolate before creating the JavaScript function).
  // If it was inlined, the JavaScript function would not get the
  // current isolate, but the one that is active when the callback
  // executes.
  var currentIsolate = JS_CURRENT_ISOLATE();

  // We use $0 and $1 to not clash with variable names used by the
  // compiler and/or minifier.
  function = JS("var",
                r"""function($0, $1) { return #(#, #, #, $0, $1); }""",
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
 * * `=List`. This means 'exactly List', which is the JavaScript Array
 *   implementation of [List] and no other implementation.
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
 *     @Returns('String|num|=List')
 *     dynamic key;
 *
 *     // Equivalent:
 *     @Returns('String') @Returns('num') @Returns('=List')
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
  assert(typeInfo == null || isJsArray(typeInfo));
  // We have to check for null because factories may return null.
  if (target != null) JS('var', r'#.$builtinTypeInfo = #', target, typeInfo);
}

getRuntimeTypeInfo(target) {
  if (target == null) return null;
  var res = JS('var', r'#.$builtinTypeInfo', target);
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

voidTypeCheck(value) {
  if (value == null) return value;
  throw new TypeErrorImplementation(value, 'void');
}

malformedTypeCheck(value, type, reasons) {
  if (value == null) return value;
  throwMalformedSubtypeError(value, type, reasons);
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

  /**
   * Normal type error caused by a failed subtype test.
   */
  TypeErrorImplementation(Object value, String type)
      : message = "type '${Primitives.objectTypeName(value)}' is not a subtype "
                  "of type '$type'";

  /**
   * Type error caused by a subtype test on a malformed type.
   */
  TypeErrorImplementation.malformedSubtype(Object value,
                                           String type, String reasons)
      : message = "type '${Primitives.objectTypeName(value)}' is not a subtype "
                  "of type '$type' because '$type' is malformed: $reasons.";

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
void throwNoSuchMethod(obj, name, arguments, expectedArgumentNames) {
  throw new NoSuchMethodError(obj, name, arguments, const {},
                              expectedArgumentNames);
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
  int get hashCode => typeName.hashCode;
  bool operator ==(other) {
    if (other is !TypeImpl) return false;
    return typeName == other.typeName;
  }
}

String getClassName(var object) {
  return JS('String', r'#.constructor.builtin$cls', object);
}

String getTypeArgumentAsString(List runtimeType) {
  String className = getConstructorName(runtimeType[0]);
  if (runtimeType.length == 1) return className;
  return '$className<${joinArguments(runtimeType, 1)}>';
}

String getConstructorName(type) => JS('String', r'#.builtin$cls', type);

String runtimeTypeToString(type) {
  if (type == null) {
    return 'dynamic';
  } else if (isJsArray(type)) {
    // A list representing a type with arguments.
    return getTypeArgumentAsString(type);
  } else {
    // A reference to the constructor.
    return getConstructorName(type);
  }
}

String joinArguments(var types, int startIndex) {
  bool firstArgument = true;
  StringBuffer buffer = new StringBuffer();
  for (int index = startIndex; index < types.length; index++) {
    if (firstArgument) {
      firstArgument = false;
    } else {
      buffer. add(', ');
    }
    var argument = types[index];
    buffer.add(runtimeTypeToString(argument));
  }
  return buffer.toString();
}

String getRuntimeTypeString(var object) {
  String className = isJsArray(object) ? 'List' : getClassName(object);
  var typeInfo = JS('var', r'#.$builtinTypeInfo', object);
  if (typeInfo == null) return className;
  return "$className<${joinArguments(typeInfo, 0)}>";
}

/**
 * Check whether the type represented by [s] is a subtype of the type
 * represented by [t].
 *
 * Type representations can be:
 *  1) a JavaScript constructor for a class C: the represented type is the raw
 *     type C.
 *  2) a JavaScript object: this represents a class for which there is no
 *     JavaScript constructor, because it is only used in type arguments or it
 *     is native. The represented type is the raw type of this class.
 *  3) a JavaScript array: the first entry is of type 1 or 2 and identifies the
 *     class of the type and the rest of the array are the type arguments.
 *  4) [:null:]: the dynamic type.
 */
bool isSubtype(var s, var t) {
  // If either type is dynamic, [s] is a subtype of [t].
  if (JS('bool', '# == null', s) || JS('bool', '# == null', t)) return true;
  // Subtyping is reflexive.
  if (JS('bool', '# === #', s, t)) return true;
  // Get the object describing the class and check for the subtyping flag
  // constructed from the type of [t].
  var typeOfS = isJsArray(s) ? s[0] : s;
  var typeOfT = isJsArray(t) ? t[0] : t;
  var test = '${JS_OPERATOR_IS_PREFIX()}${runtimeTypeToString(typeOfT)}';
  if (JS('var', r'#[#]', typeOfS, test) == null) return false;
  // The class of [s] is a subclass of the class of [t]. If either of the types
  // is raw, [s] is a subtype of [t].
  if (!isJsArray(s) || !isJsArray(t)) return true;
  // Recursively check the type arguments.
  int len = s.length;
  if (len != t.length) return false;
  for (int i = 1; i < len; i++) {
    if (!isSubtype(s[i], t[i])) {
      return false;
    }
  }
  return true;
}

createRuntimeType(String name) => new TypeImpl(name);
