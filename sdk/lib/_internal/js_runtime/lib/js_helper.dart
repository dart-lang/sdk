// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _js_helper;

import 'dart:_js_embedded_names'
    show
        CURRENT_SCRIPT,
        DEFERRED_LIBRARY_PARTS,
        DEFERRED_PART_URIS,
        DEFERRED_PART_HASHES,
        GET_ISOLATE_TAG,
        INITIALIZE_LOADED_HUNK,
        INTERCEPTORS_BY_TAG,
        IS_HUNK_LOADED,
        IS_HUNK_INITIALIZED,
        LEAF_TAGS,
        NATIVE_SUPERCLASS_TAG_NAME,
        RUNTIME_METRICS,
        STARTUP_METRICS,
        STATIC_FUNCTION_NAME_PROPERTY_NAME,
        TearOffParametersPropertyNames;

import 'dart:_js_shared_embedded_names' show JsBuiltin, JsGetName;

import 'dart:collection';

import 'dart:convert' show jsonDecode;

import 'dart:async' show Completer, DeferredLoadException, Future, Zone;

import 'dart:_foreign_helper'
    show
        DART_CLOSURE_TO_JS,
        getInterceptor,
        JS,
        JS_BUILTIN,
        JS_CONST,
        JS_EFFECT,
        JS_EMBEDDED_GLOBAL,
        JS_GET_FLAG,
        JS_GET_NAME,
        JS_INTERCEPTOR_CONSTANT,
        JS_STRING_CONCAT,
        RAW_DART_FUNCTION_REF;

import 'dart:_interceptors';
import 'dart:_internal' as _symbol_dev;
import 'dart:_internal'
    show
        EfficientLengthIterable,
        MappedIterable,
        IterableElementError,
        SubListIterable;

import 'dart:_native_typed_data';

import 'dart:_js_names' show unmangleGlobalNameIfPreservedAnyways;

import 'dart:_rti' as newRti
    show
        createRuntimeType,
        evalInInstance,
        getRuntimeType,
        getTypeFromTypesTable,
        instanceTypeName,
        instantiatedGenericFunctionType,
        throwTypeError;

import 'dart:_load_library_priority';

part 'annotations.dart';
part 'constant_map.dart';
part 'instantiation.dart';
part 'native_helper.dart';
part 'regexp_helper.dart';
part 'string_helper.dart';
part 'linked_hash_map.dart';

/// Marks the internal map in dart2js, so that internal libraries can is-check
/// them.
abstract class InternalMap {}

/// Given a raw constructor name, return the unminified name, if available,
/// otherwise tag the name with `minified:`.
String unminifyOrTag(String rawClassName) {
  String? preserved = unmangleGlobalNameIfPreservedAnyways(rawClassName);
  if (preserved != null) return preserved;
  if (JS_GET_FLAG('MINIFIED')) return 'minified:${rawClassName}';
  return rawClassName;
}

/// Returns the metadata of the given [index].
// TODO(floitsch): move this to foreign_helper.dart or similar.
@pragma('dart2js:tryInline')
getMetadata(int index) {
  return JS_BUILTIN(
      'returns:var;effects:none;depends:none', JsBuiltin.getMetadata, index);
}

/// Returns the type of the given [index].
// TODO(floitsch): move this to foreign_helper.dart or similar.
@pragma('dart2js:tryInline')
getType(int index) {
  return JS_BUILTIN(
      'returns:var;effects:none;depends:none', JsBuiltin.getType, index);
}

/// No-op method that is called to inform the compiler that preambles might
/// be needed when executing the resulting JS file in a command-line
/// JS engine.
requiresPreamble() {}

bool isJsIndexable(var object, var record) {
  if (record != null) {
    var result = dispatchRecordIndexability(record);
    if (result != null) return result;
  }
  return object is JavaScriptIndexingBehavior;
}

String S(value) {
  if (value is String) return value;
  if (value is num) {
    if (value != 0) {
      // ""+x is faster than String(x) for integers on most browsers.
      return JS('String', r'"" + (#)', value);
    }
  } else if (true == value) {
    return 'true';
  } else if (false == value) {
    return 'false';
  } else if (value == null) {
    return 'null';
  }
  var result = value.toString();
  if (result is! String) {
    throw ArgumentError.value(
        value, 'object', "toString method returned 'null'");
  }
  return result;
}

// Called from generated code.
createInvocationMirror(
    String name, internalName, kind, arguments, argumentNames, types) {
  // TODO(sra): [types] (the number of type arguments) could be omitted in the
  // generated stub code to save an argument. Then we would use `types ?? 0`.
  return new JSInvocationMirror(
      name, internalName, kind, arguments, argumentNames, types);
}

createUnmangledInvocationMirror(
    Symbol symbol, internalName, kind, arguments, argumentNames, types) {
  return new JSInvocationMirror(
      symbol, internalName, kind, arguments, argumentNames, types);
}

void throwInvalidReflectionError(String memberName) {
  throw new UnsupportedError("Can't use '$memberName' in reflection.");
}

/// Helper used to instrument calls when the compiler is invoked with
/// `--experiment-call-instrumentation`.
///
/// By default, whenever a method is invoked for the first time, it prints an id
/// and the method name to the console. This can be overridden by adding a top
/// level `dartCallInstrumentation` hook in JavaScript.
@pragma('dart2js:noInline')
void traceHelper(dynamic /*int*/ id, dynamic /*String*/ qualifiedName) {
  // Note: this method is written mostly in JavaScript to prevent a stack
  // overflow. In particular, we use dynamic argument types because with with
  // types, traceHelper would include type checks for the parameter types, those
  // checks (intTypeCheck, stringTypeCheck) are themselves calls that end up
  // invoking this traceHelper and produce a stack overflow.  Similarly if we
  // had Dart code below using, for example, string interpolation, we would
  // include extra calls to the Dart runtime that could also trigger a stack
  // overflow. This approach here is simpler than making the compiler smart
  // about how to generate traceHelper calls more carefully.
  JS(
      '',
      r'''
      (function (id, name) {
        var hook = self.dartCallInstrumentation;
        if (typeof hook === "function") {
          hook(id, name);
          return;
        }
        if (!this.callInstrumentationCache) {
          this.callInstrumentationCache = Object.create(null);
        }
        if (!this.callInstrumentationCache[id]) {
          console.log(id, name);
          this.callInstrumentationCache[id] = true;
        }
      })(#, #)''',
      id,
      qualifiedName);
}

class JSInvocationMirror implements Invocation {
  static const METHOD = 0;
  static const GETTER = 1;
  static const SETTER = 2;

  /// When [_memberName] is a String, it holds the mangled name of this
  /// invocation.  When it is a Symbol, it holds the unmangled name.
  var /* String or Symbol */ _memberName;
  final String _internalName;
  final int _kind;
  final List _arguments;
  final List _namedArgumentNames;
  final int _typeArgumentCount;

  JSInvocationMirror(this._memberName, this._internalName, this._kind,
      this._arguments, this._namedArgumentNames, this._typeArgumentCount);

  Symbol get memberName {
    if (_memberName is Symbol) return _memberName;
    return _memberName = new _symbol_dev.Symbol.unvalidated(_memberName);
  }

  bool get isMethod => _kind == METHOD;
  bool get isGetter => _kind == GETTER;
  bool get isSetter => _kind == SETTER;
  bool get isAccessor => _kind != METHOD;

  List<Type> get typeArguments {
    if (_typeArgumentCount == 0) return const <Type>[];
    int start = _arguments.length - _typeArgumentCount;
    var list = <Type>[];
    for (int index = 0; index < _typeArgumentCount; index++) {
      list.add(newRti.createRuntimeType(_arguments[start + index]));
    }
    return JSArray.markUnmodifiableList(list);
  }

  List get positionalArguments {
    if (isGetter) return const [];
    var argumentCount =
        _arguments.length - _namedArgumentNames.length - _typeArgumentCount;
    if (argumentCount == 0) return const [];
    var list = [];
    for (var index = 0; index < argumentCount; index++) {
      list.add(_arguments[index]);
    }
    return JSArray.markUnmodifiableList(list);
  }

  Map<Symbol, dynamic> get namedArguments {
    if (isAccessor) return const <Symbol, dynamic>{};
    int namedArgumentCount = _namedArgumentNames.length;
    int namedArgumentsStartIndex =
        _arguments.length - namedArgumentCount - _typeArgumentCount;
    if (namedArgumentCount == 0) return const <Symbol, dynamic>{};
    var map = new Map<Symbol, dynamic>();
    for (int i = 0; i < namedArgumentCount; i++) {
      map[new _symbol_dev.Symbol.unvalidated(_namedArgumentNames[i])] =
          _arguments[namedArgumentsStartIndex + i];
    }
    return new ConstantMapView<Symbol, dynamic>(map);
  }
}

class Primitives {
  static Object? _identityHashCodeProperty;

  static int objectHashCode(object) {
    Object property =
        _identityHashCodeProperty ??= _computeIdentityHashCodeProperty();
    int? hash = JS('int|Null', r'#[#]', object, property);
    if (hash == null) {
      hash = JS('int', '(Math.random() * 0x3fffffff) | 0');
      JS('void', r'#[#] = #', object, property, hash);
    }
    return JS('int', '#', hash);
  }

  static Object _computeIdentityHashCodeProperty() =>
      JS('', 'Symbol("identityHashCode")');

  static int? parseInt(String source, int? radix) {
    checkString(source);
    var re = JS('', r'/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i');
    List? match = JS('JSExtendableArray|Null', '#.exec(#)', re, source);
    int digitsIndex = 1;
    int hexIndex = 2;
    int decimalIndex = 3;
    if (match == null) {
      // TODO(sra): It might be that the match failed due to unrecognized U+0085
      // spaces.  We could replace them with U+0020 spaces and try matching
      // again.
      return null;
    }
    Object? decimalMatch = match[decimalIndex];
    if (radix == null) {
      if (decimalMatch != null) {
        // Cannot fail because we know that the digits are all decimal.
        return JS('int', r'parseInt(#, 10)', source);
      }
      if (match[hexIndex] != null) {
        // Cannot fail because we know that the digits are all hex.
        return JS('int', r'parseInt(#, 16)', source);
      }
      return null;
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
          return null;
        }
      }
    }
    // The above matching and checks ensures the source has at least one digits
    // and all digits are suitable for the radix, so parseInt cannot return NaN.
    return JS('int', r'parseInt(#, #)', source, radix);
  }

  static double? parseDouble(String source) {
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
      return null;
    }
    double result = JS('double', r'parseFloat(#)', source);
    if (result.isNaN) {
      var trimmed = source.trim();
      if (trimmed == 'NaN' || trimmed == '+NaN' || trimmed == '-NaN') {
        return result;
      }
      return null;
    }
    return result;
  }

  /// [: r"$".codeUnitAt(0) :]
  static const int DOLLAR_CHAR_VALUE = 36;

  /// Returns the type of [object] as a string (including type arguments).
  /// Tries to return a sensible name for non-Dart objects.
  ///
  /// In minified mode, uses the unminified names if available, otherwise tags
  /// them with 'minified:'.
  @pragma('dart2js:noInline')
  static String objectTypeName(Object? object) {
    return _objectTypeNameNewRti(object);
  }

  /// Returns the type of [object] as a string (including type arguments).
  /// Tries to return a sensible name for non-Dart objects.
  ///
  /// In minified mode, uses the unminified names if available, otherwise tags
  /// them with 'minified:'.
  static String _objectTypeNameNewRti(Object? object) {
    var dartObjectConstructor = JS_BUILTIN(
        'depends:none;effects:none;', JsBuiltin.dartObjectConstructor);
    if (JS('bool', '# instanceof #', object, dartObjectConstructor)) {
      return newRti.instanceTypeName(object);
    }

    var interceptor = getInterceptor(object);
    if (identical(interceptor, JS_INTERCEPTOR_CONSTANT(Interceptor)) ||
        identical(interceptor, JS_INTERCEPTOR_CONSTANT(JavaScriptObject)) ||
        object is UnknownJavaScriptObject) {
      // Try to do better.  If we do not find something better, fallthrough to
      // Dart-type based name that leave the name as 'UnknownJavaScriptObject',
      // 'Interceptor', or 'JavaScriptObject' (or their minified versions).
      //
      // When we get here via the UnknownJavaScriptObject test (for JavaScript
      // objects from outside the program), the object's constructor has a
      // better name that 'UnknownJavaScriptObject'.
      //
      // When we get here via either the Interceptor or JavaScriptObject test
      // (for Native classes that are declared in the Dart program but have been
      // 'folded' into one of those interceptors), the native class's
      // constructor name is better than the generic 'Interceptor' or
      // 'JavaScriptObject'.

      // Try the [constructorNameFallback]. This gets the constructor name for
      // any browser (used by [getNativeInterceptor]).
      String dispatchName = constructorNameFallback(object);
      if (_saneNativeClassName(dispatchName)) return dispatchName;
      var constructor = JS('', '#.constructor', object);
      if (JS('bool', 'typeof # == "function"', constructor)) {
        var constructorName = JS('', '#.name', constructor);
        if (constructorName is String &&
            _saneNativeClassName(constructorName)) {
          return constructorName;
        }
      }
    }

    return newRti.instanceTypeName(object);
  }

  static bool _saneNativeClassName(name) =>
      name != null && name != 'Object' && name != '';

  /// In minified mode, uses the unminified names if available.
  static String objectToHumanReadableString(Object? object) {
    String name = objectTypeName(object);
    return "Instance of '$name'";
  }

  static int dateNow() => JS('int', r'Date.now()');

  static void initTicker() {
    if (timerFrequency != 0) return;
    // Start with low-resolution. We overwrite the fields if we find better.
    timerFrequency = 1000;
    if (JS('bool', 'typeof window == "undefined"')) return;
    var window = JS('var', 'window');
    if (window == null) return;
    var performance = JS('var', '#.performance', window);
    if (performance == null) return;
    if (JS('bool', 'typeof #.now != "function"', performance)) return;
    timerFrequency = 1000000;
    timerTicks = () => (1000 * JS('num', '#.now()', performance)).floor();
  }

  static int timerFrequency = 0;
  static int Function() timerTicks = dateNow; // Low-resolution version.

  static String? currentUri() {
    requiresPreamble();
    // In a browser return self.location.href.
    if (JS('bool', '!!self.location')) {
      return JS('String', 'self.location.href');
    }

    return null;
  }

  /// Version of `String.fromCharCode.apply` that chunks the conversion to avoid
  /// stack overflows due to very large argument arrays.
  ///
  /// [array] is pre-validated as a JSArray of int values but is not typed as
  /// <int> so it can be called with any JSArray.
  static String _fromCharCodeApply(List array) {
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

  static String stringFromCodePoints(codePoints) {
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

  static String stringFromCharCodes(charCodes) {
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
        return JS('returns:String;effects:none;depends:none',
            'String.fromCharCode(#)', charCode);
      }
      if (charCode <= 0x10ffff) {
        var bits = charCode - 0x10000;
        var low = 0xDC00 | (bits & 0x3ff);
        var high = 0xD800 | (bits >> 10);
        return JS('returns:String;effects:none;depends:none',
            'String.fromCharCode(#, #)', high, low);
      }
    }
    throw new RangeError.range(charCode, 0, 0x10ffff);
  }

  static String stringConcatUnchecked(String string1, String string2) {
    return JS_STRING_CONCAT(string1, string2);
  }

  static String flattenString(String str) {
    return JS('returns:String;depends:none;effects:none;throws:never;gvn:true',
        '#.charCodeAt(0) == 0 ? # : #', str, str, str);
  }

  static String getTimeZoneName(DateTime receiver) {
    // Firefox and Chrome emit the timezone in parenthesis.
    // Example: "Wed May 16 2012 21:13:00 GMT+0200 (CEST)".
    // We extract this name using a regexp.
    var d = lazyAsJsDate(receiver);
    List? match = JS('JSArray|Null', r'/\((.*)\)/.exec(#.toString())', d);
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
    return '';
  }

  static int getTimeZoneOffsetInMinutes(DateTime receiver) {
    // Note that JS and Dart disagree on the sign of the offset.
    // Subtract to avoid -0.0
    return 0 - JS('int', r'#.getTimezoneOffset()', lazyAsJsDate(receiver))
        as int;
  }

  static int? valueFromDecomposedDate(int years, int month, int day, int hours,
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
    // The JavaScript Date constructor 'corrects' year NN to 19NN. Sidestep that
    // correction by adjusting years out of that range and compensating with an
    // adjustment of months. This hack should not be sensitive to leap years but
    // use 400 just in case.
    if (0 <= years && years < 100) {
      years += 400;
      jsMonth -= 400 * 12;
    }
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
    return JS('int', '#', value);
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
  //
  // They are marked as @pragma('dart2js:noThrows') because `receiver` comes from a receiver of
  // a method on DateTime (i.e. is not `null`).

  // TODO(sra): These methods are GVN-able. dart2js should implement an
  // annotation for that.

  // TODO(sra): These methods often occur in groups (e.g. day, month and
  // year). Is it possible to factor them so that the `Date` is visible and can
  // be GVN-ed without a lot of code bloat?

  @pragma('dart2js:noSideEffects')
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  static getYear(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('int', r'(#.getUTCFullYear() + 0)', lazyAsJsDate(receiver))
        : JS('int', r'(#.getFullYear() + 0)', lazyAsJsDate(receiver));
  }

  @pragma('dart2js:noSideEffects')
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  static getMonth(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('JSUInt31', r'#.getUTCMonth() + 1', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'#.getMonth() + 1', lazyAsJsDate(receiver));
  }

  @pragma('dart2js:noSideEffects')
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  static getDay(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('JSUInt31', r'(#.getUTCDate() + 0)', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'(#.getDate() + 0)', lazyAsJsDate(receiver));
  }

  @pragma('dart2js:noSideEffects')
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  static getHours(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('JSUInt31', r'(#.getUTCHours() + 0)', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'(#.getHours() + 0)', lazyAsJsDate(receiver));
  }

  @pragma('dart2js:noSideEffects')
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  static getMinutes(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('JSUInt31', r'(#.getUTCMinutes() + 0)', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'(#.getMinutes() + 0)', lazyAsJsDate(receiver));
  }

  @pragma('dart2js:noSideEffects')
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  static getSeconds(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('JSUInt31', r'(#.getUTCSeconds() + 0)', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'(#.getSeconds() + 0)', lazyAsJsDate(receiver));
  }

  @pragma('dart2js:noSideEffects')
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  static getMilliseconds(DateTime receiver) {
    return (receiver.isUtc)
        ? JS(
            'JSUInt31', r'(#.getUTCMilliseconds() + 0)', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'(#.getMilliseconds() + 0)', lazyAsJsDate(receiver));
  }

  @pragma('dart2js:noSideEffects')
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  static getWeekday(DateTime receiver) {
    int weekday = (receiver.isUtc)
        ? JS('int', r'#.getUTCDay() + 0', lazyAsJsDate(receiver))
        : JS('int', r'#.getDay() + 0', lazyAsJsDate(receiver));
    // Adjust by one because JS weeks start on Sunday.
    return (weekday + 6) % 7 + 1;
  }

  static num valueFromDateString(str) {
    if (str is! String) throw argumentErrorValue(str);
    num value = JS('num', r'Date.parse(#)', str);
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

  static functionNoSuchMethod(function, List? positionalArguments,
      Map<String, dynamic>? namedArguments) {
    int argumentCount = 0;
    List arguments = [];
    List namedArgumentList = [];

    if (positionalArguments != null) {
      argumentCount += positionalArguments.length;
      arguments.addAll(positionalArguments);
    }

    String names = '';
    if (namedArguments != null && !namedArguments.isEmpty) {
      namedArguments.forEach((String name, argument) {
        names = '$names\$$name';
        namedArgumentList.add(name);
        arguments.add(argument);
        argumentCount++;
      });
    }

    String selectorName =
        '${JS_GET_NAME(JsGetName.CALL_PREFIX)}\$$argumentCount$names';

    return function.noSuchMethod(createUnmangledInvocationMirror(
        #call,
        selectorName,
        JSInvocationMirror.METHOD,
        arguments,
        namedArgumentList,
        0));
  }

  /// Implements [Function.apply] for the lazy and startup emitters.
  ///
  /// There are two types of closures that can reach this function:
  ///
  /// 1. tear-offs (including tear-offs of static functions).
  /// 2. anonymous closures.
  ///
  /// They are treated differently (although there are lots of similarities).
  /// Both have in common that they have
  /// a [JsGetName.CALL_CATCH_ALL] and
  /// a [JsGetName.REQUIRED_PARAMETER_PROPERTY] property.
  ///
  /// If the closure supports optional parameters, then they also feature
  /// a [JsGetName.DEFAULT_VALUES_PROPERTY] property.
  ///
  /// The catch-all property is a method that takes all arguments (including
  /// all optional positional or named arguments). If the function accepts
  /// optional arguments, then the default-values property stores (potentially
  /// wrapped in a function) the default values for the optional arguments. If
  /// the function accepts optional positional arguments, then the value is a
  /// JavaScript array with the default values. Otherwise, when the function
  /// accepts optional named arguments, it is a JavaScript object.
  ///
  /// The default-values property may either contain the value directly, or
  /// it can be a function that returns the default-values when invoked.
  ///
  /// If the function is an anonymous closure, then the catch-all property
  /// only contains a string pointing to the property that should be used
  /// instead. For example, if the catch-all property contains the string
  /// "call$4", then the object's "call$4" property should be used as if it was
  /// the value of the catch-all property.
  static applyFunction(Function function, List? positionalArguments,
      Map<String, dynamic>? namedArguments) {
    // Fast path for common cases.
    if (positionalArguments is JSArray &&
        (namedArguments == null || namedArguments.isEmpty)) {
      JSArray arguments = positionalArguments;
      int argumentCount = arguments.length;
      if (argumentCount == 0) {
        String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX0);
        if (JS('bool', '!!#[#]', function, selectorName)) {
          return JS('', '#[#]()', function, selectorName);
        }
      } else if (argumentCount == 1) {
        String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX1);
        if (JS('bool', '!!#[#]', function, selectorName)) {
          return JS('', '#[#](#[0])', function, selectorName, arguments);
        }
      } else if (argumentCount == 2) {
        String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX2);
        if (JS('bool', '!!#[#]', function, selectorName)) {
          return JS('', '#[#](#[0],#[1])', function, selectorName, arguments,
              arguments);
        }
      } else if (argumentCount == 3) {
        String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX3);
        if (JS('bool', '!!#[#]', function, selectorName)) {
          return JS('', '#[#](#[0],#[1],#[2])', function, selectorName,
              arguments, arguments, arguments);
        }
      } else if (argumentCount == 4) {
        String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX4);
        if (JS('bool', '!!#[#]', function, selectorName)) {
          return JS('', '#[#](#[0],#[1],#[2],#[3])', function, selectorName,
              arguments, arguments, arguments, arguments);
        }
      } else if (argumentCount == 5) {
        String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX5);
        if (JS('bool', '!!#[#]', function, selectorName)) {
          return JS(
              '',
              '#[#](#[0],#[1],#[2],#[3],#[4])',
              function,
              selectorName,
              arguments,
              arguments,
              arguments,
              arguments,
              arguments);
        }
      }
      String selectorName =
          '${JS_GET_NAME(JsGetName.CALL_PREFIX)}\$$argumentCount';
      var jsStub = JS('var', r'#[#]', function, selectorName);
      if (jsStub != null) {
        return JS('var', '#.apply(#, #)', jsStub, function, arguments);
      }
    }

    return _generalApplyFunction(function, positionalArguments, namedArguments);
  }

  static _generalApplyFunction(Function function, List? positionalArguments,
      Map<String, dynamic>? namedArguments) {
    List arguments;
    if (positionalArguments != null) {
      if (positionalArguments is JSArray) {
        arguments = positionalArguments;
      } else {
        arguments = List.of(positionalArguments);
      }
    } else {
      arguments = [];
    }

    int argumentCount = arguments.length;

    int requiredParameterCount = JS('int', r'#[#]', function,
        JS_GET_NAME(JsGetName.REQUIRED_PARAMETER_PROPERTY));

    if (argumentCount < requiredParameterCount) {
      return functionNoSuchMethod(function, arguments, namedArguments);
    }

    var defaultValuesClosure = JS('var', r'#[#]', function,
        JS_GET_NAME(JsGetName.DEFAULT_VALUES_PROPERTY));

    bool acceptsOptionalArguments = defaultValuesClosure != null;

    // Default values are stored inside a JavaScript closure to avoid
    // accessing them too early.
    var defaultValues =
        acceptsOptionalArguments ? JS('', '#()', defaultValuesClosure) : null;

    var interceptor = getInterceptor(function);
    var jsFunction =
        JS('', '#[#]', interceptor, JS_GET_NAME(JsGetName.CALL_CATCH_ALL));
    if (jsFunction is String) {
      // Anonymous closures redirect to the catch-all property instead of
      // storing the catch-all method directly in the catch-all property.
      jsFunction = JS('', '#[#]', interceptor, jsFunction);
    }

    if (!acceptsOptionalArguments) {
      if (namedArguments != null && namedArguments.isNotEmpty) {
        // Tried to invoke a function that takes a fixed number of arguments
        // with named (optional) arguments.
        return functionNoSuchMethod(function, arguments, namedArguments);
      }
      if (argumentCount == requiredParameterCount) {
        return JS('var', r'#.apply(#, #)', jsFunction, function, arguments);
      }
      return functionNoSuchMethod(function, arguments, namedArguments);
    }

    bool acceptsPositionalArguments = defaultValues is JSArray;

    if (acceptsPositionalArguments) {
      if (namedArguments != null && namedArguments.isNotEmpty) {
        // Tried to invoke a function that takes optional positional arguments
        // with named arguments.
        return functionNoSuchMethod(function, arguments, namedArguments);
      }

      int defaultsLength = JS('int', '#.length', defaultValues);
      int maxArguments = requiredParameterCount + defaultsLength;
      if (argumentCount > maxArguments) {
        // The function expects fewer arguments.
        return functionNoSuchMethod(function, arguments, null);
      }
      if (argumentCount < maxArguments) {
        List missingDefaults = JS('JSArray', '#.slice(#)', defaultValues,
            argumentCount - requiredParameterCount);
        if (identical(arguments, positionalArguments)) {
          // Defensive copy to avoid modifying passed-in List.
          arguments = List.of(arguments);
        }
        arguments.addAll(missingDefaults);
      }
      return JS('var', '#.apply(#, #)', jsFunction, function, arguments);
    } else {
      // Handle named arguments.

      if (argumentCount > requiredParameterCount) {
        // Tried to invoke a function that takes named parameters with
        // too many positional arguments.
        return functionNoSuchMethod(function, arguments, namedArguments);
      }

      if (identical(arguments, positionalArguments)) {
        // Defensive copy to avoid modifying passed-in List.
        arguments = List.of(arguments);
      }

      List keys = JS('JSArray', r'Object.keys(#)', defaultValues);
      if (namedArguments == null) {
        for (String key in keys) {
          var defaultValue = JS('var', '#[#]', defaultValues, key);
          if (isRequired(defaultValue)) {
            return functionNoSuchMethod(function, arguments, namedArguments);
          }
          arguments.add(defaultValue);
        }
      } else {
        int used = 0;
        for (String key in keys) {
          if (namedArguments.containsKey(key)) {
            used++;
            arguments.add(namedArguments[key]);
          } else {
            var defaultValue = JS('var', '#[#]', defaultValues, key);
            if (isRequired(defaultValue)) {
              return functionNoSuchMethod(function, arguments, namedArguments);
            }
            arguments.add(defaultValue);
          }
        }
        if (used != namedArguments.length) {
          // Named argument with name not accected by function.
          return functionNoSuchMethod(function, arguments, namedArguments);
        }
      }
      return JS('var', r'#.apply(#, #)', jsFunction, function, arguments);
    }
  }

  static StackTrace extractStackTrace(Error error) {
    return getTraceFromException(JS('', r'#.$thrownJsError', error));
  }
}

/// Called by generated code to throw an illegal-argument exception,
/// for example, if a non-integer index is given to an optimized
/// indexed access.
@pragma('dart2js:noInline')
iae(argument) {
  throw argumentErrorValue(argument);
}

/// Called by generated code to throw an index-out-of-range exception, for
/// example, if a bounds check fails in an optimized indexed access.  This may
/// also be called when the index is not an integer, in which case it throws an
/// illegal-argument exception instead, like [iae], or when the receiver is
/// null.
@pragma('dart2js:noInline')
ioore(receiver, index) {
  if (receiver == null) receiver.length; // Force a NoSuchMethodError.
  throw diagnoseIndexError(receiver, index);
}

/// Diagnoses an indexing error. Returns the ArgumentError or RangeError that
/// describes the problem.
@pragma('dart2js:noInline')
Error diagnoseIndexError(indexable, index) {
  if (index is! int) return new ArgumentError.value(index, 'index');
  int length = indexable.length;
  // The following returns the same error that would be thrown by calling
  // [IndexError.check] with no optional parameters
  // provided.
  if (index < 0 || index >= length) {
    return new IndexError.withLength(index, length,
        indexable: indexable, name: 'index');
  }
  // The above should always match, but if it does not, use the following.
  return new RangeError.value(index, 'index');
}

/// Diagnoses a range error. Returns the ArgumentError or RangeError that
/// describes the problem.
@pragma('dart2js:noInline')
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
  return new ArgumentError.value(end, 'end');
}

stringLastIndexOfUnchecked(receiver, element, start) =>
    JS('int', r'#.lastIndexOf(#, #)', receiver, element, start);

/// 'factory' for constructing ArgumentError.value to keep the call sites small.
@pragma('dart2js:noInline')
ArgumentError argumentErrorValue(object) {
  return new ArgumentError.value(object);
}

checkNull(object) {
  if (object == null) throw argumentErrorValue(object);
  return object;
}

@pragma('dart2js:noInline')
num checkNum(value) {
  if (value is! num) throw argumentErrorValue(value);
  return value;
}

int checkInt(value) {
  if (value is! int) throw argumentErrorValue(value);
  return value;
}

bool checkBool(value) {
  if (value is! bool) throw argumentErrorValue(value);
  return value;
}

String checkString(value) {
  if (value is! String) throw argumentErrorValue(value);
  return value;
}

/// Wrap the given Dart object and record a stack trace.
///
/// The code in [unwrapException] deals with getting the original Dart
/// object out of the wrapper again.
@pragma('dart2js:noInline')
wrapException(ex) {
  if (ex == null) ex = new NullThrownError();
  var wrapper = JS('', 'new Error()');
  // [unwrapException] looks for the property 'dartException'.
  JS('void', '#.dartException = #', wrapper, ex);

  if (JS('bool', '"defineProperty" in Object')) {
    // Define a JavaScript getter for 'message'. This is to work around V8 bug
    // (https://code.google.com/p/v8/issues/detail?id=2519).  The default
    // toString on Error returns the value of 'message' if 'name' is
    // empty. Setting toString directly doesn't work, see the bug.
    JS('void', 'Object.defineProperty(#, "message", { get: # })', wrapper,
        DART_CLOSURE_TO_JS(toStringWrapper));
    JS('void', '#.name = ""', wrapper);
  } else {
    // In the unlikely event the browser doesn't support Object.defineProperty,
    // hope that it just calls toString.
    JS('void', '#.toString = #', wrapper, DART_CLOSURE_TO_JS(toStringWrapper));
  }

  return wrapper;
}

/// Do not call directly.
toStringWrapper() {
  // This method gets installed as toString on a JavaScript object. Due to the
  // weird scope rules of JavaScript, JS 'this' will refer to that object.
  return JS('', r'this.dartException').toString();
}

/// This wraps the exception and does the throw.  It is possible to call this in
/// a JS expression context, where the throw statement is not allowed.  Helpers
/// are never inlined, so we don't risk inlining the throw statement into an
/// expression context.
throwExpression(ex) {
  JS('void', 'throw #', wrapException(ex));
}

throwUnsupportedError(message) {
  throw new UnsupportedError(message);
}

// This is used in open coded for-in loops on arrays.
//
//     checkConcurrentModificationError(a.length == startLength, a)
//
// is replaced in codegen by:
//
//     a.length == startLength || throwConcurrentModificationError(a)
//
// TODO(sra): We would like to annotate this as @pragma('dart2js:noSideEffects') so that loops
// with no other effects can recognize that the array length does not
// change. However, in the usual case where the loop does have other effects,
// that causes the length in the loop condition to be phi(startLength,a.length),
// which causes confusion in range analysis and the insertion of a bounds check.
@pragma('dart2js:noInline')
checkConcurrentModificationError(sameLength, collection) {
  if (true != sameLength) {
    throwConcurrentModificationError(collection);
  }
}

@pragma('dart2js:noInline')
throwConcurrentModificationError(collection) {
  throw new ConcurrentModificationError(collection);
}

/// Helper class for building patterns recognizing native type errors.
class TypeErrorDecoder {
  // Field names are private to help tree-shaking.

  /// A regular expression which matches is matched against an error message.
  final String _pattern;

  /// The group index of "arguments" in [_pattern], or -1 if _pattern has no
  /// match for "arguments".
  final int _arguments;

  /// The group index of "argumentsExpr" in [_pattern], or -1 if _pattern has
  /// no match for "argumentsExpr".
  final int _argumentsExpr;

  /// The group index of "expr" in [_pattern], or -1 if _pattern has no match
  /// for "expr".
  final int _expr;

  /// The group index of "method" in [_pattern], or -1 if _pattern has no match
  /// for "method".
  final int _method;

  /// The group index of "receiver" in [_pattern], or -1 if _pattern has no
  /// match for "receiver".
  final int _receiver;

  /// Pattern used to recognize a NoSuchMethodError error (and
  /// possibly extract the method name).
  static final TypeErrorDecoder noSuchMethodPattern =
      extractPattern(provokeCallErrorOn(buildJavaScriptObject()));

  /// Pattern used to recognize an "object not a closure" error (and
  /// possibly extract the method name).
  static final TypeErrorDecoder notClosurePattern =
      extractPattern(provokeCallErrorOn(buildJavaScriptObjectWithNonClosure()));

  /// Pattern used to recognize a NoSuchMethodError on JavaScript null
  /// call.
  static final TypeErrorDecoder nullCallPattern =
      extractPattern(provokeCallErrorOn(JS('', 'null')));

  /// Pattern used to recognize a NoSuchMethodError on JavaScript literal null
  /// call.
  static final TypeErrorDecoder nullLiteralCallPattern =
      extractPattern(provokeCallErrorOnNull());

  /// Pattern used to recognize a NoSuchMethodError on JavaScript
  /// undefined call.
  static final TypeErrorDecoder undefinedCallPattern =
      extractPattern(provokeCallErrorOn(JS('', 'void 0')));

  /// Pattern used to recognize a NoSuchMethodError on JavaScript literal
  /// undefined call.
  static final TypeErrorDecoder undefinedLiteralCallPattern =
      extractPattern(provokeCallErrorOnUndefined());

  /// Pattern used to recognize a NoSuchMethodError on JavaScript null
  /// property access.
  static final TypeErrorDecoder nullPropertyPattern =
      extractPattern(provokePropertyErrorOn(JS('', 'null')));

  /// Pattern used to recognize a NoSuchMethodError on JavaScript literal null
  /// property access.
  static final TypeErrorDecoder nullLiteralPropertyPattern =
      extractPattern(provokePropertyErrorOnNull());

  /// Pattern used to recognize a NoSuchMethodError on JavaScript
  /// undefined property access.
  static final TypeErrorDecoder undefinedPropertyPattern =
      extractPattern(provokePropertyErrorOn(JS('', 'void 0')));

  /// Pattern used to recognize a NoSuchMethodError on JavaScript literal
  /// undefined property access.
  static final TypeErrorDecoder undefinedLiteralPropertyPattern =
      extractPattern(provokePropertyErrorOnUndefined());

  TypeErrorDecoder(this._arguments, this._argumentsExpr, this._expr,
      this._method, this._receiver, this._pattern);

  /// Returns a JavaScript object literal (map) with at most the
  /// following keys:
  ///
  /// * arguments: The arguments as formatted by the JavaScript
  ///   engine. No browsers are known to provide this information.
  ///
  /// * argumentsExpr: The syntax of the arguments (JavaScript source
  ///   code). No browsers are known to provide this information.
  ///
  /// * expr: The syntax of the receiver expression (JavaScript source
  ///   code). Firefox provides this information, for example: "$expr$.$method$
  ///   is not a function".
  ///
  /// * method: The name of the called method (mangled name). At least Firefox
  ///   and Chrome/V8 provides this information, for example, "Object [object
  ///   Object] has no method '$method$'".
  ///
  /// * receiver: The string representation of the receiver. Chrome/V8
  ///   used to provide this information (by calling user-defined
  ///   JavaScript toString on receiver), but it has degenerated into
  ///   "[object Object]" in recent versions.
  matchTypeError(message) {
    var match = JS(
        'JSExtendableArray|Null', 'new RegExp(#).exec(#)', _pattern, message);
    if (match == null) return null;
    var result = JS('', 'Object.create(null)');
    if (_arguments != -1) {
      JS('', '#.arguments = #[# + 1]', result, match, _arguments);
    }
    if (_argumentsExpr != -1) {
      JS('', '#.argumentsExpr = #[# + 1]', result, match, _argumentsExpr);
    }
    if (_expr != -1) {
      JS('', '#.expr = #[# + 1]', result, match, _expr);
    }
    if (_method != -1) {
      JS('', '#.method = #[# + 1]', result, match, _method);
    }
    if (_receiver != -1) {
      JS('', '#.receiver = #[# + 1]', result, match, _receiver);
    }

    return result;
  }

  /// Builds a JavaScript Object with a toString method saying
  /// r"$receiver$".
  static buildJavaScriptObject() {
    return JS('', r'{ toString: function() { return "$receiver$"; } }');
  }

  /// Builds a JavaScript Object with a toString method saying
  /// r"$receiver$". The property "$method" is defined, but is not a function.
  static buildJavaScriptObjectWithNonClosure() {
    return JS(
        '',
        r'{ $method$: null, '
            r'toString: function() { return "$receiver$"; } }');
  }

  /// Extract a pattern from a JavaScript TypeError message.
  ///
  /// The patterns are extracted by forcing TypeErrors on known
  /// objects thus forcing known strings into the error message. The
  /// known strings are then replaced with wildcards which in theory
  /// makes it possible to recognize the desired information even if
  /// the error messages are reworded or translated.
  static extractPattern(String message) {
    // Some JavaScript implementations (V8 at least) include a
    // representation of the receiver in the error message, however,
    // this representation is not always [: receiver.toString() :],
    // sometimes it is [: Object.prototype.toString(receiver) :], and
    // sometimes it is an implementation specific method (but that
    // doesn't seem to happen for object literals). So sometimes we
    // get the text "[object Object]". The shortest way to get that
    // string is using "String({})".
    // See: http://code.google.com/p/v8/issues/detail?id=2519.
    message = JS('String', r'#.replace(String({}), "$receiver$")', message);

    // Since we want to create a new regular expression from an unknown string,
    // we must escape all regular expression syntax.
    message = quoteStringForRegExp(message);

    // Look for the special pattern \$camelCase\$ (all the $ symbols
    // have been escaped already), as we will soon be inserting
    // regular expression syntax that we want interpreted by RegExp.
    List<String>? match =
        JS('JSExtendableArray|Null', r'#.match(/\\\$[a-zA-Z]+\\\$/g)', message);
    if (match == null) match = [];

    // Find the positions within the substring matches of the error message
    // components.  This will help us extract information later, such as the
    // method name.
    int arguments = JS('int', '#.indexOf(#)', match, r'\$arguments\$');
    int argumentsExpr = JS('int', '#.indexOf(#)', match, r'\$argumentsExpr\$');
    int expr = JS('int', '#.indexOf(#)', match, r'\$expr\$');
    int method = JS('int', '#.indexOf(#)', match, r'\$method\$');
    int receiver = JS('int', '#.indexOf(#)', match, r'\$receiver\$');

    // Replace the patterns with a regular expression wildcard.
    // Note: in a perfect world, one would use "(.*)", but not in
    // JavaScript, "." does not match newlines.
    String pattern = JS(
        'String',
        r'#.replace(new RegExp("\\\\\\$arguments\\\\\\$", "g"), '
            r'"((?:x|[^x])*)")'
            r'.replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$", "g"),  '
            r'"((?:x|[^x])*)")'
            r'.replace(new RegExp("\\\\\\$expr\\\\\\$", "g"),  "((?:x|[^x])*)")'
            r'.replace(new RegExp("\\\\\\$method\\\\\\$", "g"),  "((?:x|[^x])*)")'
            r'.replace(new RegExp("\\\\\\$receiver\\\\\\$", "g"),  '
            r'"((?:x|[^x])*)")',
        message);

    return new TypeErrorDecoder(
        arguments, argumentsExpr, expr, method, receiver, pattern);
  }

  /// Provokes a TypeError and returns its message.
  ///
  /// The error is provoked so all known variable content can be recognized and
  /// a pattern can be inferred.
  static String provokeCallErrorOn(expression) {
    // This function is carefully created to maximize the possibility
    // of decoding the TypeError message and turning it into a general
    // pattern.
    //
    // The idea is to inject something known into something unknown.  The
    // unknown entity is the error message that the browser provides with a
    // TypeError.  It is a human readable message, possibly localized in a
    // language no dart2js engineer understand.  We assume that $name$ would
    // never naturally occur in a human readable error message, yet it is easy
    // to decode.
    //
    // For example, evaluate this in V8 version 3.13.7.6:
    //
    // var $expr$ = null; $expr$.$method$()
    //
    // The VM throws an instance of TypeError whose message property contains
    // "Cannot call method '$method$' of null".  We can then reasonably assume
    // that if the string contains $method$, that's where the method name will
    // be in general.  Call this automatically reverse engineering the error
    // format string in V8.
    //
    // So the error message from V8 is turned into this regular expression:
    //
    // "Cannot call method '(.*)' of null"
    //
    // Similarly, if we evaluate:
    //
    // var $expr$ = {toString: function() { return '$receiver$'; }};
    // $expr$.$method$()
    //
    // We get this message: "Object $receiver$ has no method '$method$'"
    //
    // Which is turned into this regular expression:
    //
    // "Object (.*) has no method '(.*)'"
    //
    // Firefox/jsshell is slightly different, it tries to include the source
    // code that caused the exception, so we get this message: "$expr$.$method$
    // is not a function" which is turned into this regular expression:
    //
    // "(.*)\\.(.*) is not a function"

    var function = JS('', r"""function($expr$) {
  var $argumentsExpr$ = "$arguments$";
  try {
    $expr$.$method$($argumentsExpr$);
  } catch (e) {
    return e.message;
  }
}""");
    return JS('String', '(#)(#)', function, expression);
  }

  /// Similar to [provokeCallErrorOn], but provokes an error directly on
  /// literal "null" expression.
  static String provokeCallErrorOnNull() {
    // See [provokeCallErrorOn] for a detailed explanation.
    var function = JS('', r"""function() {
  var $argumentsExpr$ = "$arguments$";
  try {
    null.$method$($argumentsExpr$);
  } catch (e) {
    return e.message;
  }
}""");
    return JS('String', '(#)()', function);
  }

  /// Similar to [provokeCallErrorOnNull], but provokes an error directly on
  /// (void 0), that is, "undefined".
  static String provokeCallErrorOnUndefined() {
    // See [provokeCallErrorOn] for a detailed explanation.
    var function = JS('', r"""function() {
  var $argumentsExpr$ = "$arguments$";
  try {
    (void 0).$method$($argumentsExpr$);
  } catch (e) {
    return e.message;
  }
}""");
    return JS('String', '(#)()', function);
  }

  /// Similar to [provokeCallErrorOn], but provokes a property access
  /// error.
  static String provokePropertyErrorOn(expression) {
    // See [provokeCallErrorOn] for a detailed explanation.
    var function = JS('', r"""function($expr$) {
  try {
    $expr$.$method$;
  } catch (e) {
    return e.message;
  }
}""");
    return JS('String', '(#)(#)', function, expression);
  }

  /// Similar to [provokePropertyErrorOn], but provokes an property access
  /// error directly on literal "null" expression.
  static String provokePropertyErrorOnNull() {
    // See [provokeCallErrorOn] for a detailed explanation.
    var function = JS('', r"""function() {
  try {
    null.$method$;
  } catch (e) {
    return e.message;
  }
}""");
    return JS('String', '(#)()', function);
  }

  /// Similar to [provokePropertyErrorOnNull], but provokes an property access
  /// error directly on (void 0), that is, "undefined".
  static String provokePropertyErrorOnUndefined() {
    // See [provokeCallErrorOn] for a detailed explanation.
    var function = JS('', r"""function() {
  try {
    (void 0).$method$;
  } catch (e) {
    return e.message;
  }
}""");
    return JS('String', '(#)()', function);
  }
}

class NullError extends TypeError implements NoSuchMethodError {
  final String _message;
  final String? _method;

  NullError(this._message, match)
      : _method = match == null ? null : JS('', '#.method', match);

  String toString() {
    if (_method == null) return 'NoSuchMethodError: $_message';
    return "NoSuchMethodError: method not found: '$_method' on null";
  }
}

class JsNoSuchMethodError extends Error implements NoSuchMethodError {
  final String _message;
  final String? _method;
  final String? _receiver;

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

class NullThrownFromJavaScriptException implements Exception {
  final dynamic _irritant;
  NullThrownFromJavaScriptException(this._irritant);

  @override
  String toString() {
    String description =
        JS('bool', '# === null', _irritant) ? 'null' : 'undefined';
    return "Throw of null ('$description' from JavaScript)";
  }
}

/// A wrapper around an exception, much like the one created by [wrapException]
/// but with a pre-given stack-trace.
class ExceptionAndStackTrace {
  dynamic dartException;
  StackTrace stackTrace;

  ExceptionAndStackTrace(this.dartException, this.stackTrace);
}

/// Called from catch blocks in generated code to extract the Dart exception
/// from the thrown value. The thrown value may have been created by
/// [wrapException] or it may be a 'native' JavaScript exception.
///
/// Some native exceptions are mapped to new Dart instances, others are
/// returned unmodified.
Object unwrapException(Object? ex) {
  // Dart converts `null` to `NullThrownError()`. JavaScript can still throw a
  // nullish value.
  if (ex == null) {
    return NullThrownFromJavaScriptException(ex);
  }

  if (ex is ExceptionAndStackTrace) {
    return saveStackTrace(ex, ex.dartException);
  }

  // e.g. a primitive value thrown by JavaScript.
  if (JS('bool', 'typeof # !== "object"', ex)) return ex;

  if (JS('bool', r'"dartException" in #', ex)) {
    return saveStackTrace(ex, JS('', r'#.dartException', ex));
  }
  return _unwrapNonDartException(ex);
}

/// If error implements Dart [Error], save [ex] in [error.$thrownJsError].
/// Otherwise, do nothing. Later, the stack trace can then be extracted from
/// [ex].
Object saveStackTrace(Object ex, Object error) {
  if (error is Error) {
    var thrownStackTrace = JS('', r'#.$thrownJsError', error);
    if (thrownStackTrace == null) {
      JS('void', r'#.$thrownJsError = #', error, ex);
    }
  }
  return error;
}

Object _unwrapNonDartException(Object ex) {
  if (!JS('bool', r'"message" in #', ex)) {
    return ex;
  }
  // Grab hold of the exception message. This field is available on
  // all supported browsers.
  var message = JS('var', r'#.message', ex);

  // Internet Explorer has an error number.  This is the most reliable way to
  // detect specific errors, so check for this first.
  if (JS('bool', '"number" in #', ex) &&
      JS('bool', 'typeof #.number == "number"', ex)) {
    int number = JS('int', '#.number', ex);

    // From http://msdn.microsoft.com/en-us/library/ie/hc53e755(v=vs.94).aspx
    // "number" is a 32-bit word. The error code is the low 16 bits, and the
    // facility code is the upper 16 bits.
    var ieErrorCode = number & 0xffff;
    var ieFacilityNumber = (number >> 16) & 0x1fff;

    // http://msdn.microsoft.com/en-us/library/aa264975(v=vs.60).aspx
    // http://msdn.microsoft.com/en-us/library/ie/1dk3k160(v=vs.94).aspx
    if (ieFacilityNumber == 10) {
      switch (ieErrorCode) {
        case 438:
          return saveStackTrace(
              ex, JsNoSuchMethodError('$message (Error $ieErrorCode)', null));
        case 445:
        case 5007:
          return saveStackTrace(
              ex, NullError('$message (Error $ieErrorCode)', null));
      }
    }
  }

  if (JS('bool', r'# instanceof TypeError', ex)) {
    var match;
    var nsme = TypeErrorDecoder.noSuchMethodPattern;
    var notClosure = TypeErrorDecoder.notClosurePattern;
    var nullCall = TypeErrorDecoder.nullCallPattern;
    var nullLiteralCall = TypeErrorDecoder.nullLiteralCallPattern;
    var undefCall = TypeErrorDecoder.undefinedCallPattern;
    var undefLiteralCall = TypeErrorDecoder.undefinedLiteralCallPattern;
    var nullProperty = TypeErrorDecoder.nullPropertyPattern;
    var nullLiteralProperty = TypeErrorDecoder.nullLiteralPropertyPattern;
    var undefProperty = TypeErrorDecoder.undefinedPropertyPattern;
    var undefLiteralProperty = TypeErrorDecoder.undefinedLiteralPropertyPattern;
    if ((match = nsme.matchTypeError(message)) != null) {
      return saveStackTrace(ex, JsNoSuchMethodError(message, match));
    } else if ((match = notClosure.matchTypeError(message)) != null) {
      // notClosure may match "({c:null}).c()" or "({c:1}).c()", so we
      // cannot tell if this an attempt to invoke call on null or a
      // non-function object.
      // But we do know the method name is "call".
      JS('', '#.method = "call"', match);
      return saveStackTrace(ex, JsNoSuchMethodError(message, match));
    } else if ((match = nullCall.matchTypeError(message)) != null ||
        (match = nullLiteralCall.matchTypeError(message)) != null ||
        (match = undefCall.matchTypeError(message)) != null ||
        (match = undefLiteralCall.matchTypeError(message)) != null ||
        (match = nullProperty.matchTypeError(message)) != null ||
        (match = nullLiteralCall.matchTypeError(message)) != null ||
        (match = undefProperty.matchTypeError(message)) != null ||
        (match = undefLiteralProperty.matchTypeError(message)) != null) {
      return saveStackTrace(ex, NullError(message, match));
    }

    // If we cannot determine what kind of error this is, we fall back
    // to reporting this as a generic error. It's probably better than
    // nothing.
    return saveStackTrace(
        ex, UnknownJsTypeError(message is String ? message : ''));
  }

  if (JS('bool', r'# instanceof RangeError', ex)) {
    if (message is String && contains(message, 'call stack')) {
      return StackOverflowError();
    }

    // In general, a RangeError is thrown when trying to pass a number as an
    // argument to a function that does not allow a range that includes that
    // number. Translate to a Dart ArgumentError with the same message.
    // TODO(sra): Translate to RangeError.
    message = tryStringifyException(ex);
    if (message is String) {
      message = JS('String', r'#.replace(/^RangeError:\s*/, "")', message);
    }
    return saveStackTrace(ex, ArgumentError(message));
  }

  // Check for the Firefox specific stack overflow signal.
  if (JS(
      'bool',
      r'typeof InternalError == "function" && # instanceof InternalError',
      ex)) {
    if (message is String && message == 'too much recursion') {
      return StackOverflowError();
    }
  }

  // Just return the exception. We should not wrap it because in case the
  // exception comes from the DOM, it is a JavaScript object that has a Dart
  // interceptor.
  return ex;
}

String? tryStringifyException(ex) {
  // Since this function is called from [unwrapException] which is called from
  // code injected into a catch-clause, use JavaScript try-catch to avoid a
  // potential loop if stringifying crashes.
  return JS(
      'String|Null',
      r'''
    (function(ex) {
      try {
        return String(ex);
      } catch (e) {}
      return null;
    })(#)
    ''',
      ex);
}

/// Called by generated code to fetch the stack trace from an
/// exception. Should never return null.
StackTrace getTraceFromException(exception) {
  if (exception is ExceptionAndStackTrace) {
    return exception.stackTrace;
  }
  if (exception == null) return new _StackTrace(exception);
  _StackTrace? trace = JS('_StackTrace|Null', r'#.$cachedTrace', exception);
  if (trace != null) return trace;
  trace = new _StackTrace(exception);
  return JS('_StackTrace', r'#.$cachedTrace = #', exception, trace);
}

class _StackTrace implements StackTrace {
  var _exception;
  String? _trace;
  _StackTrace(this._exception);

  String toString() {
    if (_trace != null) return JS('String', '#', _trace);

    String? trace;
    if (JS('bool', '# !== null', _exception) &&
        JS('bool', 'typeof # === "object"', _exception)) {
      trace = JS('String|Null', r'#.stack', _exception);
    }
    return _trace = (trace == null) ? '' : trace;
  }
}

int objectHashCode(var object) {
  if (object == null || JS('bool', 'typeof # != "object"', object)) {
    return object.hashCode;
  } else {
    return Primitives.objectHashCode(object);
  }
}

/// Called by generated code to build a map literal. [keyValuePairs] is
/// a list of key, value, key, value, ..., etc.
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

/// Called by generated code to build a set literal.
fillLiteralSet(values, Set result) {
  // TODO(johnniwinther): Use JSArray to optimize this code instead of calling
  // [getLength] and [getIndex].
  int length = getLength(values);
  for (int index = 0; index < length; index++) {
    result.add(getIndex(values, index));
  }
  return result;
}

/// Called by generated code to move and JSON-ify properties from an object
/// to a map literal.
copyAndJsonifyProperties(from, Map to) {
  if (JS('bool', '!#', from)) return to;
  List keys = JS('JSArray', r'Object.keys(#)', from);
  int index = 0;
  int length = getLength(keys);
  while (index < length) {
    var key = getIndex(keys, index++);
    var value = JS('String', r'JSON.stringify(#[#])', from, key);
    Map jsonValue = jsonDecode(value);
    to[key] = jsonValue;
  }
  return to;
}

/// Returns the property [index] of the JavaScript array [array].
getIndex(var array, int index) {
  return JS('var', r'#[#]', array, index);
}

/// Returns the length of the JavaScript array [array].
int getLength(var array) {
  return JS('int', r'#.length', array);
}

invokeClosure(Function closure, int numberOfArguments, var arg1, var arg2,
    var arg3, var arg4) {
  switch (numberOfArguments) {
    case 0:
      return closure();
    case 1:
      return closure(arg1);
    case 2:
      return closure(arg1, arg2);
    case 3:
      return closure(arg1, arg2, arg3);
    case 4:
      return closure(arg1, arg2, arg3, arg4);
  }
  throw new Exception('Unsupported number of arguments for wrapped closure');
}

/// Called by generated code to convert a Dart closure to a JS
/// closure when the Dart closure is passed to the DOM.
convertDartClosureToJS(closure, int arity) {
  if (closure == null) return null;
  var function = JS('var', r'#.$identity', closure);
  if (JS('bool', r'!!#', function)) return function;

  function = JS(
      'var',
      r'''
        (function(closure, arity, invoke) {
          return function(a1, a2, a3, a4) {
            return invoke(closure, arity, a1, a2, a3, a4);
          };
        })(#,#,#)''',
      closure,
      arity,
      DART_CLOSURE_TO_JS(invokeClosure));

  JS('void', r'#.$identity = #', closure, function);
  return function;
}

/// Superclass for Dart closures.
///
/// All static, tear-off, function declaration and function expression closures
/// extend this class.
abstract class Closure implements Function {
  /// Global counter to prevent reusing function code objects.
  ///
  /// V8 will share the underlying function code objects when the same string is
  /// passed to "new Function".  Shared function code objects can lead to
  /// sub-optimal performance due to polymorphism, and can be prevented by
  /// ensuring the strings are different, for example, by generating a local
  /// variable with a name dependent on [functionCounter].
  static int functionCounter = 0;

  Closure();

  /// Creates a new closure class for use by implicit getters associated with a
  /// method.
  ///
  /// Called from [closureFromTearOff], which is called from code generated by
  /// the emitter.
  ///
  /// Caution: This function is used to create static tearoffs which, being
  /// constants, may be referred to by other constants. This means that this
  /// code cannot refer to the constant pool since it does not exist.
  /// TODO(ahe): Don't call this function when building constants.
  static fromTearOff(Object? parameters) {
    JS_EFFECT(() {
      // The functions are called here to model the calls from JS forms below.
      // The types in the JS forms in the arguments are propagated in type
      // inference.
      var aBoundClosure = JS('BoundClosure', '0');
      var aString = JS('String', '0');
      BoundClosure.receiverOf(aBoundClosure);
      BoundClosure.interceptorOf(aBoundClosure);
      BoundClosure.evalRecipe(aBoundClosure, aString);
      getType(JS('int', '0'));
    });

    Object? container =
        JS('', '#.#', parameters, TearOffParametersPropertyNames.container);

    bool isStatic =
        JS('', '#.#', parameters, TearOffParametersPropertyNames.isStatic);
    bool isIntercepted =
        JS('', '#.#', parameters, TearOffParametersPropertyNames.isIntercepted);
    bool needsDirectAccess = JS('', '#.#', parameters,
        TearOffParametersPropertyNames.needsDirectAccess);
    int applyTrampolineIndex =
        JS('', '#.#', parameters, TearOffParametersPropertyNames.applyIndex);

    JSArray funsOrNames =
        JS('', '#.#', parameters, TearOffParametersPropertyNames.funsOrNames);
    JSArray callNames =
        JS('', '#.#', parameters, TearOffParametersPropertyNames.callNames);

    // The first function is the primary entry point. It is always a string, the
    // property name of the first function within the container.
    assert(JS('', '#[#]', funsOrNames, 0) is String);
    String name = JS('', '#[#]', funsOrNames, 0);
    String? callName = JS('', '#[#]', callNames, 0);
    Object? function = JS('', '#[#]', container, name);

    // [functionType] is either an index into the types-table, a String type
    // recipe (for types that are dependent on the tear-off class type
    // variables), or a function that can compute an Rti. (The latter is
    // necessary if the type is dependent on generic arguments).
    Object? functionType =
        JS('', '#.#', parameters, TearOffParametersPropertyNames.funType)!;

    // function tmp() {};
    // tmp.prototype = BC.prototype;
    // var proto = new tmp;
    // for each computed prototype property:
    //   proto[property] = ...;
    // proto._init = BC;
    // var dynClosureConstructor =
    //     new Function('self', 'target', 'receiver', 'name',
    //                  'this._init(self, target, receiver, name)');
    // proto.constructor = dynClosureConstructor;
    // dynClosureConstructor.prototype = proto;
    // return dynClosureConstructor;

    // We need to create a new subclass of TearOffClosure, one of StaticClosure
    // or BoundClosure.  For this, we need to create an object whose prototype
    // is the prototype is either StaticClosure.prototype or
    // BoundClosure.prototype, respectively in pseudo JavaScript code. The
    // simplest way to access the JavaScript construction function of a Dart
    // class is to create an instance and access its constructor property.
    // Creating an instance ensures that any lazy class initialization has taken
    // place. The newly created instance could in theory be used directly as the
    // prototype, but it might include additional fields that we don't need.  So
    // we only use the new instance to access the constructor property and use
    // Object.create to create the desired prototype.
    //
    // TODO(sra): Cache the prototype to avoid the allocation.
    var prototype = isStatic
        ? JS('StaticClosure', 'Object.create(#.constructor.prototype)',
            new StaticClosure())
        : JS('BoundClosure', 'Object.create(#.constructor.prototype)',
            new BoundClosure(null, null));

    JS('', '#.\$initialize = #', prototype, JS('', '#.constructor', prototype));

    // The constructor functions have names to prevent the JavaScript
    // implementation from inventing a name that might have special meaning
    // (e.g. clashing with minified 'Object' or 'Interceptor').
    var constructor = isStatic
        ? JS('', 'function static_tear_off(){this.\$initialize()}')
        : isCsp
            ? JS('', 'function tear_off(a,b) {this.\$initialize(a,b)}')
            : JS(
                '',
                'new Function("a,b" + #,'
                    ' "this.\$initialize(a,b" + # + ")")',
                functionCounter,
                functionCounter++);

    // It is necessary to set the constructor property, otherwise it will be
    // "Object".
    JS('', '#.constructor = #', prototype, constructor);

    JS('', '#.prototype = #', constructor, prototype);

    JS('', '#.# = #', prototype, BoundClosure.nameProperty, name);
    JS('', '#.# = #', prototype, BoundClosure.targetProperty, function);

    // Create a closure and "monkey" patch it with call stubs.
    var trampoline = function;
    if (!isStatic) {
      trampoline =
          forwardCallTo(name, function, isIntercepted, needsDirectAccess);
    } else {
      // TODO(sra): Can this be removed?
      JS('', '#[#] = #', prototype, STATIC_FUNCTION_NAME_PROPERTY_NAME, name);
    }

    var signatureFunction =
        _computeSignatureFunctionNewRti(functionType, isStatic, isIntercepted);

    JS('', '#[#] = #', prototype, JS_GET_NAME(JsGetName.SIGNATURE_NAME),
        signatureFunction);
    var applyTrampoline = trampoline;
    JS('', '#[#] = #', prototype, callName, trampoline);

    for (int i = 1; i < funsOrNames.length; i++) {
      Object? stub = JS('', '#[#]', funsOrNames, i);

      String stubName = '';
      if (stub is String) {
        stubName = stub;
        stub = JS('', '#[#]', container, stubName);
      }

      Object? stubCallName = JS('', '#[#]', callNames, i);
      // stubCallName can be null if the applyTrampoline has a selector that is
      // otherwise unused, e.g. `foo<T>({bool strange = true})...`
      if (stubCallName != null) {
        if (!isStatic) {
          stub =
              forwardCallTo(stubName, stub, isIntercepted, needsDirectAccess);
        }
        JS('', '#[#] = #', prototype, stubCallName, stub);
      }
      if (i == applyTrampolineIndex) {
        applyTrampoline = stub;
      }
    }

    JS('', '#[#] = #', prototype, JS_GET_NAME(JsGetName.CALL_CATCH_ALL),
        applyTrampoline);

    String reqArgProperty = JS_GET_NAME(JsGetName.REQUIRED_PARAMETER_PROPERTY);
    Object? requiredParameterCount = JS('', '#.#', parameters,
        TearOffParametersPropertyNames.requiredParameterCount);
    JS('', '#.# = #', prototype, reqArgProperty, requiredParameterCount);

    String defValProperty = JS_GET_NAME(JsGetName.DEFAULT_VALUES_PROPERTY);
    Object? optionalParameterDefaultValues = JS('', '#.#', parameters,
        TearOffParametersPropertyNames.optionalParameterDefaultValues);
    JS('', '#.# = #', prototype, defValProperty,
        optionalParameterDefaultValues);

    return constructor;
  }

  static _computeSignatureFunctionNewRti(
      Object functionType, bool isStatic, bool isIntercepted) {
    if (JS('bool', 'typeof # == "number"', functionType)) {
      // Index into types table. Handled in rti.dart.
      return functionType;
    }
    if (JS('bool', 'typeof # == "string"', functionType)) {
      // A recipe to evaluate against the instance type.
      if (isStatic) {
        // TODO(sra): Recipe for static tearoff.
        throw 'Cannot compute signature for static tearoff.';
      }
      final typeEvalMethod = RAW_DART_FUNCTION_REF(BoundClosure.evalRecipe);
      return JS(
          '',
          '    function(recipe, evalOnReceiver) {'
              '  return function() {'
              '    return evalOnReceiver(this, recipe);'
              '  };'
              '}(#,#)',
          functionType,
          typeEvalMethod);
    }
    throw 'Error in functionType of tearoff';
  }

  static cspForwardCall(
      int arity, bool needsDirectAccess, String? stubName, function) {
    var getReceiver = RAW_DART_FUNCTION_REF(BoundClosure.receiverOf);

    // We have the target method (or an arity stub for the method) in
    // [function]. These fixed-arity forwarding stubs could use
    // `Function.prototype.call` on the target directly, but on some browsers it
    // is quite a bit faster to do a property access again to get the
    // function. Accessing the property again will fail (retrieve the wrong
    // function) if the desired property is shadowed. This can happen, e.g.,
    // when the tear-off was created by a super-getter call `super.method` and
    // `method` has an override on some subclass.
    //
    // To handle the shadowing-of-a-method-that-has-a-super-tearoff case, we use
    // the default slow case that uses `Function.prototype.apply`.
    if (needsDirectAccess) arity = -1;

    switch (arity) {
      case 0:
        return JS(
            '',
            'function(entry, receiverOf){'
                'return function(){'
                'return receiverOf(this)[entry]()'
                '}'
                '}(#,#)',
            stubName,
            getReceiver);
      case 1:
        return JS(
            '',
            'function(entry, receiverOf){'
                'return function(a){'
                'return receiverOf(this)[entry](a)'
                '}'
                '}(#,#)',
            stubName,
            getReceiver);
      case 2:
        return JS(
            '',
            'function(entry, receiverOf){'
                'return function(a, b){'
                'return receiverOf(this)[entry](a, b)'
                '}'
                '}(#,#)',
            stubName,
            getReceiver);
      case 3:
        return JS(
            '',
            'function(entry, receiverOf){'
                'return function(a, b, c){'
                'return receiverOf(this)[entry](a, b, c)'
                '}'
                '}(#,#)',
            stubName,
            getReceiver);
      case 4:
        return JS(
            '',
            'function(entry, receiverOf){'
                'return function(a, b, c, d){'
                'return receiverOf(this)[entry](a, b, c, d)'
                '}'
                '}(#,#)',
            stubName,
            getReceiver);
      case 5:
        return JS(
            '',
            'function(entry, receiverOf){'
                'return function(a, b, c, d, e){'
                'return receiverOf(this)[entry](a, b, c, d, e)'
                '}'
                '}(#,#)',
            stubName,
            getReceiver);
      default:
        // Here we use `Function.prototype.apply`.
        return JS(
            '',
            'function(f, receiverOf){'
                'return function(){'
                'return f.apply(receiverOf(this), arguments)'
                '}'
                '}(#,#)',
            function,
            getReceiver);
    }
  }

  static bool get isCsp => JS_GET_FLAG('USE_CONTENT_SECURITY_POLICY');

  static forwardCallTo(
      String stubName, function, bool isIntercepted, bool needsDirectAccess) {
    if (isIntercepted)
      return forwardInterceptedCallTo(stubName, function, needsDirectAccess);
    int arity = JS('int', '#.length', function);

    if (isCsp || needsDirectAccess || arity >= 27) {
      return cspForwardCall(arity, needsDirectAccess, stubName, function);
    }

    if (arity == 0) {
      // Incorporate functionCounter into a local.
      String selfName = 'self${functionCounter++}';
      return JS(
          '',
          '(new Function(#))()',
          'return function(){'
              'var $selfName = this.${BoundClosure.receiverFieldName()};'
              'return $selfName.$stubName();'
              '}');
    }
    assert(1 <= arity && arity < 27);
    String arguments = JS('String',
        '"abcdefghijklmnopqrstuvwxyz".split("").splice(0,#).join(",")', arity);
    arguments += '${functionCounter++}';
    return JS(
        '',
        '(new Function(#))()',
        'return function($arguments){'
            'return this.${BoundClosure.receiverFieldName()}.$stubName($arguments);'
            '}');
  }

  static cspForwardInterceptedCall(
      int arity, bool needsDirectAccess, String? stubName, function) {
    var getReceiver = RAW_DART_FUNCTION_REF(BoundClosure.receiverOf);
    var getInterceptor = RAW_DART_FUNCTION_REF(BoundClosure.interceptorOf);
    // Handle intercepted stub-names with the default slow case.
    if (needsDirectAccess) arity = -1;
    switch (arity) {
      case 0:
        // Intercepted functions always takes at least one argument (the
        // receiver).
        throw RuntimeError('Intercepted function with no arguments.');
      case 1:
        return JS(
            '',
            'function(entry, interceptorOf, receiverOf){'
                'return function(){'
                'return interceptorOf(this)[entry](receiverOf(this))'
                '}'
                '}(#,#,#)',
            stubName,
            getInterceptor,
            getReceiver);
      case 2:
        return JS(
            '',
            'function(entry, interceptorOf, receiverOf){'
                'return function(a){'
                'return interceptorOf(this)[entry](receiverOf(this), a)'
                '}'
                '}(#,#,#)',
            stubName,
            getInterceptor,
            getReceiver);
      case 3:
        return JS(
            '',
            'function(entry, interceptorOf, receiverOf){'
                'return function(a, b){'
                'return interceptorOf(this)[entry](receiverOf(this), a, b)'
                '}'
                '}(#,#,#)',
            stubName,
            getInterceptor,
            getReceiver);
      case 4:
        return JS(
            '',
            'function(entry, interceptorOf, receiverOf){'
                'return function(a, b, c){'
                'return interceptorOf(this)[entry](receiverOf(this), a, b, c)'
                '}'
                '}(#,#,#)',
            stubName,
            getInterceptor,
            getReceiver);
      case 5:
        return JS(
            '',
            'function(entry, interceptorOf, receiverOf){'
                'return function(a, b, c, d){'
                'return interceptorOf(this)[entry](receiverOf(this), a, b, c, d)'
                '}'
                '}(#,#,#)',
            stubName,
            getInterceptor,
            getReceiver);
      case 6:
        return JS(
            '',
            'function(entry, interceptorOf, receiverOf){'
                'return function(a, b, c, d, e){'
                'return interceptorOf(this)[entry](receiverOf(this), a, b, c, d, e)'
                '}'
                '}(#,#,#)',
            stubName,
            getInterceptor,
            getReceiver);
      default:
        return JS(
            '',
            'function(f, interceptorOf, receiverOf){'
                'return function(){'
                'var a = [receiverOf(this)];'
                'Array.prototype.push.apply(a, arguments);'
                'return f.apply(interceptorOf(this), a)'
                '}'
                '}(#,#,#)',
            function,
            getInterceptor,
            getReceiver);
    }
  }

  static forwardInterceptedCallTo(
      String stubName, function, bool needsDirectAccess) {
    String interceptorField = BoundClosure.interceptorFieldName();
    String receiverField = BoundClosure.receiverFieldName();
    int arity = JS('int', '#.length', function);
    bool isCsp = JS_GET_FLAG('USE_CONTENT_SECURITY_POLICY');

    if (isCsp || needsDirectAccess || arity >= 28) {
      return cspForwardInterceptedCall(
          arity, needsDirectAccess, stubName, function);
    }
    if (arity == 1) {
      return JS(
          '',
          '(new Function(#))()',
          'return function(){'
              'return this.$interceptorField.$stubName(this.$receiverField);'
              '${functionCounter++}'
              '}');
    }
    assert(1 < arity && arity < 28);
    String arguments = JS(
        'String',
        '"abcdefghijklmnopqrstuvwxyz".split("").splice(0,#).join(",")',
        arity - 1);
    return JS(
        '',
        '(new Function(#))()',
        'return function($arguments){'
            'return this.$interceptorField.$stubName(this.$receiverField, $arguments);'
            '${functionCounter++}'
            '}');
  }

  // The backend adds a special getter of the form
  //
  // Closure get call => this;
  //
  // to allow tearing off a closure from itself. We do this magically in the
  // backend rather than simply adding it here, as we do not want this getter
  // to be visible to resolution and the generation of extra stubs.

  String toString() {
    String? name;
    var constructor = JS('', '#.constructor', this);
    name =
        constructor == null ? null : JS('String|Null', '#.name', constructor);
    if (name == null) name = 'unknown';
    return "Closure '${unminifyOrTag(name)}'";
  }
}

/// This is called by the fragment emitter.
// TODO(sra): The fragment emitter could call `Closure.fromTearOff` directly.
closureFromTearOff(parameters) {
  return Closure.fromTearOff(parameters);
}

/// Base class for closures with no arguments.
abstract class Closure0Args extends Closure {}

/// Base class for closures with two positional arguments.
abstract class Closure2Args extends Closure {}

/// Represents an implicit closure of a function.
abstract class TearOffClosure extends Closure {}

class StaticClosure extends TearOffClosure {
  String toString() {
    String? name =
        JS('String|Null', '#[#]', this, STATIC_FUNCTION_NAME_PROPERTY_NAME);
    if (name == null) return 'Closure of unknown static method';
    return "Closure '${unminifyOrTag(name)}'";
  }
}

/// Represents a 'tear-off' or property extraction closure of an instance
/// method, that is an instance method bound to a specific receiver (instance).
///
/// This is a base class that is extended to create a separate closure class for
/// each instance method. The subclass is created at run time.
class BoundClosure extends TearOffClosure {
  /// The Dart receiver.
  final _receiver;

  /// The JavaScript receiver when using the interceptor calling convention.
  final _interceptor;

  /// The [_name] and [_target] of the bound closure are stored in the prototype
  /// of the closure class (i.e. the subclass of BoundClosure).
  static const nameProperty = r'$_name';
  static const targetProperty = r'$_target';

  /// The name of the function. Only used by `toString()`.
  String get _name => JS('', '#.#', this, nameProperty);

  /// The primary entry point for the instance method, used by `==`/`hashCode`.
  Object get _target => JS('', '#.#', this, targetProperty);

  BoundClosure(this._receiver, this._interceptor);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BoundClosure) return false;
    return JS('bool', '# === #', _target, other._target) &&
        JS('bool', '# === #', _receiver, other._receiver);
  }

  @override
  int get hashCode {
    int receiverHashCode = objectHashCode(_receiver);
    return receiverHashCode ^ Primitives.objectHashCode(_target);
  }

  @override
  String toString() {
    // TODO(sra): When minified, mark [_name] with a tag,
    // e.g. 'minified-property:' so that it can be unminified.
    return "Closure '$_name' of "
        "${Primitives.objectToHumanReadableString(_receiver)}";
  }

  @pragma('dart2js:parameter:trust')
  static evalRecipe(BoundClosure closure, String recipe) {
    return newRti.evalInInstance(closure._receiver, recipe);
  }

  @pragma('dart2js:noInline')
  @pragma('dart2js:parameter:trust')
  static receiverOf(BoundClosure closure) => closure._receiver;

  @pragma('dart2js:noInline')
  @pragma('dart2js:parameter:trust')
  static interceptorOf(BoundClosure closure) => closure._interceptor;

  static String? _receiverFieldNameCache;
  static String receiverFieldName() =>
      _receiverFieldNameCache ??= _computeFieldNamed('receiver');

  static String? _interceptorFieldNameCache;
  static String interceptorFieldName() =>
      _interceptorFieldNameCache ??= _computeFieldNamed('interceptor');

  @pragma('dart2js:noInline')
  @pragma('dart2js:noSideEffects')
  static String _computeFieldNamed(String fieldName) {
    var template = new BoundClosure('receiver', 'interceptor');
    var names = JSArray.markFixedList(
        JS('', 'Object.getOwnPropertyNames(#)', template));
    for (int i = 0; i < names.length; i++) {
      var name = names[i];
      if (JS('bool', '#[#] === #', template, name, fieldName)) {
        return JS('String', '#', name);
      }
    }
    throw ArgumentError("Field name $fieldName not found.");
  }
}

bool jsHasOwnProperty(var jsObject, String property) {
  return JS('bool', r'#.hasOwnProperty(#)', jsObject, property);
}

jsPropertyAccess(var jsObject, String property) {
  return JS('var', r'#[#]', jsObject, property);
}

/// A metadata annotation describing the types instantiated by a native element.
///
/// The annotation is valid on a native method and a field of a native class.
///
/// By default, a field of a native class is seen as an instantiation point for
/// all native classes that are a subtype of the field's type, and a native
/// method is seen as an instantiation point fo all native classes that are a
/// subtype of the method's return type, or the argument types of the declared
/// type of the method's callback parameter.
///
/// An @[Creates] annotation overrides the default set of instantiated types.
/// If one or more @[Creates] annotations are present, the type of the native
/// element is ignored, and the union of @[Creates] annotations is used instead.
/// The names in the strings are resolved and the program will fail to compile
/// with dart2js if they do not name types.
///
/// The argument to [Creates] is a string.  The string is parsed as the names of
/// one or more types, separated by vertical bars `|`.  There are some special
/// names:
///
/// * `=Object`. This means 'exactly Object', which is a plain JavaScript object
///   with properties and none of the subtypes of Object.
///
/// Example: we may know that a method always returns a specific implementation:
///
///     @Creates('_NodeList')
///     List<Node> getElementsByTagName(String tag) native;
///
/// Useful trick: A method can be marked as not instantiating any native classes
/// with the annotation `@Creates('Null')`.  This is useful for fields on native
/// classes that are used only in Dart code.
///
///     @Creates('Null')
///     var _cachedFoo;
class Creates {
  final String types;
  const Creates(this.types);
}

/// A metadata annotation describing the types returned or yielded by a native
/// element.
///
/// The annotation is valid on a native method and a field of a native class.
///
/// By default, a native method or field is seen as returning or yielding all
/// subtypes if the method return type or field type.  This annotation allows a
/// more precise set of types to be specified.
///
/// See [Creates] for the syntax of the argument.
///
/// Example: IndexedDB keys are numbers, strings and JavaScript Arrays of keys.
///
///     @Returns('String|num|JSExtendableArray')
///     dynamic key;
///
///     // Equivalent:
///     @Returns('String') @Returns('num') @Returns('JSExtendableArray')
///     dynamic key;
class Returns {
  final String types;
  const Returns(this.types);
}

/// A metadata annotation placed on native methods and fields of native classes
/// to specify the JavaScript name.
///
/// This example declares a Dart field + getter + setter called `$dom_title`
/// that corresponds to the JavaScript property `title`.
///
///     class Document native "*Foo" {
///       @JSName('title')
///       String $dom_title;
///     }
class JSName {
  final String name;
  const JSName(this.name);
}

/// The following methods are called by the runtime to implement checked mode
/// and casts. We specialize each primitive type (eg int, bool), and use the
/// compiler's convention to do is-checks on regular objects.
bool boolConversionCheck(value) {
  // The value from kernel should always be true, false, or null.
  if (value == null) assertThrow('boolean expression must not be null');
  return JS('bool', '#', value);
}

@pragma('dart2js:noInline')
void checkDeferredIsLoaded(String loadId) {
  if (!_loadedLibraries.contains(loadId)) {
    throw new DeferredNotLoadedError(loadId);
  }
}

/// Special interface recognized by the compiler and implemented by DOM
/// objects that support integer indexing. This interface is not
/// visible to anyone, and is only injected into special libraries.
abstract class JavaScriptIndexingBehavior<E> extends JSMutableIndexable<E> {}

class FallThroughErrorImplementation extends FallThroughError {
  FallThroughErrorImplementation();
  String toString() => 'Switch case fall-through.';
}

/// Helper function for implementing asserts. The compiler treats this
/// specially.
///
/// Returns the negation of the condition. That is: `true` if the assert should
/// fail.
bool assertTest(condition) {
  if (true == condition) return false;
  if (false == condition) return true;
  bool checked = condition as bool;
  if (null == condition) {
    newRti.throwTypeError('assert condition must not be null');
  }
  return !checked;
}

/// Helper function for implementing asserts with messages.
/// The compiler treats this specially.
void assertThrow(Object message) {
  throw _AssertionError(message);
}

/// Helper function for implementing asserts without messages.
/// The compiler treats this specially.
@pragma('dart2js:noInline')
void assertHelper(condition) {
  if (assertTest(condition)) throw AssertionError();
}

/// Called by generated code when a static field's initializer references the
/// field that is currently being initialized.
void throwCyclicInit(String staticName) {
  throw new CyclicInitializationError(staticName);
}

/// Error thrown when a runtime error occurs.
class RuntimeError extends Error {
  final message;
  RuntimeError(this.message);
  String toString() => 'RuntimeError: $message';
}

class DeferredNotLoadedError extends Error implements NoSuchMethodError {
  String libraryName;

  DeferredNotLoadedError(this.libraryName);

  String toString() {
    return 'Deferred library $libraryName was not loaded.';
  }
}

// TODO(ahe): Remove this class and call noSuchMethod instead.
class UnimplementedNoSuchMethodError extends Error
    implements NoSuchMethodError {
  final String _message;

  UnimplementedNoSuchMethodError(this._message);

  String toString() => 'Unsupported operation: $_message';
}

/// Creates a random number with 64 bits of randomness.
///
/// This will be truncated to the 53 bits available in a double.
int random64() {
  // TODO(lrn): Use a secure random source.
  int int32a = JS('int', '(Math.random() * 0x100000000) >>> 0');
  int int32b = JS('int', '(Math.random() * 0x100000000) >>> 0');
  return int32a + int32b * 0x100000000;
}

String jsonEncodeNative(String string) {
  return JS('String', 'JSON.stringify(#)', string);
}

/// Returns a property name for placing data on JavaScript objects shared
/// between DOM isolates.  This happens when multiple programs are loaded in the
/// same JavaScript context (i.e. page).  The name is based on [name] but with
/// an additional part that is unique for each isolate.
///
/// The form of the name is '___dart_$name_$id'.
String getIsolateAffinityTag(String name) {
  var isolateTagGetter = JS_EMBEDDED_GLOBAL('', GET_ISOLATE_TAG);
  return JS('String', '#(#)', isolateTagGetter, name);
}

final Map<String, Future<Null>?> _loadingLibraries = <String, Future<Null>?>{};
final Set<String> _loadedLibraries = new Set<String>();

/// Events used to diagnose failures from deferred loading requests.
final List<String> _eventLog = <String>[];

typedef void DeferredLoadCallback();

// Function that will be called every time a new deferred import is loaded.
DeferredLoadCallback? deferredLoadHook;

/// Loads a deferred library. The compiler generates a call to this method to
/// implement `import.loadLibrary()`. The [priority] argument is the index of
/// one of the [LoadLibraryPriority] enum's members.
///
///   - `0` for `LoadLibraryPriority.normal`
///   - `1` for `LoadLibraryPriority.high`
Future<Null> loadDeferredLibrary(String loadId, int priority) {
  // Convert [priority] to the enum value as form of validation:
  final unusedPriorityEnum = LoadLibraryPriority.values[priority];
  // The enum's values may be checked via the `index`:
  assert(priority == LoadLibraryPriority.normal.index ||
      priority == LoadLibraryPriority.high.index);

  // TODO(sra): Implement prioritization.

  // For each loadId there is a list of parts to load. The parts are represented
  // by an index. There are two arrays, one that maps the index into a Uri and
  // another that maps the index to a hash.
  var partsMap = JS_EMBEDDED_GLOBAL('', DEFERRED_LIBRARY_PARTS);
  List? indexes = JS('JSExtendableArray|Null', '#[#]', partsMap, loadId);
  if (indexes == null) return new Future.value(null);
  List<String> uris = <String>[];
  List<String> hashes = <String>[];
  List index2uri = JS_EMBEDDED_GLOBAL('JSArray', DEFERRED_PART_URIS);
  List index2hash = JS_EMBEDDED_GLOBAL('JSArray', DEFERRED_PART_HASHES);
  for (int i = 0; i < indexes.length; i++) {
    int index = JS('int', '#[#]', indexes, i);
    uris.add(JS('String', '#[#]', index2uri, index));
    hashes.add(JS('String', '#[#]', index2hash, index));
  }

  int total = hashes.length;
  assert(total == uris.length);
  List<bool> waitingForLoad = new List.filled(total, true);
  int nextHunkToInitialize = 0;
  var isHunkLoaded = JS_EMBEDDED_GLOBAL('', IS_HUNK_LOADED);
  var isHunkInitialized = JS_EMBEDDED_GLOBAL('', IS_HUNK_INITIALIZED);
  var initializer = JS_EMBEDDED_GLOBAL('', INITIALIZE_LOADED_HUNK);

  void initializeSomeLoadedHunks() {
    for (int i = nextHunkToInitialize; i < total; ++i) {
      // A hunk is initialized only if all the preceding hunks have been
      // initialized.
      if (waitingForLoad[i]) return;
      nextHunkToInitialize++;

      // It is possible for a hash to be repeated. This happens when two
      // different parts both end up empty. Checking in the loop rather than
      // pre-filtering prevents duplicate hashes leading to duplicated
      // initializations.
      // TODO(29572): Merge small parts.
      // TODO(29635): Remove duplicate parts from tables and output files.
      var uri = uris[i];
      var hash = hashes[i];
      if (JS('bool', '#(#)', isHunkInitialized, hash)) {
        _eventLog.add(' - already initialized: $uri ($hash)');
        continue;
      }
      // On strange scenarios, e.g. if js encounters parse errors, we might get
      // an "success" callback on the script load but the hunk will be null.
      if (JS('bool', '#(#)', isHunkLoaded, hash)) {
        _eventLog.add(' - initialize: $uri ($hash)');
        JS('void', '#(#)', initializer, hash);
      } else {
        _eventLog.add(' - missing hunk: $uri ($hash)');
        throw new DeferredLoadException("Loading ${uris[i]} failed: "
            "the code with hash '${hash}' was not loaded.\n"
            "event log:\n${_eventLog.join("\n")}\n");
      }
    }
  }

  Future loadAndInitialize(int i) {
    if (JS('bool', '#(#)', isHunkLoaded, hashes[i])) {
      waitingForLoad[i] = false;
      return new Future.value();
    }
    return _loadHunk(uris[i], loadId).then((Null _) {
      waitingForLoad[i] = false;
      initializeSomeLoadedHunks();
    });
  }

  return Future.wait(new List.generate(total, loadAndInitialize)).then((_) {
    initializeSomeLoadedHunks();
    // At this point all hunks have been loaded, so there should be no pending
    // initializations to do.
    assert(nextHunkToInitialize == total);
    bool updated = _loadedLibraries.add(loadId);
    if (updated && deferredLoadHook != null) {
      deferredLoadHook!();
    }
  });
}

/// The `nonce` value on the current script used for strict-CSP, if any.
String? _cspNonce = _computeCspNonce();

String? _computeCspNonce() {
  var currentScript = JS_EMBEDDED_GLOBAL('', CURRENT_SCRIPT);
  if (currentScript == null) return null;
  String? nonce = JS('String|Null', '#.nonce', currentScript);
  return (nonce != null && nonce != '')
      ? nonce
      : JS('String|Null', '#.getAttribute("nonce")', currentScript);
}

/// The 'crossOrigin' value on the current script used for CORS, if any.
String? _crossOrigin = _computeCrossOrigin();

String? _computeCrossOrigin() {
  var currentScript = JS_EMBEDDED_GLOBAL('', CURRENT_SCRIPT);
  if (currentScript == null) return null;
  return JS('String|Null', '#.crossOrigin', currentScript);
}

/// Returns true if we are currently in a worker context.
bool _isWorker() {
  requiresPreamble();
  return JS('', '!self.window && !!self.postMessage');
}

/// The src URL for the script tag that loaded this code.
final String? thisScript = _computeThisScript();

/// Base URL of `thisScript`.
final String _thisScriptBaseUrl = _computeBaseUrl();

String _computeBaseUrl() {
  String script = thisScript!;
  return JS('', '#.substring(0, #.lastIndexOf("/") + 1)', script, script);
}

/// Trusted Type policy [1] for generating validated URLs for scripts for
/// deferred loading. Only the `createScriptURL` member of this policy is used.
///
/// [1]: https://w3c.github.io/webappsec-trusted-types/dist/spec/#trusted-type-policy
final Object _deferredLoadingTrustedTypesPolicy = _computePolicy();

const _deferredLoadingTrustedTypesPolicyName = 'dart:deferred-loading';

Object _computePolicy() {
  // There is no actual validation, since the URLs for deferred loading are safe
  // by construction (see [_getBasedScriptUrl].  If the URL was validated, the
  // validation would ensure it is based off the main script.
  final Object policyOptions = JS('=Object', '{createScriptURL: (url) => url}');

  // For our purposes, the policyOptions duck-types to an object with a single
  // method of the policy, so we use the options as a policy polyfill.
  final fallbackPolicy = policyOptions;

  final Object? policyFactory = JS('', 'self.trustedTypes');
  if (policyFactory == null) return fallbackPolicy;
  final Object? newPolicy = JS('', '#.createPolicy(#, #)', policyFactory,
      _deferredLoadingTrustedTypesPolicyName, policyOptions);
  return newPolicy ?? fallbackPolicy;
}

/// A TrustedScriptURL for the component that is alongside the main script of
/// this program. On browsers or environments that do not support
/// TrustedScriptURL, a String is returned instead.
///
/// Changes to this method require a careful review to ensure that the URLs
/// remain safe by construction.
///
/// The component is encoded to prevent any directory 'navigation'. If deferred
/// loading is changed to use a more structured layout with subdirectories, this
/// method will need to be updated to make the URL still clearly safe by
/// construction.
Object _getBasedScriptUrl(String component) {
  final base = _thisScriptBaseUrl;
  final encodedComponent = _encodeURIComponent(component);
  final url = '$base$encodedComponent';
  final policy = _deferredLoadingTrustedTypesPolicy;
  return JS('', '#.createScriptURL(#)', policy, url);
}

Object getBasedScriptUrlForTesting(String component) =>
    _getBasedScriptUrl(component);

String _encodeURIComponent(String component) {
  return JS('', 'self.encodeURIComponent(#)', component);
}

/// The src url for the script tag that loaded this function.
///
/// Used to create JavaScript workers and load deferred libraries.
String? _computeThisScript() {
  var currentScript = JS_EMBEDDED_GLOBAL('', CURRENT_SCRIPT);
  if (currentScript != null) {
    return JS('String', 'String(#.src)', currentScript);
  }
  // A worker has no script tag - so get an url from a stack-trace.
  if (_isWorker()) return _computeThisScriptFromTrace();
  // An isolate that doesn't support workers, but doesn't have a
  // currentScript either. This is most likely a Chrome extension.
  return null;
}

String _computeThisScriptFromTrace() {
  var stack = JS('String|Null', 'new Error().stack');
  if (stack == null) {
    // According to Internet Explorer documentation, the stack
    // property is not set until the exception is thrown. The stack
    // property was not provided until IE10.
    stack = JS(
        'String|Null',
        '(function() {'
            'try { throw new Error() } catch(e) { return e.stack }'
            '})()');
    if (stack == null) throw new UnsupportedError('No stack trace');
  }
  var pattern, matches;

  // This pattern matches V8, Chrome, and Internet Explorer stack
  // traces that look like this:
  // Error
  //     at methodName (URI:LINE:COLUMN)
  pattern = JS('', r'new RegExp("^ *at [^(]*\\((.*):[0-9]*:[0-9]*\\)$", "m")');

  matches = JS('JSExtendableArray|Null', '#.match(#)', stack, pattern);
  if (matches != null) return JS('String', '#[1]', matches);

  // This pattern matches Firefox stack traces that look like this:
  // methodName@URI:LINE
  pattern = JS('', r'new RegExp("^[^@]*@(.*):[0-9]*$", "m")');

  matches = JS('JSExtendableArray|Null', '#.match(#)', stack, pattern);
  if (matches != null) return JS('String', '#[1]', matches);

  throw new UnsupportedError('Cannot extract URI from "$stack"');
}

Future<Null> _loadHunk(String hunkName, String loadId) {
  var future = _loadingLibraries[hunkName];
  _eventLog.add(' - _loadHunk: $hunkName');
  if (future != null) {
    _eventLog.add('reuse: $hunkName');
    return future.then((Null _) => null);
  }

  Object trustedScriptUri = _getBasedScriptUrl(hunkName);
  // [trustedScriptUri] is either a String, in which case `toString()` is an
  // identity function, or it is a TrustedScriptURL and `toString()` returns the
  // sanitized URL.
  String uriAsString = JS('', '#.toString()', trustedScriptUri);

  _eventLog.add(' - download: $hunkName from $uriAsString');

  var deferredLibraryLoader = JS('', 'self.dartDeferredLibraryLoader');
  Completer<Null> completer = Completer();

  void success() {
    _eventLog.add(' - download success: $hunkName');
    completer.complete(null);
  }

  void failure(error, String context, StackTrace? stackTrace) {
    _eventLog.add(' - download failed: $hunkName (context: $context)');
    _loadingLibraries[hunkName] = null;
    stackTrace ??= StackTrace.current;
    completer.completeError(
        DeferredLoadException('Loading $uriAsString failed: $error\n'
            'event log:\n${_eventLog.join("\n")}\n'),
        stackTrace);
  }

  var jsSuccess = convertDartClosureToJS(success, 0);
  var jsFailure = convertDartClosureToJS((error) {
    failure(unwrapException(error), 'js-failure-wrapper',
        getTraceFromException(error));
  }, 1);

  if (JS('bool', 'typeof # === "function"', deferredLibraryLoader)) {
    try {
      // Share the loadId that hunk belongs to, this will allow for any
      // additional loadId based bundling optimizations.
      JS('void', '#(#, #, #, #)', deferredLibraryLoader, uriAsString, jsSuccess,
          jsFailure, loadId);
    } catch (error, stackTrace) {
      failure(error, "invoking dartDeferredLibraryLoader hook", stackTrace);
    }
  } else if (_isWorker()) {
    // We are in a web worker. Load the code with an XMLHttpRequest.
    var xhr = JS('var', 'new XMLHttpRequest()');
    JS('void', '#.open("GET", #)', xhr, uriAsString);
    JS(
        'void',
        '#.addEventListener("load", #, false)',
        xhr,
        convertDartClosureToJS((event) {
          int status = JS('int', '#.status', xhr);
          if (status != 200) {
            failure('Request status: $status', 'worker xhr', null);
          }
          String code = JS('String', '#.responseText', xhr);
          try {
            // Create a new function to avoid getting access to current function
            // context.
            JS('void', '(new Function(#))()', code);
            success();
          } catch (error, stackTrace) {
            failure(error, 'evaluating the code in worker xhr', stackTrace);
          }
        }, 1));

    JS('void', '#.addEventListener("error", #, false)', xhr, (e) {
      failure(e, 'xhr error handler', null);
    });
    JS('void', '#.addEventListener("abort", #, false)', xhr, (e) {
      failure(e, 'xhr abort handler', null);
    });
    JS('void', '#.send()', xhr);
  } else {
    // We are in a dom-context.
    // Inject a script tag.
    var script = JS('', 'document.createElement("script")');
    JS('', '#.type = "text/javascript"', script);
    JS('', '#.src = #', script, trustedScriptUri);
    if (_cspNonce != null && _cspNonce != '') {
      JS('', '#.nonce = #', script, _cspNonce);
      JS('', '#.setAttribute("nonce", #)', script, _cspNonce);
    }
    if (_crossOrigin != null && _crossOrigin != '') {
      JS('', '#.crossOrigin = #', script, _crossOrigin);
    }
    JS('', '#.addEventListener("load", #, false)', script, jsSuccess);
    JS('', '#.addEventListener("error", #, false)', script, jsFailure);
    JS('', 'document.body.appendChild(#)', script);
  }
  _loadingLibraries[hunkName] = completer.future;
  return completer.future;
}

/// Converts a raw JavaScript array into a `List<String>`.
/// Called from generated code.
List<String> convertMainArgumentList(Object? args) {
  List<String> result = [];
  if (args == null) return result;
  if (args is JSArray) {
    for (int i = 0; i < args.length; i++) {
      JS('', '#.push(String(#[#]))', result, args, i);
    }
    return result;
  }
  // Single non-Array element. Convert to a String.
  JS('', '#.push(String(#))', result, args);
  return result;
}

class _AssertionError extends AssertionError {
  _AssertionError(Object message) : super(message);

  String toString() => "Assertion failed: " + Error.safeToString(message);
}

// [_UnreachableError] is a separate class because we always resolve
// [assertUnreachable] and want to reduce the impact of resolving possibly
// unneeded code.
class _UnreachableError extends AssertionError {
  _UnreachableError();
  String toString() => 'Assertion failed: Reached dead code';
}

@pragma('dart2js:noInline')
Never assertUnreachable() {
  throw new _UnreachableError();
}

// Hook to register new global object if necessary.
// This is currently a no-op in dart2js.
void registerGlobalObject(object) {}

// Hook to register new browser classes in dartdevc.
// This is currently a no-op in dart2js.
void applyExtension(name, nativeObject) {}

// Hook to upgrade user native-type classes in dartdevc.
// This is currently a no-op in dart2js, but used for native tests.
void applyTestExtensions(List<String> names) {}

// See tests/web_2/platform_environment_variable1_test.dart
const String testPlatformEnvironmentVariableValue = String.fromEnvironment(
    'dart2js.test.platform.environment.variable',
    defaultValue: 'not-specified');

String testingGetPlatformEnvironmentVariable() {
  return testPlatformEnvironmentVariableValue;
}

// These are used to indicate that a named parameter is required when lazily
// retrieving default values via [JsGetName.DEFAULT_VALUES_PROPERTY].
class _Required {
  const _Required();
}

const kRequiredSentinel = const _Required();
bool isRequired(Object? value) => identical(kRequiredSentinel, value);

/// Checks that [f] is a function that supports interop.
@pragma('dart2js:tryInline')
bool isJSFunction(Function f) => JS('bool', 'typeof(#) == "function"', f);

/// Asserts that if [value] is a function, it is a JavaScript function or has
/// been wrapped by [allowInterop].
///
/// This function does not recurse if [value] is a collection.
void assertInterop(Object? value) {
  assert(value is! Function || isJSFunction(value),
      'Dart function requires `allowInterop` to be passed to JavaScript.');
}

/// Like [assertInterop], except iterates over a list of arguments
/// non-recursively.
///
/// This function intentionally avoids using [assertInterop] so that this
/// function can become a no-op if assertions are disabled.
void assertInteropArgs(List<Object?> args) {
  assert(args.every((arg) => arg is! Function || isJSFunction(arg)),
      'Dart function requires `allowInterop` to be passed to JavaScript.');
}

Object? rawStartupMetrics() {
  return JS('JSArray', '#.a', JS_EMBEDDED_GLOBAL('', STARTUP_METRICS));
}

Object? rawRuntimeMetrics() {
  return JS('', '#', JS_EMBEDDED_GLOBAL('', RUNTIME_METRICS));
}

/// Wraps the given [callback] within the current Zone.
void Function(T)? wrapZoneUnaryCallback<T>(void Function(T)? callback) {
  // For performance reasons avoid wrapping if we are in the root zone.
  if (Zone.current == Zone.root) return callback;
  if (callback == null) return null;
  return Zone.current.bindUnaryCallbackGuarded(callback);
}
