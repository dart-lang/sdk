// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _js_helper;

import 'dart:collection';
import 'dart:_foreign_helper' show DART_CLOSURE_TO_JS,
                                   JS,
                                   JS_CALL_IN_ISOLATE,
                                   JS_CONST,
                                   JS_CURRENT_ISOLATE,
                                   JS_CURRENT_ISOLATE_CONTEXT,
                                   JS_DART_OBJECT_CONSTRUCTOR,
                                   JS_FUNCTION_CLASS_NAME,
                                   JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG,
                                   JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG,
                                   JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG,
                                   JS_FUNCTION_TYPE_RETURN_TYPE_TAG,
                                   JS_FUNCTION_TYPE_TAG,
                                   JS_FUNCTION_TYPE_VOID_RETURN_TAG,
                                   JS_GET_NAME,
                                   JS_HAS_EQUALS,
                                   JS_IS_INDEXABLE_FIELD_NAME,
                                   JS_OBJECT_CLASS_NAME,
                                   JS_NULL_CLASS_NAME,
                                   JS_OPERATOR_AS_PREFIX,
                                   JS_OPERATOR_IS_PREFIX,
                                   JS_SIGNATURE_NAME,
                                   RAW_DART_FUNCTION_REF;
import 'dart:_interceptors';
import 'dart:_collection-dev' as _symbol_dev;

import 'dart:_js_names' show
    mangledNames,
    unmangleGlobalNameIfPreservedAnyways;

part 'constant_map.dart';
part 'native_helper.dart';
part 'regexp_helper.dart';
part 'string_helper.dart';
part 'js_rti.dart';

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
  var res = value.toString();
  if (res is !String) throw new ArgumentError(value);
  return res;
}

createInvocationMirror(String name, internalName, kind, arguments,
                       argumentNames) {
  return new JSInvocationMirror(name,
                                internalName,
                                kind,
                                arguments,
                                argumentNames);
}

createUnmangledInvocationMirror(Symbol symbol, internalName, kind, arguments,
                                argumentNames) {
  return new JSInvocationMirror(symbol,
                                internalName,
                                kind,
                                arguments,
                                argumentNames);
}

void throwInvalidReflectionError(String memberName) {
  throw new UnsupportedError("Can't use '$memberName' in reflection "
      "because it is not included in a @MirrorsUsed annotation.");
}

bool hasReflectableProperty(var jsFunction) {
  return JS('bool', '# in #', JS_GET_NAME("REFLECTABLE"), jsFunction);
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
  /** Map from argument name to index in _arguments. */
  Map<String, dynamic> _namedIndices = null;

  JSInvocationMirror(this._memberName,
                     this._internalName,
                     this._kind,
                     this._arguments,
                     this._namedArgumentNames);

  Symbol get memberName {
    if (_memberName is Symbol) return _memberName;
    String name = _memberName;
    String unmangledName = mangledNames[name];
    if (unmangledName != null) {
      name = unmangledName.split(':')[0];
    }
    _memberName = new _symbol_dev.Symbol.unvalidated(name);
    return _memberName;
  }

  bool get isMethod => _kind == METHOD;
  bool get isGetter => _kind == GETTER;
  bool get isSetter => _kind == SETTER;
  bool get isAccessor => _kind != METHOD;

  List get positionalArguments {
    if (isGetter) return const [];
    var argumentCount =
        _arguments.length - _namedArgumentNames.length;
    if (argumentCount == 0) return const [];
    var list = [];
    for (var index = 0 ; index < argumentCount ; index++) {
      list.add(_arguments[index]);
    }
    return makeLiteralListConst(list);
  }

  Map<Symbol, dynamic> get namedArguments {
    // TODO: Make maps const (issue 10471)
    if (isAccessor) return <Symbol, dynamic>{};
    int namedArgumentCount = _namedArgumentNames.length;
    int namedArgumentsStartIndex = _arguments.length - namedArgumentCount;
    if (namedArgumentCount == 0) return <Symbol, dynamic>{};
    var map = new Map<Symbol, dynamic>();
    for (int i = 0; i < namedArgumentCount; i++) {
      map[new _symbol_dev.Symbol.unvalidated(_namedArgumentNames[i])] =
          _arguments[namedArgumentsStartIndex + i];
    }
    return map;
  }

  _getCachedInvocation(Object object) {
    var interceptor = getInterceptor(object);
    var receiver = object;
    var name = _internalName;
    var arguments = _arguments;
    // TODO(ngeoffray): If this functionality ever become performance
    // critical, we might want to dynamically change [interceptedNames]
    // to be a JavaScript object with intercepted names as property
    // instead of a JavaScript array.
    bool isIntercepted =
        JS('int', '#.indexOf(#)', interceptedNames, name) != -1;
    if (isIntercepted) {
      receiver = interceptor;
      if (JS('bool', '# === #', object, interceptor)) {
        interceptor = null;
      }
    } else {
      interceptor = null;
    }
    var method = JS('var', '#[#]', receiver, name);
    if (JS('String', 'typeof #', method) == 'function') {
      if (!hasReflectableProperty(method)) {
        throwInvalidReflectionError(_symbol_dev.Symbol.getName(memberName));
      }
      return new CachedInvocation(method, isIntercepted, interceptor);
    } else {
      // In this case, receiver doesn't implement name.  So we should
      // invoke noSuchMethod instead (which will often throw a
      // NoSuchMethodError).
      return new CachedNoSuchMethodInvocation(interceptor);
    }
  }

  /// This method is called by [InstanceMirror.delegate].
  static invokeFromMirror(JSInvocationMirror invocation, Object victim) {
    var cached = invocation._getCachedInvocation(victim);
    if (cached.isNoSuchMethod) {
      return cached.invokeOn(victim, invocation);
    } else {
      return cached.invokeOn(victim, invocation._arguments);
    }
  }

  static getCachedInvocation(JSInvocationMirror invocation, Object victim) {
    return invocation._getCachedInvocation(victim);
  }
}

class CachedInvocation {
  /// The JS function to call.
  var jsFunction;

  /// True if this is an intercepted call.
  bool isIntercepted;

  /// Non-null interceptor if this is an intercepted call through an
  /// [Interceptor].
  Interceptor cachedInterceptor;

  CachedInvocation(this.jsFunction, this.isIntercepted, this.cachedInterceptor);

  bool get isNoSuchMethod => false;

  /// Applies [jsFunction] to object with [arguments].
  /// Users of this class must take care to check the arguments first.
  invokeOn(Object victim, List arguments) {
    var receiver = victim;
    if (!isIntercepted) {
      if (arguments is! JSArray) arguments = new List.from(arguments);
    } else {
      arguments = [victim]..addAll(arguments);
      if (cachedInterceptor != null) receiver = cachedInterceptor;
    }
    return JS("var", "#.apply(#, #)", jsFunction, receiver, arguments);
  }
}

class CachedNoSuchMethodInvocation {
  /// Non-null interceptor if this is an intercepted call through an
  /// [Interceptor].
  var interceptor;

  CachedNoSuchMethodInvocation(this.interceptor);

  bool get isNoSuchMethod => true;

  invokeOn(Object victim, Invocation invocation) {
    var receiver = (interceptor == null) ? victim : interceptor;
    return receiver.noSuchMethod(invocation);
  }
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

  static computeGlobalThis() => JS('', 'function() { return this; }()');

  static _throwFormatException(String string) {
    throw new FormatException(string);
  }

  static int parseInt(String source,
                      int radix,
                      int handleError(String source)) {
    if (handleError == null) handleError = _throwFormatException;

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
    return JS('num', r'parseInt(#, #)', source, radix);
  }

  static double parseDouble(String source, double handleError(String source)) {
    checkString(source);
    if (handleError == null) handleError = _throwFormatException;
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

  /// Creates a string containing the complete type for the class [className]
  /// with the given type arguments.
  static String formatType(String className, List typeArguments) {
    return '$className${joinArguments(typeArguments, 0)}';
  }

  /// Returns the type of [object] as a string (including type arguments).
  static String objectTypeName(Object object) {
    String name = constructorNameFallback(getInterceptor(object));
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
    if (identical(name.codeUnitAt(0), DOLLAR_CHAR_VALUE)) {
      name = name.substring(1);
    }
    return formatType(name, getRuntimeTypeInfo(object));
  }

  static String objectToString(Object object) {
    String name = objectTypeName(object);
    return "Instance of '$name'";
  }

  static List newGrowableList(length) {
    return JS('JSExtendableArray', r'new Array(#)', length);
  }

  static List newFixedList(length) {
    var result = JS('JSFixedArray', r'new Array(#)', length);
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
    if (JS('bool', 'typeof self != "undefined"')) {
      return JS('String', 'self.location.href');
    }

    // In JavaScript shells try to determine the current working
    // directory.
    var workingDirectory;
    if (isD8) {
      // TODO(sgjesse): This does not work on Windows.
      workingDirectory = JS('String', 'os.system("pwd")');
      var length = workingDirectory.length;
      if (workingDirectory[length - 1] == '\n') {
        workingDirectory = workingDirectory.substring(0, length - 1);
      }
    }

    if (isJsshell) {
      // TODO(sgjesse): This does not work on Windows.
      workingDirectory = JS('String', 'environment["PWD"]');
    }

    return workingDirectory != null
        ? "file://" + workingDirectory + "/"
        : null;
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

  static String stringConcatUnchecked(String string1, String string2) {
    return JS('String', r'# + #', string1, string2);
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

    if (JS('bool', r'# in #', JS_GET_NAME('CALL_CATCH_ALL'), function)) {
      // We expect the closure to have a "call$catchAll" (the value of
      // JS_GET_NAME('CALL_CATCH_ALL')) function that returns all the expected
      // named parameters as a (new) JavaScript object literal.  The keys in
      // the object literal correspond to the argument names, and the values
      // are the default values. The compiler emits the properties sorted by
      // keys, and this order is preserved in JavaScript, so we don't need to
      // sort the keys. Since a new object is returned each time we call
      // call$catchAll, we can simply overwrite default entries with the
      // provided named arguments. If there are incorrectly named arguments in
      // [namedArguments], noSuchMethod will be called as expected.
      var allNamedArguments =
          JS('var', r'#[#]()', function, JS_GET_NAME('CALL_CATCH_ALL'));
      if (namedArguments != null && !namedArguments.isEmpty) {
        namedArguments.forEach((String key, argument) {
          JS('void', '#[#] = #', allNamedArguments, key, argument);
        });
      }
      List<String> listOfNamedArguments =
          JS('List', 'Object.getOwnPropertyNames(#)', allNamedArguments);
      argumentCount += listOfNamedArguments.length;
      listOfNamedArguments.forEach((String name) {
        buffer.write('\$$name');
        arguments.add(JS('', '#[#]', allNamedArguments, name));
      });
    } else {
      if (namedArguments != null && !namedArguments.isEmpty) {
        namedArguments.forEach((String name, argument) {
          buffer.write('\$$name');
          arguments.add(argument);
          argumentCount++;
        });
      }
    }

    String selectorName = 'call\$$argumentCount$buffer';
    var jsFunction = JS('var', '#[#]', function, selectorName);
    if (jsFunction == null) {
      return function.noSuchMethod(createUnmangledInvocationMirror(
          const Symbol('call'),
          selectorName,
          JSInvocationMirror.METHOD,
          arguments,
          namedArguments == null ? [] : namedArguments.keys.toList()));
    }
    // We bound 'this' to [function] because of how we compile
    // closures: escaped local variables are stored and accessed through
    // [function].
    return JS('var', '#.apply(#, #)', jsFunction, function, arguments);
  }

  static getConstructorOrInterceptor(String className) {
    // TODO(ahe): Generalize this and improve test coverage of
    // reflecting on intercepted classes.
    if (JS('bool', '# == "String"', className)) return const JSString();
    if (JS('bool', '# == "int"', className)) return const JSInt();
    if (JS('bool', '# == "double"', className)) return const JSDouble();
    if (JS('bool', '# == "num"', className)) return const JSNumber();
    if (JS('bool', '# == "bool"', className)) return const JSBool();
    if (JS('bool', '# == "List"', className)) return const JSArray();
    return JS('var', 'init.allClasses[#]', className);
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

/// Helper class for allocating and using JS object literals as caches.
class JsCache {
  /// Returns a JavaScript object suitable for use as a cache.
  static allocate() {
    var result = JS('=Object', '{x:0}');
    // Deleting a property makes V8 assume that it shouldn't create a hidden
    // class for [result] and map transitions. Although these map transitions
    // pay off if there are many cache hits for the same keys, it becomes
    // really slow when there aren't many repeated hits.
    JS('void', 'delete #.x', result);
    return result;
  }

  static fetch(cache, String key) => JS('', '#[#]', cache, key);

  static void update(cache, String key, value) {
    JS('void', '#[#] = #', cache, key, value);
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
 * access.  This may also be called when the index is not an integer, in
 * which case it throws an illegal-argument exception instead, like
 * [iae], or when the receiver is null.
 */
ioore(receiver, index) {
  if (receiver == null) receiver.length; // Force a NoSuchMethodError.
  if (index is !int) iae(index);
  throw new RangeError.value(index);
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

/**
 * Wrap the given Dart object and record a stack trace.
 *
 * The code in [unwrapException] deals with getting the original Dart
 * object out of the wrapper again.
 */
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
    JS('void', 'Object.defineProperty(#, "message", { get: # })',
       wrapper, DART_CLOSURE_TO_JS(toStringWrapper));
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

/**
 * This wraps the exception and does the throw.  It is possible to call this in
 * a JS expression context, where the throw statement is not allowed.  Helpers
 * are never inlined, so we don't risk inlining the throw statement into an
 * expression context.
 */
throwExpression(ex) {
  JS('void', 'throw #', wrapException(ex));
}

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
 * Helper class for building patterns recognizing native type errors.
 */
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

  TypeErrorDecoder(this._arguments,
                   this._argumentsExpr,
                   this._expr,
                   this._method,
                   this._receiver,
                   this._pattern);

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
    var match = JS('JSExtendableArray|Null',
        'new RegExp(#).exec(#)', _pattern, message);
    if (match == null) return null;
    var result = JS('', '{}');
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
    return JS('', r'{ $method$: null, '
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
    message = JS('String', r"#.replace(String({}), '$receiver$')", message);

    // Since we want to create a new regular expression from an unknown string,
    // we must escape all regular expression syntax.
    message = JS('String', r"#.replace(new RegExp(#, 'g'), '\\$&')",
                 message, ESCAPE_REGEXP);

    // Look for the special pattern \$camelCase\$ (all the $ symbols
    // have been escaped already), as we will soon be inserting
    // regular expression syntax that we want interpreted by RegExp.
    List<String> match =
        JS('JSExtendableArray|Null', r"#.match(/\\\$[a-zA-Z]+\\\$/g)", message);
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
    String pattern = JS('String',
                        r"#.replace('\\$arguments\\$', '((?:x|[^x])*)')"
                        r".replace('\\$argumentsExpr\\$',  '((?:x|[^x])*)')"
                        r".replace('\\$expr\\$',  '((?:x|[^x])*)')"
                        r".replace('\\$method\\$',  '((?:x|[^x])*)')"
                        r".replace('\\$receiver\\$',  '((?:x|[^x])*)')",
                        message);

    return new TypeErrorDecoder(arguments,
                                argumentsExpr,
                                expr,
                                method,
                                receiver,
                                pattern);
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
  var $argumentsExpr$ = '$arguments$'
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
  var $argumentsExpr$ = '$arguments$'
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
  var $argumentsExpr$ = '$arguments$'
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
 * Called from catch blocks in generated code to extract the Dart
 * exception from the thrown value. The thrown value may have been
 * created by [wrapException] or it may be a 'native' JS exception.
 *
 * Some native exceptions are mapped to new Dart instances, others are
 * returned unmodified.
 */
unwrapException(ex) {
  /// If error implements Error, save [ex] in [error.$thrownJsError].
  /// Otherwise, do nothing. Later, the stack trace can then be extraced from
  /// [ex].
  saveStackTrace(error) {
    if (error is Error) {
      var thrownStackTrace = JS('', r'#.$thrownJsError', error);
      if (thrownStackTrace == null) {
        JS('void', r'#.$thrownJsError = #', error, ex);
      }
    }
    return error;
  }

  // Note that we are checking if the object has the property. If it
  // has, it could be set to null if the thrown value is null.
  if (ex == null) return null;
  if (JS('bool', 'typeof # !== "object"', ex)) return ex;

  if (JS('bool', r'"dartException" in #', ex)) {
    return saveStackTrace(JS('', r'#.dartException', ex));
  } else if (!JS('bool', r'"message" in #', ex)) {
    return ex;
  }

  // Grab hold of the exception message. This field is available on
  // all supported browsers.
  var message = JS('var', r'#.message', ex);

  // Internet Explorer has an error number.  This is the most reliable way to
  // detect specific errors, so check for this first.
  if (JS('bool', '"number" in #', ex)
      && JS('bool', 'typeof #.number == "number"', ex)) {
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
            new JsNoSuchMethodError('$message (Error $ieErrorCode)', null));
      case 445:
      case 5007:
        return saveStackTrace(
            new NullError('$message (Error $ieErrorCode)', null));
      }
    }
  }

  if (JS('bool', r'# instanceof TypeError', ex)) {
    var match;
    // Using JS to give type hints to the compiler to help tree-shaking.
    // TODO(ahe): That should be unnecessary due to type inference.
    var nsme =
        JS('TypeErrorDecoder', '#', TypeErrorDecoder.noSuchMethodPattern);
    var notClosure =
        JS('TypeErrorDecoder', '#', TypeErrorDecoder.notClosurePattern);
    var nullCall =
        JS('TypeErrorDecoder', '#', TypeErrorDecoder.nullCallPattern);
    var nullLiteralCall =
        JS('TypeErrorDecoder', '#', TypeErrorDecoder.nullLiteralCallPattern);
    var undefCall =
        JS('TypeErrorDecoder', '#', TypeErrorDecoder.undefinedCallPattern);
    var undefLiteralCall =
        JS('TypeErrorDecoder', '#',
           TypeErrorDecoder.undefinedLiteralCallPattern);
    var nullProperty =
        JS('TypeErrorDecoder', '#', TypeErrorDecoder.nullPropertyPattern);
    var nullLiteralProperty =
        JS('TypeErrorDecoder', '#',
           TypeErrorDecoder.nullLiteralPropertyPattern);
    var undefProperty =
        JS('TypeErrorDecoder', '#', TypeErrorDecoder.undefinedPropertyPattern);
    var undefLiteralProperty =
        JS('TypeErrorDecoder', '#',
           TypeErrorDecoder.undefinedLiteralPropertyPattern);
    if ((match = nsme.matchTypeError(message)) != null) {
      return saveStackTrace(new JsNoSuchMethodError(message, match));
    } else if ((match = notClosure.matchTypeError(message)) != null) {
      // notClosure may match "({c:null}).c()" or "({c:1}).c()", so we
      // cannot tell if this an attempt to invoke call on null or a
      // non-function object.
      // But we do know the method name is "call".
      JS('', '#.method = "call"', match);
      return saveStackTrace(new JsNoSuchMethodError(message, match));
    } else if ((match = nullCall.matchTypeError(message)) != null ||
               (match = nullLiteralCall.matchTypeError(message)) != null ||
               (match = undefCall.matchTypeError(message)) != null ||
               (match = undefLiteralCall.matchTypeError(message)) != null ||
               (match = nullProperty.matchTypeError(message)) != null ||
               (match = nullLiteralCall.matchTypeError(message)) != null ||
               (match = undefProperty.matchTypeError(message)) != null ||
               (match = undefLiteralProperty.matchTypeError(message)) != null) {
      return saveStackTrace(new NullError(message, match));
    }

    // If we cannot determine what kind of error this is, we fall back
    // to reporting this as a generic error. It's probably better than
    // nothing.
    return saveStackTrace(
        new UnknownJsTypeError(message is String ? message : ''));
  }

  if (JS('bool', r'# instanceof RangeError', ex)) {
    if (message is String && contains(message, 'call stack')) {
      return new StackOverflowError();
    }

    // In general, a RangeError is thrown when trying to pass a number
    // as an argument to a function that does not allow a range that
    // includes that number.
    return saveStackTrace(new ArgumentError());
  }

  // Check for the Firefox specific stack overflow signal.
  if (JS('bool',
         r'typeof InternalError == "function" && # instanceof InternalError',
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
makeLiteralMap(keyValuePairs) {
  return fillLiteralMap(keyValuePairs, new LinkedHashMap());
}

makeConstantMap(keyValuePairs) {
  return fillLiteralMap(keyValuePairs,
      new LinkedHashMap(equals: identical, hashCode: objectHashCode));
}

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

invokeClosure(Function closure,
              var isolate,
              int numberOfArguments,
              var arg1,
              var arg2,
              var arg3,
              var arg4) {
  if (numberOfArguments == 0) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure());
  } else if (numberOfArguments == 1) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1));
  } else if (numberOfArguments == 2) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1, arg2));
  } else if (numberOfArguments == 3) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1, arg2, arg3));
  } else if (numberOfArguments == 4) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1, arg2, arg3, arg4));
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

  // We use $0 and $1 to not clash with variable names used by the
  // compiler and/or minifier.
  function = JS('var',
                '(function(closure, arity, context, invoke) {'
                '  return function(a1, a2, a3, a4) {'
                '     return invoke(closure, context, arity, a1, a2, a3, a4);'
                '  };'
                '})(#,#,#,#)',
                closure,
                arity,
                // Capture the current isolate now.  Remember that "#"
                // in JS is simply textual substitution of compiled
                // expressions.
                JS_CURRENT_ISOLATE_CONTEXT(),
                DART_CLOSURE_TO_JS(invokeClosure));

  JS('void', r'#.$identity = #', closure, function);
  return function;
}

/**
 * Super class for Dart closures.
 */
class Closure implements Function {
  String toString() => "Closure";
}

/// Represents a 'tear-off' closure, that is an instance method bound
/// to a specific receiver (instance).
class BoundClosure extends Closure {
  /// The receiver or interceptor.
  // TODO(ahe): This could just be the interceptor, we always know if
  // we need the interceptor when generating the call method.
  final _self;

  /// The method.
  final _target;

  /// The receiver. Null if [_self] is not an interceptor.
  final _receiver;

  /// The name of the function. Only used by the mirror system.
  final String _name;

  bool operator==(other) {
    if (identical(this, other)) return true;
    if (other is! BoundClosure) return false;
    return JS('bool', '# === # && # === # && # === #',
        _self, other._self,
        _target, other._target,
        _receiver, other._receiver);
  }

  int get hashCode {
    int receiverHashCode;
    if (_receiver == null) {
      // A bound closure on a regular Dart object, just use the
      // identity hash code.
      receiverHashCode = Primitives.objectHashCode(_self);
    } else if (JS('String', 'typeof #', _receiver) != 'object') {
      // A bound closure on a primitive JavaScript type. We
      // use the hashCode method we define for those primitive types.
      receiverHashCode = _receiver.hashCode;
    } else {
      // A bound closure on an intercepted native class, just use the
      // identity hash code.
      receiverHashCode = Primitives.objectHashCode(_receiver);
    }
    return receiverHashCode ^ Primitives.objectHashCode(_target);
  }

  static selfOf(BoundClosure closure) => closure._self;

  static targetOf(BoundClosure closure) => closure._target;

  static receiverOf(BoundClosure closure) => closure._receiver;

  static nameOf(BoundClosure closure) => closure._name;
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
 * Represents the type dynamic. The compiler treats this specially.
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
 * For types that are supertypes of native (eg DOM) types, we use the
 * interceptor for the class because we cannot add a JS property to the
 * prototype at load time.
 */
interceptedTypeCheck(value, property) {
  if (value == null) return value;
  if ((identical(JS('String', 'typeof #', value), 'object'))
      && JS('bool', '#[#]', getInterceptor(value), property)) {
    return value;
  }
  propertyTypeError(value, property);
}

/**
 * For types that are supertypes of native (eg DOM) types, we use the
 * interceptor for the class because we cannot add a JS property to the
 * prototype at load time.
 */
interceptedTypeCast(value, property) {
  if (value == null
      || ((JS('bool', 'typeof # === "object"', value))
          && JS('bool', '#[#]', getInterceptor(value), property))) {
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
  if (JS('bool', '#[#]', getInterceptor(value), property)) return value;
  propertyTypeError(value, property);
}

numberOrStringSuperNativeTypeCast(value, property) {
  if (value == null) return value;
  if (value is String) return value;
  if (value is num) return value;
  if (JS('bool', '#[#]', getInterceptor(value), property)) return value;
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
  if (JS('bool', '#[#]', getInterceptor(value), property)) return value;
  propertyTypeError(value, property);
}

stringSuperNativeTypeCast(value, property) {
  if (value is String || value == null) return value;
  if (JS('bool', '#[#]', getInterceptor(value), property)) return value;
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
  if (JS('bool', '#[#]', getInterceptor(value), property)) return value;
  propertyTypeError(value, property);
}

listSuperNativeTypeCast(value, property) {
  if (value is List || value == null) return value;
  if (JS('bool', '#[#]', getInterceptor(value), property)) return value;
  propertyTypeCastError(value, property);
}

voidTypeCheck(value) {
  if (value == null) return value;
  throw new TypeErrorImplementation(value, 'void');
}

checkMalformedType(value, message) {
  if (value == null) return value;
  throw new TypeErrorImplementation.fromMessage(message);
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
  Symbol memberName = new _symbol_dev.Symbol.unvalidated(name);
  throw new NoSuchMethodError(obj, memberName, arguments,
                              new Map<Symbol, dynamic>(),
                              expectedArgumentNames);
}

/**
 * Called by generated code when a static field's initializer references the
 * field that is currently being initialized.
 */
void throwCyclicInit(String staticName) {
  throw new CyclicInitializationError(
      "Cyclic initialization for static $staticName");
}

/**
 * Error thrown when a runtime error occurs.
 */
class RuntimeError extends Error {
  final message;
  RuntimeError(this.message);
  String toString() => "RuntimeError: $message";
}
