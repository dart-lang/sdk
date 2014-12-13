// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _js_helper;

import 'shared/embedded_names.dart' show
    ALL_CLASSES,
    GET_ISOLATE_TAG,
    INTERCEPTED_NAMES,
    INTERCEPTORS_BY_TAG,
    LEAF_TAGS,
    METADATA,
    DEFERRED_LIBRARY_URIS,
    DEFERRED_LIBRARY_HASHES,
    INITIALIZE_LOADED_HUNK,
    IS_HUNK_LOADED;

import 'dart:collection';
import 'dart:_isolate_helper' show
    IsolateNatives,
    leaveJsAsync,
    enterJsAsync,
    isWorker;

import 'dart:async' show Future, DeferredLoadException, Completer;

import 'dart:_foreign_helper' show
    DART_CLOSURE_TO_JS,
    JS,
    JS_CALL_IN_ISOLATE,
    JS_CONST,
    JS_CURRENT_ISOLATE,
    JS_CURRENT_ISOLATE_CONTEXT,
    JS_DART_OBJECT_CONSTRUCTOR,
    JS_EFFECT,
    JS_EMBEDDED_GLOBAL,
    JS_FUNCTION_CLASS_NAME,
    JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG,
    JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG,
    JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG,
    JS_FUNCTION_TYPE_RETURN_TYPE_TAG,
    JS_FUNCTION_TYPE_TAG,
    JS_FUNCTION_TYPE_VOID_RETURN_TAG,
    JS_GET_NAME,
    JS_GET_FLAG,
    JS_HAS_EQUALS,
    JS_IS_INDEXABLE_FIELD_NAME,
    JS_NULL_CLASS_NAME,
    JS_OBJECT_CLASS_NAME,
    JS_OPERATOR_AS_PREFIX,
    JS_OPERATOR_IS_PREFIX,
    JS_SIGNATURE_NAME,
    JS_STRING_CONCAT,
    RAW_DART_FUNCTION_REF;

import 'dart:_interceptors';
import 'dart:_internal' as _symbol_dev;
import 'dart:_internal' show MappedIterable;

import 'dart:_js_names' show
    extractKeys,
    mangledNames,
    unmangleGlobalNameIfPreservedAnyways,
    unmangleAllIdentifiersIfPreservedAnyways;

part 'annotations.dart';
part 'constant_map.dart';
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

/// Helper to print the given method information to the console the first
/// time it is called with it.
@NoInline()
void traceHelper(String method) {
  if (JS('bool', '!this.cache')) {
    JS('', 'this.cache = Object.create(null)');
  }
  if (JS('bool', '!this.cache[#]', method)) {
    JS('', 'console.log(#)', method);
    JS('', 'this.cache[#] = true', method);
  }
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
    } else {
      if (mangledNames[_internalName] == null) {
        print("Warning: '$name' is used reflectively but not in MirrorsUsed. "
              "This will break minified code.");
      }
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
    var argumentCount = _arguments.length - _namedArgumentNames.length;
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
    var embeddedInterceptedNames = JS_EMBEDDED_GLOBAL('', INTERCEPTED_NAMES);
    // TODO(ngeoffray): If this functionality ever become performance
    // critical, we might want to dynamically change [interceptedNames]
    // to be a JavaScript object with intercepted names as property
    // instead of a JavaScript array.
    // TODO(floitsch): we already add stubs (tear-off getters) as properties
    // in the embedded global interceptedNames.
    // Finish the transition and always use the object as hashtable.
    bool isIntercepted =
        JS("bool",
            'Object.prototype.hasOwnProperty.call(#, #) || #.indexOf(#) !== -1',
            embeddedInterceptedNames, name, interceptedNames, name);
    if (isIntercepted) {
      receiver = interceptor;
      if (JS('bool', '# === #', object, interceptor)) {
        interceptor = null;
      }
    } else {
      interceptor = null;
    }
    bool isCatchAll = false;
    var method = JS('var', '#[#]', receiver, name);
    if (JS('bool', 'typeof # != "function"', method) ) {
      String baseName = _symbol_dev.Symbol.getName(memberName);
      method = JS('', '#[# + "*"]', receiver, baseName);
      if (method == null) {
        interceptor = getInterceptor(object);
        method = JS('', '#[# + "*"]', interceptor, baseName);
        if (method != null) {
          isIntercepted = true;
          receiver = interceptor;
        } else {
          interceptor = null;
        }
      }
      isCatchAll = true;
    }
    if (JS('bool', 'typeof # == "function"', method)) {
      if (isCatchAll) {
        return new CachedCatchAllInvocation(
            name, method, isIntercepted, interceptor);
      } else {
        return new CachedInvocation(name, method, isIntercepted, interceptor);
      }
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
  // The mangled name of this invocation.
  String mangledName;

  /// The JS function to call.
  var jsFunction;

  /// True if this is an intercepted call.
  bool isIntercepted;

  /// Non-null interceptor if this is an intercepted call through an
  /// [Interceptor].
  Interceptor cachedInterceptor;

  CachedInvocation(this.mangledName,
                   this.jsFunction,
                   this.isIntercepted,
                   this.cachedInterceptor);

  bool get isNoSuchMethod => false;
  bool get isGetterStub => JS("bool", "!!#.\$getterStub", jsFunction);

  /// Applies [jsFunction] to [victim] with [arguments].
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

class CachedCatchAllInvocation extends CachedInvocation {
  final ReflectionInfo info;

  CachedCatchAllInvocation(String name,
                           jsFunction,
                           bool isIntercepted,
                           Interceptor cachedInterceptor)
      : info = new ReflectionInfo(jsFunction),
        super(name, jsFunction, isIntercepted, cachedInterceptor);

  bool get isGetterStub => false;

  invokeOn(Object victim, List arguments) {
    var receiver = victim;
    int providedArgumentCount;
    int fullParameterCount =
        info.requiredParameterCount + info.optionalParameterCount;
    if (!isIntercepted) {
      if (arguments is JSArray) {
        providedArgumentCount = arguments.length;
        // If we need to add extra arguments before calling, we have
        // to copy the arguments array.
        if (providedArgumentCount < fullParameterCount) {
          arguments = new List.from(arguments);
        }
      } else {
        arguments = new List.from(arguments);
        providedArgumentCount = arguments.length;
      }
    } else {
      arguments = [victim]..addAll(arguments);
      if (cachedInterceptor != null) receiver = cachedInterceptor;
      providedArgumentCount = arguments.length - 1;
    }
    if (info.areOptionalParametersNamed &&
        (providedArgumentCount > info.requiredParameterCount)) {
      throw new UnimplementedNoSuchMethodError(
          "Invocation of unstubbed method '${info.reflectionName}'"
          " with ${arguments.length} arguments.");
    } else if (providedArgumentCount < info.requiredParameterCount) {
      throw new UnimplementedNoSuchMethodError(
          "Invocation of unstubbed method '${info.reflectionName}'"
          " with $providedArgumentCount arguments (too few).");
    } else if (providedArgumentCount > fullParameterCount) {
      throw new UnimplementedNoSuchMethodError(
          "Invocation of unstubbed method '${info.reflectionName}'"
          " with $providedArgumentCount arguments (too many).");
    }
    for (int i = providedArgumentCount; i < fullParameterCount; i++) {
      arguments.add(getMetadata(info.defaultValue(i)));
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
  bool get isGetterStub => false;

  invokeOn(Object victim, Invocation invocation) {
    var receiver = (interceptor == null) ? victim : interceptor;
    return receiver.noSuchMethod(invocation);
  }
}

class ReflectionInfo {
  static const int REQUIRED_PARAMETERS_INFO = 0;
  static const int OPTIONAL_PARAMETERS_INFO = 1;
  static const int FUNCTION_TYPE_INDEX = 2;
  static const int FIRST_DEFAULT_ARGUMENT = 3;

  /// A JavaScript function object.
  final jsFunction;

  /// Raw reflection information.
  final List data;

  /// Is this a getter or a setter.
  final bool isAccessor;

  /// Number of required parameters.
  final int requiredParameterCount;

  /// Number of optional parameters.
  final int optionalParameterCount;

  /// Are optional parameters named.
  final bool areOptionalParametersNamed;

  /// Either an index to the function type in the embedded `metadata` global or
  /// a JavaScript function object which can compute such a type (presumably
  /// due to free type variables).
  final functionType;

  List cachedSortedIndices;

  ReflectionInfo.internal(this.jsFunction,
                          this.data,
                          this.isAccessor,
                          this.requiredParameterCount,
                          this.optionalParameterCount,
                          this.areOptionalParametersNamed,
                          this.functionType);

  factory ReflectionInfo(jsFunction) {
    List data = JS('JSExtendableArray|Null', r'#.$reflectionInfo', jsFunction);
    if (data == null) return null;
    data = JSArray.markFixedList(data);

    int requiredParametersInfo =
        JS('int', '#[#]', data, REQUIRED_PARAMETERS_INFO);
    int requiredParameterCount = JS('int', '# >> 1', requiredParametersInfo);
    bool isAccessor = (requiredParametersInfo & 1) == 1;

    int optionalParametersInfo =
        JS('int', '#[#]', data, OPTIONAL_PARAMETERS_INFO);
    int optionalParameterCount = JS('int', '# >> 1', optionalParametersInfo);
    bool areOptionalParametersNamed = (optionalParametersInfo & 1) == 1;

    var functionType = JS('', '#[#]', data, FUNCTION_TYPE_INDEX);
    return new ReflectionInfo.internal(
        jsFunction, data, isAccessor, requiredParameterCount,
        optionalParameterCount, areOptionalParametersNamed, functionType);
  }

  String parameterName(int parameter) {
    int metadataIndex;
    if (JS_GET_FLAG('MUST_RETAIN_METADATA')) {
      metadataIndex = JS('int', '#[2 * # + # + #]', data,
          parameter, optionalParameterCount, FIRST_DEFAULT_ARGUMENT);
    } else {
      metadataIndex = JS('int', '#[# + # + #]', data,
          parameter, optionalParameterCount, FIRST_DEFAULT_ARGUMENT);
    }
    var metadata = JS_EMBEDDED_GLOBAL('', METADATA);
    return JS('String', '#[#]', metadata, metadataIndex);
  }

  List<int> parameterMetadataAnnotations(int parameter) {
    if (!JS_GET_FLAG('MUST_RETAIN_METADATA')) {
      throw new StateError('metadata has not been preserved');
    } else {
      return JS('', '#[2 * # + # + # + 1]', data, parameter,
          optionalParameterCount, FIRST_DEFAULT_ARGUMENT);
    }
  }

  int defaultValue(int parameter) {
    if (parameter < requiredParameterCount) return null;
    return JS('int', '#[# + # - #]', data,
              FIRST_DEFAULT_ARGUMENT, parameter, requiredParameterCount);
  }

  /// Returns the default value of the [parameter]th entry of the list of
  /// parameters sorted by name.
  int defaultValueInOrder(int parameter) {
    if (parameter < requiredParameterCount) return null;

    if (!areOptionalParametersNamed || optionalParameterCount == 1) {
      return defaultValue(parameter);
    }

    int index = sortedIndex(parameter - requiredParameterCount);
    return defaultValue(index);
  }

  /// Returns the default value of the [parameter]th entry of the list of
  /// parameters sorted by name.
  String parameterNameInOrder(int parameter) {
    if (parameter < requiredParameterCount) return null;

    if (!areOptionalParametersNamed ||
        optionalParameterCount == 1) {
      return parameterName(parameter);
    }

    int index = sortedIndex(parameter - requiredParameterCount);
    return parameterName(index);
  }

  /// Computes the index of the parameter in the list of named parameters sorted
  /// by their name.
  int sortedIndex(int unsortedIndex) {
    if (cachedSortedIndices == null) {
      // TODO(karlklose): cache this between [ReflectionInfo] instances or cache
      // [ReflectionInfo] instances by [jsFunction].
      cachedSortedIndices = new List(optionalParameterCount);
      Map<String, int> positions = <String, int>{};
      for (int i = 0; i < optionalParameterCount; i++) {
        int index = requiredParameterCount + i;
        positions[parameterName(index)] = index;
      }
      int index = 0;
      (positions.keys.toList()..sort()).forEach((String name) {
        cachedSortedIndices[index++] = positions[name];
      });
    }
    return cachedSortedIndices[unsortedIndex];
  }

  @NoInline()
  computeFunctionRti(jsConstructor) {
    if (JS('bool', 'typeof # == "number"', functionType)) {
      return getMetadata(functionType);
    } else if (JS('bool', 'typeof # == "function"', functionType)) {
      var fakeInstance = JS('', 'new #()', jsConstructor);
      setRuntimeTypeInfo(
          fakeInstance, JS('JSExtendableArray', '#["<>"]', fakeInstance));
      return JS('=Object|Null', r'#.apply({$receiver:#})',
                functionType, fakeInstance);
    } else {
      throw new RuntimeError('Unexpected function type');
    }
  }

  String get reflectionName => JS('String', r'#.$reflectionName', jsFunction);
}

getMetadata(int index) {
  var metadata = JS_EMBEDDED_GLOBAL('', METADATA);
  return JS('', '#[#]', metadata, index);
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
  ///
  /// In minified mode, uses the unminified names if available.
  static String formatType(String className, List typeArguments) {
    return unmangleAllIdentifiersIfPreservedAnyways
        ('$className${joinArguments(typeArguments, 0)}');
  }

  /// Returns the type of [object] as a string (including type arguments).
  ///
  /// In minified mode, uses the unminified names if available.
  static String objectTypeName(Object object) {
    String name = constructorNameFallback(getInterceptor(object));
    if (name == 'Object') {
      // Try to decompile the constructor by turning it into a string and get
      // the name out of that. If the decompiled name is a string containing an
      // identifier, we use that instead of the very generic 'Object'.
      var decompiled =
          JS('var', r'#.match(/^\s*function\s*(\S*)\s*\(/)[1]',
              JS('var', r'String(#.constructor)', object));
      if (decompiled is String)
        if (JS('bool', r'/^\w+$/.test(#)', decompiled))
          name = decompiled;
    }
    // TODO(kasperl): If the namer gave us a fresh global name, we may
    // want to remove the numeric suffix that makes it unique too.
    if (name.length > 1 && identical(name.codeUnitAt(0), DOLLAR_CHAR_VALUE)) {
      name = name.substring(1);
    }
    return formatType(name, getRuntimeTypeInfo(object));
  }

  /// In minified mode, uses the unminified names if available.
  static String objectToString(Object object) {
    String name = objectTypeName(object);
    return "Instance of '$name'";
  }

  static num dateNow() => JS('int', r'Date.now()');

  static void initTicker() {
    if (timerFrequency != null) return;
    // Start with low-resolution. We overwrite the fields if we find better.
    timerFrequency = 1000;
    timerTicks = dateNow;
    if (JS('bool', 'typeof window == "undefined"')) return;
    var window = JS('var', 'window');
    if (window == null) return;
    var performance = JS('var', '#.performance', window);
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
    requiresPreamble();
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

  static functionNoSuchMethod(function,
                              List positionalArguments,
                              Map<String, dynamic> namedArguments) {
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
      '${JS_GET_NAME("CALL_PREFIX")}\$$argumentCount$names';

    return function.noSuchMethod(
        createUnmangledInvocationMirror(
            #call,
            selectorName,
            JSInvocationMirror.METHOD,
            arguments,
            namedArgumentList));
  }

  static applyFunction(Function function,
                       List positionalArguments,
                       Map<String, dynamic> namedArguments) {
    // Dispatch on presence of named arguments to improve tree-shaking.
    //
    // This dispatch is as simple as possible to help the compiler detect the
    // common case of `null` namedArguments, either via inlining or
    // specialization.
    return namedArguments == null
        ? applyFunctionWithPositionalArguments(
            function, positionalArguments)
        : applyFunctionWithNamedArguments(
            function, positionalArguments, namedArguments);
  }

  static applyFunctionWithPositionalArguments(Function function,
                                              List positionalArguments) {
    int argumentCount = 0;
    List arguments;

    if (positionalArguments != null) {
      if (JS('bool', '# instanceof Array', positionalArguments)) {
        arguments = positionalArguments;
      } else {
        arguments = new List.from(positionalArguments);
      }
      argumentCount = JS('int', '#.length', arguments);
    } else {
      arguments = [];
    }

    String selectorName = '${JS_GET_NAME("CALL_PREFIX")}\$$argumentCount';
    var jsFunction = JS('var', '#[#]', function, selectorName);
    if (jsFunction == null) {

      // TODO(ahe): This might occur for optional arguments if there is no call
      // selector with that many arguments.

      return functionNoSuchMethod(function, positionalArguments, null);
    }
    // We bound 'this' to [function] because of how we compile
    // closures: escaped local variables are stored and accessed through
    // [function].
    return JS('var', '#.apply(#, #)', jsFunction, function, arguments);
  }

  static applyFunctionWithNamedArguments(Function function,
                                         List positionalArguments,
                                         Map<String, dynamic> namedArguments) {
    if (namedArguments.isEmpty) {
      return applyFunctionWithPositionalArguments(
          function, positionalArguments);
    }
    // TODO(ahe): The following code can be shared with
    // JsInstanceMirror.invoke.
    var interceptor = getInterceptor(function);
    var jsFunction = JS('', '#["call*"]', interceptor);

    if (jsFunction == null) {
      return functionNoSuchMethod(
          function, positionalArguments, namedArguments);
    }
    ReflectionInfo info = new ReflectionInfo(jsFunction);
    if (info == null || !info.areOptionalParametersNamed) {
      return functionNoSuchMethod(
          function, positionalArguments, namedArguments);
    }

    if (positionalArguments != null) {
      positionalArguments = new List.from(positionalArguments);
    } else {
      positionalArguments = [];
    }
    // Check the number of positional arguments is valid.
    if (info.requiredParameterCount != positionalArguments.length) {
      return functionNoSuchMethod(
          function, positionalArguments, namedArguments);
    }
    var defaultArguments = new Map();
    for (int i = 0; i < info.optionalParameterCount; i++) {
      int index = i + info.requiredParameterCount;
      var parameterName = info.parameterNameInOrder(index);
      var value = info.defaultValueInOrder(index);
      var defaultValue = getMetadata(value);
      defaultArguments[parameterName] = defaultValue;
    }
    bool bad = false;
    namedArguments.forEach((String parameter, value) {
      if (defaultArguments.containsKey(parameter)) {
        defaultArguments[parameter] = value;
      } else {
        // Extraneous named argument.
        bad = true;
      }
    });
    if (bad) {
      return functionNoSuchMethod(
          function, positionalArguments, namedArguments);
    }
    positionalArguments.addAll(defaultArguments.values);
    return JS('', '#.apply(#, #)', jsFunction, function, positionalArguments);
  }

  static _mangledNameMatchesType(String mangledName, TypeImpl type) {
    return JS('bool', '# == #', mangledName, type._typeName);
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
    var result = JS('=Object', 'Object.create(null)');
    // Deleting a property makes V8 assume that it shouldn't create a hidden
    // class for [result] and map transitions. Although these map transitions
    // pay off if there are many cache hits for the same keys, it becomes
    // really slow when there aren't many repeated hits.
    JS('void', '#.x=0', result);
    JS('void', 'delete #.x', result);
    return result;
  }

  static fetch(cache, String key) {
    return JS('', '#[#]', cache, key);
  }

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
@NoInline()
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
  var $argumentsExpr$ = '$arguments$';
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
  var $argumentsExpr$ = '$arguments$';
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
  var $argumentsExpr$ = '$arguments$';
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
abstract class Closure implements Function {
  // TODO(ahe): These constants must be in sync with
  // reflection_data_parser.dart.
  static const FUNCTION_INDEX = 0;
  static const NAME_INDEX = 1;
  static const CALL_NAME_INDEX = 2;
  static const REQUIRED_PARAMETER_INDEX = 3;
  static const OPTIONAL_PARAMETER_INDEX = 4;
  static const DEFAULT_ARGUMENTS_INDEX = 5;

  /**
   * Global counter to prevent reusing function code objects.
   *
   * V8 will share the underlying function code objects when the same string is
   * passed to "new Function".  Shared function code objects can lead to
   * sub-optimal performance due to polymorhism, and can be prevented by
   * ensuring the strings are different.
   */
  static int functionCounter = 0;

  Closure();

  /**
   * Creates a new closure class for use by implicit getters associated with a
   * method.
   *
   * In other words, creates a tear-off closure.
   *
   * Called from [closureFromTearOff] as well as from reflection when tearing
   * of a method via [:getField:].
   *
   * This method assumes that [functions] was created by the JavaScript function
   * `addStubs` in `reflection_data_parser.dart`. That is, a list of JavaScript
   * function objects with properties `$stubName` and `$callName`.
   *
   * Further assumes that [reflectionInfo] is the end of the array created by
   * [dart2js.js_emitter.ContainerBuilder.addMemberMethod] starting with
   * required parameter count.
   *
   * Caution: this function may be called when building constants.
   * TODO(ahe): Don't call this function when building constants.
   */
  static fromTearOff(receiver,
                     List functions,
                     List reflectionInfo,
                     bool isStatic,
                     jsArguments,
                     String propertyName) {
    JS_EFFECT(() {
      BoundClosure.receiverOf(JS('BoundClosure', 'void 0'));
      BoundClosure.selfOf(JS('BoundClosure', 'void 0'));
    });
    // TODO(ahe): All the place below using \$ should be rewritten to go
    // through the namer.
    var function = JS('', '#[#]', functions, 0);
    String name = JS('String|Null', '#.\$stubName', function);
    String callName = JS('String|Null', '#.\$callName', function);

    JS('', '#.\$reflectionInfo = #', function, reflectionInfo);
    ReflectionInfo info = new ReflectionInfo(function);

    var functionType = info.functionType;

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

    // We need to create a new subclass of either TearOffClosure or
    // BoundClosure.  For this, we need to create an object whose prototype is
    // the prototype is either TearOffClosure.prototype or
    // BoundClosure.prototype, respectively in pseudo JavaScript code. The
    // simplest way to access the JavaScript construction function of a Dart
    // class is to create an instance and access its constructor property.  The
    // newly created instance could in theory be used directly as the
    // prototype, but it might include additional fields that we don't need.
    // So we only use the new instance to access the constructor property and
    // use Object.create to create the desired prototype.
    var prototype = isStatic
        ? JS('TearOffClosure', 'Object.create(#.constructor.prototype)',
             new TearOffClosure())
        : JS('BoundClosure', 'Object.create(#.constructor.prototype)',
             new BoundClosure(null, null, null, null));

    JS('', '#.\$initialize = #', prototype, JS('', '#.constructor', prototype));
    var constructor = isStatic
        ? JS('', 'function(){this.\$initialize()}')
        : isCsp
            ? JS('', 'function(a,b,c,d) {this.\$initialize(a,b,c,d)}')
            : JS('',
                 'new Function("a","b","c","d",'
                     '"this.\$initialize(a,b,c,d);"+#)',
                 functionCounter++);

    // It is necessary to set the constructor property, otherwise it will be
    // "Object".
    JS('', '#.constructor = #', prototype, constructor);

    JS('', '#.prototype = #', constructor, prototype);

    // Create a closure and "monkey" patch it with call stubs.
    var trampoline = function;
    var isIntercepted = false;
    if (!isStatic) {
      if (JS('bool', '#.length == 1', jsArguments)) {
        // Intercepted call.
        isIntercepted = true;
      }
      trampoline = forwardCallTo(receiver, function, isIntercepted);
      JS('', '#.\$reflectionInfo = #', trampoline, reflectionInfo);
    } else {
      JS('', '#.\$name = #', prototype, propertyName);
    }

    var signatureFunction;
    if (JS('bool', 'typeof # == "number"', functionType)) {
      var metadata = JS_EMBEDDED_GLOBAL('', METADATA);
      // It is ok, if the access is inlined into the JS. The access is safe in
      // and outside the function. In fact we prefer if there is a textual
      // inlining.
      signatureFunction =
          JS('', '(function(s){return function(){return #[s]}})(#)',
              metadata,
              functionType);
    } else if (!isStatic
               && JS('bool', 'typeof # == "function"', functionType)) {
      var getReceiver = isIntercepted
          ? RAW_DART_FUNCTION_REF(BoundClosure.receiverOf)
          : RAW_DART_FUNCTION_REF(BoundClosure.selfOf);
      signatureFunction = JS(
        '',
        'function(f,r){'
          'return function(){'
            'return f.apply({\$receiver:r(this)},arguments)'
          '}'
        '}(#,#)', functionType, getReceiver);
    } else {
      throw 'Error in reflectionInfo.';
    }

    JS('', '#[#] = #', prototype, JS_SIGNATURE_NAME(), signatureFunction);

    JS('', '#[#] = #', prototype, callName, trampoline);
    for (int i = 1; i < functions.length; i++) {
      var stub = functions[i];
      var stubCallName = JS('String|Null', '#.\$callName', stub);
      if (stubCallName != null) {
        JS('', '#[#] = #', prototype, stubCallName,
           isStatic ? stub : forwardCallTo(receiver, stub, isIntercepted));
      }
    }

    JS('', '#["call*"] = #', prototype, trampoline);

    return constructor;
  }

  static cspForwardCall(int arity, bool isSuperCall, String stubName,
                        function) {
    var getSelf = RAW_DART_FUNCTION_REF(BoundClosure.selfOf);
    // Handle intercepted stub-names with the default slow case.
    if (isSuperCall) arity = -1;
    switch (arity) {
    case 0:
      return JS(
          '',
          'function(n,S){'
            'return function(){'
              'return S(this)[n]()'
            '}'
          '}(#,#)', stubName, getSelf);
    case 1:
      return JS(
          '',
          'function(n,S){'
            'return function(a){'
              'return S(this)[n](a)'
            '}'
          '}(#,#)', stubName, getSelf);
    case 2:
      return JS(
          '',
          'function(n,S){'
            'return function(a,b){'
              'return S(this)[n](a,b)'
            '}'
          '}(#,#)', stubName, getSelf);
    case 3:
      return JS(
          '',
          'function(n,S){'
            'return function(a,b,c){'
              'return S(this)[n](a,b,c)'
            '}'
          '}(#,#)', stubName, getSelf);
    case 4:
      return JS(
          '',
          'function(n,S){'
            'return function(a,b,c,d){'
              'return S(this)[n](a,b,c,d)'
            '}'
          '}(#,#)', stubName, getSelf);
    case 5:
      return JS(
          '',
          'function(n,S){'
            'return function(a,b,c,d,e){'
              'return S(this)[n](a,b,c,d,e)'
            '}'
          '}(#,#)', stubName, getSelf);
    default:
      return JS(
          '',
          'function(f,s){'
            'return function(){'
              'return f.apply(s(this),arguments)'
            '}'
          '}(#,#)', function, getSelf);
    }
  }

  static bool get isCsp => JS('bool', 'typeof dart_precompiled == "function"');

  static forwardCallTo(receiver, function, bool isIntercepted) {
    if (isIntercepted) return forwardInterceptedCallTo(receiver, function);
    String stubName = JS('String|Null', '#.\$stubName', function);
    int arity = JS('int', '#.length', function);
    var lookedUpFunction = JS("", "#[#]", receiver, stubName);
    // The receiver[stubName] may not be equal to the function if we try to
    // forward to a super-method. Especially when we create a bound closure
    // of a super-call we need to make sure that we don't forward back to the
    // dynamically looked up function.
    bool isSuperCall = !identical(function, lookedUpFunction);

    if (isCsp || isSuperCall || arity >= 27) {
      return cspForwardCall(arity, isSuperCall, stubName, function);
    }

    if (arity == 0) {
      return JS(
          '',
          '(new Function(#))()',
          'return function(){'
            'return this.${BoundClosure.selfFieldName()}.$stubName();'
            '${functionCounter++}'
          '}');
    }
    assert (1 <= arity && arity < 27);
    String arguments = JS(
        'String',
        '"abcdefghijklmnopqrstuvwxyz".split("").splice(0,#).join(",")',
        arity);
    return JS(
        '',
        '(new Function(#))()',
        'return function($arguments){'
          'return this.${BoundClosure.selfFieldName()}.$stubName($arguments);'
          '${functionCounter++}'
        '}');
  }

  static cspForwardInterceptedCall(int arity, bool isSuperCall,
                                   String name, function) {
    var getSelf = RAW_DART_FUNCTION_REF(BoundClosure.selfOf);
    var getReceiver = RAW_DART_FUNCTION_REF(BoundClosure.receiverOf);
    // Handle intercepted stub-names with the default slow case.
    if (isSuperCall) arity = -1;
    switch (arity) {
    case 0:
      // Intercepted functions always takes at least one argument (the
      // receiver).
      throw new RuntimeError('Intercepted function with no arguments.');
    case 1:
      return JS(
          '',
          'function(n,s,r){'
            'return function(){'
              'return s(this)[n](r(this))'
            '}'
          '}(#,#,#)', name, getSelf, getReceiver);
    case 2:
      return JS(
          '',
          'function(n,s,r){'
            'return function(a){'
              'return s(this)[n](r(this),a)'
            '}'
          '}(#,#,#)', name, getSelf, getReceiver);
    case 3:
      return JS(
          '',
          'function(n,s,r){'
            'return function(a,b){'
              'return s(this)[n](r(this),a,b)'
            '}'
          '}(#,#,#)', name, getSelf, getReceiver);
    case 4:
      return JS(
          '',
          'function(n,s,r){'
            'return function(a,b,c){'
              'return s(this)[n](r(this),a,b,c)'
            '}'
          '}(#,#,#)', name, getSelf, getReceiver);
    case 5:
      return JS(
          '',
          'function(n,s,r){'
            'return function(a,b,c,d){'
              'return s(this)[n](r(this),a,b,c,d)'
            '}'
          '}(#,#,#)', name, getSelf, getReceiver);
    case 6:
      return JS(
          '',
          'function(n,s,r){'
            'return function(a,b,c,d,e){'
              'return s(this)[n](r(this),a,b,c,d,e)'
            '}'
          '}(#,#,#)', name, getSelf, getReceiver);
    default:
      return JS(
          '',
          'function(f,s,r,a){'
            'return function(){'
              'a=[r(this)];'
              'Array.prototype.push.apply(a,arguments);'
              'return f.apply(s(this),a)'
            '}'
          '}(#,#,#)', function, getSelf, getReceiver);
    }
  }

  static forwardInterceptedCallTo(receiver, function) {
    String selfField = BoundClosure.selfFieldName();
    String receiverField = BoundClosure.receiverFieldName();
    String stubName = JS('String|Null', '#.\$stubName', function);
    int arity = JS('int', '#.length', function);
    bool isCsp = JS('bool', 'typeof dart_precompiled == "function"');
    var lookedUpFunction = JS("", "#[#]", receiver, stubName);
    // The receiver[stubName] may not be equal to the function if we try to
    // forward to a super-method. Especially when we create a bound closure
    // of a super-call we need to make sure that we don't forward back to the
    // dynamically looked up function.
    bool isSuperCall = !identical(function, lookedUpFunction);

    if (isCsp || isSuperCall || arity >= 28) {
      return cspForwardInterceptedCall(arity, isSuperCall, stubName,
                                       function);
    }
    if (arity == 1) {
      return JS(
          '',
          '(new Function(#))()',
          'return function(){'
            'return this.$selfField.$stubName(this.$receiverField);'
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
          'return this.$selfField.$stubName(this.$receiverField, $arguments);'
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

  String toString() => "Closure";
}

/// Called from implicit method getter (aka tear-off).
closureFromTearOff(receiver,
                   functions,
                   reflectionInfo,
                   isStatic,
                   jsArguments,
                   name) {
  return Closure.fromTearOff(
      receiver,
      JSArray.markFixedList(functions),
      JSArray.markFixedList(reflectionInfo),
      JS('bool', '!!#', isStatic),
      jsArguments,
      JS('String', '#', name));
}

/// Represents an implicit closure of a function.
class TearOffClosure extends Closure {
}

/// Represents a 'tear-off' closure, that is an instance method bound
/// to a specific receiver (instance).
class BoundClosure extends TearOffClosure {
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

  BoundClosure(this._self, this._target, this._receiver, this._name);

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

  @NoInline()
  static selfOf(BoundClosure closure) => closure._self;

  static targetOf(BoundClosure closure) => closure._target;

  @NoInline()
  static receiverOf(BoundClosure closure) => closure._receiver;

  static nameOf(BoundClosure closure) => closure._name;

  static String selfFieldNameCache;

  static String selfFieldName() {
    if (selfFieldNameCache == null) {
      selfFieldNameCache = computeFieldNamed('self');
    }
    return selfFieldNameCache;
  }

  static String receiverFieldNameCache;

  static String receiverFieldName() {
    if (receiverFieldNameCache == null) {
      receiverFieldNameCache = computeFieldNamed('receiver');
    }
    return receiverFieldNameCache;
  }

  @NoInline() @NoSideEffects()
  static String computeFieldNamed(String fieldName) {
    var template = new BoundClosure('self', 'target', 'receiver', 'name');
    var names = JSArray.markFixedList(
        JS('', 'Object.getOwnPropertyNames(#)', template));
    for (int i = 0; i < names.length; i++) {
      var name = names[i];
      if (JS('bool', '#[#] === #', template, name, fieldName)) {
        return JS('String', '#', name);
      }
    }
  }
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
 * The following methods are called by the runtime to implement
 * checked mode and casts. We specialize each primitive type (eg int, bool), and
 * use the compiler's convention to do is-checks on regular objects.
 */
boolConversionCheck(value) {
  if (value is bool) return value;
  // One of the following checks will always fail.
  boolTypeCheck(value);
  assert(value != null);
  return false;
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

@NoInline()
void checkDeferredIsLoaded(String loadId, String uri) {
  if (!_loadedLibraries.contains(loadId)) {
    throw new DeferredNotLoadedError(uri);
  }
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
  // Do a bool check first because it is common and faster than 'is Function'.
  if (condition is !bool) {
    if (condition is Function) condition = condition();
    if (condition is !bool) {
      throw new TypeErrorImplementation(condition, 'bool');
    }
  }
  // Compare to true to avoid boolean conversion check in checked
  // mode.
  if (true != condition) throw new AssertionError();
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

class DeferredNotLoadedError extends Error implements NoSuchMethodError {
  String libraryName;

  DeferredNotLoadedError(this.libraryName);

  String toString() {
    return "Deferred library $libraryName was not loaded.";
  }
}

abstract class RuntimeType {
  const RuntimeType();

  toRti();
}

class RuntimeFunctionType extends RuntimeType {
  final RuntimeType returnType;
  final List<RuntimeType> parameterTypes;
  final List<RuntimeType> optionalParameterTypes;
  final namedParameters;

  static var /* bool */ inAssert = false;

  RuntimeFunctionType(this.returnType,
                      this.parameterTypes,
                      this.optionalParameterTypes,
                      this.namedParameters);

  bool get isVoid => returnType is VoidRuntimeType;

  /// Called from generated code. [expression] is a Dart object and this method
  /// returns true if [this] is a supertype of [expression].
  @NoInline() @NoSideEffects()
  bool _isTest(expression) {
    var functionTypeObject = _extractFunctionTypeObjectFrom(expression);
    return functionTypeObject == null
        ? false
        : isFunctionSubtype(functionTypeObject, toRti());
  }

  @NoInline() @NoSideEffects()
  _asCheck(expression) {
    // Type inferrer doesn't think this is called with dynamic arguments.
    return _check(JS('', '#', expression), true);
  }

  @NoInline() @NoSideEffects()
  _assertCheck(expression) {
    if (inAssert) return null;
    inAssert = true; // Don't try to check this library itself.
    try {
      // Type inferrer don't think this is called with dynamic arguments.
      return _check(JS('', '#', expression), false);
    } finally {
      inAssert = false;
    }
  }

  _check(expression, bool isCast) {
    if (expression == null) return null;
    if (_isTest(expression)) return expression;

    var self = new FunctionTypeInfoDecoderRing(toRti()).toString();
    if (isCast) {
      var functionTypeObject = _extractFunctionTypeObjectFrom(expression);
      var pretty;
      if (functionTypeObject != null) {
        pretty = new FunctionTypeInfoDecoderRing(functionTypeObject).toString();
      } else {
        pretty = Primitives.objectTypeName(expression);
      }
      throw new CastErrorImplementation(pretty, self);
    } else {
      // TODO(ahe): Pass "pretty" function-type to TypeErrorImplementation?
      throw new TypeErrorImplementation(expression, self);
    }
  }

  _extractFunctionTypeObjectFrom(o) {
    var interceptor = getInterceptor(o);
    return JS('bool', '# in #', JS_SIGNATURE_NAME(), interceptor)
        ? JS('', '#[#]()', interceptor, JS_SIGNATURE_NAME())
        : null;
  }

  toRti() {
    var result = JS('=Object', '{ #: "dynafunc" }', JS_FUNCTION_TYPE_TAG());
    if (isVoid) {
      JS('', '#[#] = true', result, JS_FUNCTION_TYPE_VOID_RETURN_TAG());
    } else {
      if (returnType is! DynamicRuntimeType) {
        JS('', '#[#] = #', result, JS_FUNCTION_TYPE_RETURN_TYPE_TAG(),
           returnType.toRti());
      }
    }
    if (parameterTypes != null && !parameterTypes.isEmpty) {
      JS('', '#[#] = #', result, JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG(),
         listToRti(parameterTypes));
    }

    if (optionalParameterTypes != null && !optionalParameterTypes.isEmpty) {
      JS('', '#[#] = #', result, JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG(),
         listToRti(optionalParameterTypes));
    }

    if (namedParameters != null) {
      var namedRti = JS('=Object', 'Object.create(null)');
      var keys = extractKeys(namedParameters);
      for (var i = 0; i < keys.length; i++) {
        var name = keys[i];
        var rti = JS('', '#[#]', namedParameters, name).toRti();
        JS('', '#[#] = #', namedRti, name, rti);
      }
      JS('', '#[#] = #', result, JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG(),
         namedRti);
    }

    return result;
  }

  static listToRti(list) {
    list = JS('JSFixedArray', '#', list);
    var result = JS('JSExtendableArray', '[]');
    for (var i = 0; i < list.length; i++) {
      JS('', '#.push(#)', result, list[i].toRti());
    }
    return result;
  }

  String toString() {
    String result = '(';
    bool needsComma = false;
    if (parameterTypes != null) {
      for (var i = 0; i < parameterTypes.length; i++) {
        RuntimeType type = parameterTypes[i];
        if (needsComma) result += ', ';
        result += '$type';
        needsComma = true;
      }
    }
    if (optionalParameterTypes != null && !optionalParameterTypes.isEmpty) {
      if (needsComma) result += ', ';
      needsComma = false;
      result += '[';
      for (var i = 0; i < optionalParameterTypes.length; i++) {
        RuntimeType type = optionalParameterTypes[i];
        if (needsComma) result += ', ';
        result += '$type';
        needsComma = true;
      }
      result += ']';
    } else if (namedParameters != null) {
      if (needsComma) result += ', ';
      needsComma = false;
      result += '{';
      var keys = extractKeys(namedParameters);
      for (var i = 0; i < keys.length; i++) {
        var name = keys[i];
        if (needsComma) result += ', ';
        var rti = JS('', '#[#]', namedParameters, name).toRti();
        result += '$rti ${JS("String", "#", name)}';
        needsComma = true;
      }
      result += '}';
    }

    result += ') -> $returnType';
    return result;
  }
}

RuntimeFunctionType buildFunctionType(returnType,
                                      parameterTypes,
                                      optionalParameterTypes) {
  return new RuntimeFunctionType(
      returnType,
      parameterTypes,
      optionalParameterTypes,
      null);
}

RuntimeFunctionType buildNamedFunctionType(returnType,
                                           parameterTypes,
                                           namedParameters) {
  return new RuntimeFunctionType(
      returnType,
      parameterTypes,
      null,
      namedParameters);
}

RuntimeType buildInterfaceType(rti, typeArguments) {
  String name = JS('String|Null', r'#.name', rti);
  if (typeArguments == null || typeArguments.isEmpty) {
    return new RuntimeTypePlain(name);
  }
  return new RuntimeTypeGeneric(name, typeArguments, null);
}

class DynamicRuntimeType extends RuntimeType {
  const DynamicRuntimeType();

  String toString() => 'dynamic';

  toRti() => null;
}

RuntimeType getDynamicRuntimeType() => const DynamicRuntimeType();

class VoidRuntimeType extends RuntimeType {
  const VoidRuntimeType();

  String toString() => 'void';

  toRti() => throw 'internal error';
}

RuntimeType getVoidRuntimeType() => const VoidRuntimeType();

/**
 * Meta helper for function type tests.
 *
 * A "meta helper" is a helper function that is never called but simulates how
 * generated code behaves as far as resolution and type inference is concerned.
 */
functionTypeTestMetaHelper() {
  var dyn = JS('', 'x');
  var dyn2 = JS('', 'x');
  List fixedListOrNull = JS('JSFixedArray|Null', 'x');
  List fixedListOrNull2 = JS('JSFixedArray|Null', 'x');
  List fixedList = JS('JSFixedArray', 'x');
  // TODO(ahe): Can we use [UnknownJavaScriptObject] below?
  var /* UnknownJavaScriptObject */ jsObject = JS('=Object', 'x');

  buildFunctionType(dyn, fixedListOrNull, fixedListOrNull2);
  buildNamedFunctionType(dyn, fixedList, jsObject);
  buildInterfaceType(dyn, fixedListOrNull);
  getDynamicRuntimeType();
  getVoidRuntimeType();
  convertRtiToRuntimeType(dyn);
  dyn._isTest(dyn2);
  dyn._asCheck(dyn2);
  dyn._assertCheck(dyn2);
}

RuntimeType convertRtiToRuntimeType(rti) {
  if (rti == null) {
    return getDynamicRuntimeType();
  } else if (JS('bool', 'typeof # == "function"', rti)) {
    return new RuntimeTypePlain(JS('String', r'rti.name'));
  } else if (JS('bool', '#.constructor == Array', rti)) {
    List list = JS('JSFixedArray', '#', rti);
    String name = JS('String', r'#.name', list[0]);
    List arguments = [];
    for (int i = 1; i < list.length; i++) {
      arguments.add(convertRtiToRuntimeType(list[i]));
    }
    return new RuntimeTypeGeneric(name, arguments, rti);
  } else if (JS('bool', '"func" in #', rti)) {
    return new FunctionTypeInfoDecoderRing(rti).toRuntimeType();
  } else {
    throw new RuntimeError(
        "Cannot convert "
        "'${JS('String', 'JSON.stringify(#)', rti)}' to RuntimeType.");
  }
}

class RuntimeTypePlain extends RuntimeType {
  final String name;

  RuntimeTypePlain(this.name);

  toRti() {
    var allClasses = JS_EMBEDDED_GLOBAL('', ALL_CLASSES);
    var rti = JS('', '#[#]', allClasses, name);
    if (rti == null) throw "no type for '$name'";
    return rti;
  }

  String toString() => name;
}

class RuntimeTypeGeneric extends RuntimeType {
  final String name;
  final List<RuntimeType> arguments;
  var rti;

  RuntimeTypeGeneric(this.name, this.arguments, this.rti);

  toRti() {
    if (rti != null) return rti;
    var allClasses = JS_EMBEDDED_GLOBAL('', ALL_CLASSES);
    var result = JS('JSExtendableArray', '[#[#]]', allClasses, name);
    if (result[0] == null) {
      throw "no type for '$name<...>'";
    }
    for (RuntimeType argument in arguments) {
      JS('', '#.push(#)', result, argument.toRti());
    }
    return rti = result;
  }

  String toString() => '$name<${arguments.join(", ")}>';
}

class FunctionTypeInfoDecoderRing {
  final _typeData;
  String _cachedToString;

  FunctionTypeInfoDecoderRing(this._typeData);

  bool get _hasReturnType => JS('bool', '"ret" in #', _typeData);
  get _returnType => JS('', '#.ret', _typeData);

  bool get _isVoid => JS('bool', '!!#.void', _typeData);

  bool get _hasArguments => JS('bool', '"args" in #', _typeData);
  List get _arguments => JS('JSExtendableArray', '#.args', _typeData);

  bool get _hasOptionalArguments => JS('bool', '"opt" in #', _typeData);
  List get _optionalArguments => JS('JSExtendableArray', '#.opt', _typeData);

  bool get _hasNamedArguments => JS('bool', '"named" in #', _typeData);
  get _namedArguments => JS('=Object', '#.named', _typeData);

  RuntimeType toRuntimeType() {
    // TODO(ahe): Implement this (and update return type).
    return const DynamicRuntimeType();
  }

  String _convert(type) {
    String result = runtimeTypeToString(type);
    if (result != null) return result;
    if (JS('bool', '"func" in #', type)) {
      return new FunctionTypeInfoDecoderRing(type).toString();
    } else {
      throw 'bad type';
    }
  }

  String toString() {
    if (_cachedToString != null) return _cachedToString;
    var s = "(";
    var sep = '';
    if (_hasArguments) {
      for (var argument in _arguments) {
        s += sep;
        s += _convert(argument);
        sep = ', ';
      }
    }
    if (_hasOptionalArguments) {
      s += '$sep[';
      sep = '';
      for (var argument in _optionalArguments) {
        s += sep;
        s += _convert(argument);
        sep = ', ';
      }
      s += ']';
    }
    if (_hasNamedArguments) {
      s += '$sep{';
      sep = '';
      for (var name in extractKeys(_namedArguments)) {
        s += sep;
        s += '$name: ';
        s += _convert(JS('', '#[#]', _namedArguments, name));
        sep = ', ';
      }
      s += '}';
    }
    s += ') -> ';
    if (_isVoid) {
      s += 'void';
    } else if (_hasReturnType) {
      s += _convert(_returnType);
    } else {
      s += 'dynamic';
    }
    return _cachedToString = "$s";
  }
}

// TODO(ahe): Remove this class and call noSuchMethod instead.
class UnimplementedNoSuchMethodError extends Error
    implements NoSuchMethodError {
  final String _message;

  UnimplementedNoSuchMethodError(this._message);

  String toString() => "Unsupported operation: $_message";
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

/**
 * Returns a property name for placing data on JavaScript objects shared between
 * DOM isolates.  This happens when multiple programs are loaded in the same
 * JavaScript context (i.e. page).  The name is based on [name] but with an
 * additional part that is unique for each isolate.
 *
 * The form of the name is '___dart_$name_$id'.
 */
String getIsolateAffinityTag(String name) {
  var isolateTagGetter =
      JS_EMBEDDED_GLOBAL('', GET_ISOLATE_TAG);
  return JS('String', '#(#)', isolateTagGetter, name);
}

typedef Future<Null> LoadLibraryFunctionType();

LoadLibraryFunctionType _loadLibraryWrapper(String loadId) {
  return () => loadDeferredLibrary(loadId);
}

final Map<String, Future<Null>> _loadingLibraries = <String, Future<Null>>{};
final Set<String> _loadedLibraries = new Set<String>();

typedef void DeferredLoadCallback();

// Function that will be called every time a new deferred import is loaded.
DeferredLoadCallback deferredLoadHook;

Future<Null> loadDeferredLibrary(String loadId) {
  // For each loadId there is a list of hunk-uris to load, and a corresponding
  // list of hashes. These are stored in the app-global scope.
  var urisMap = JS_EMBEDDED_GLOBAL('', DEFERRED_LIBRARY_URIS);
  List<String> uris = JS('JSExtendableArray|Null', '#[#]', urisMap, loadId);
  var hashesMap = JS_EMBEDDED_GLOBAL('', DEFERRED_LIBRARY_HASHES);
  List<String> hashes = JS('JSExtendableArray|Null', '#[#]', hashesMap, loadId);
  if (uris == null) return new Future.value(null);
  // The indices into `uris` and `hashes` that we want to load.
  List<int> indices = new List.generate(uris.length, (i) => i);
  var isHunkLoaded = JS_EMBEDDED_GLOBAL('', IS_HUNK_LOADED);
  // Filter away indices for hunks that have already been loaded.
  List<int> indicesToLoad = indices
      .where((int i) => !JS('bool','#(#)', isHunkLoaded, hashes[i]))
      .toList();
  // Load the needed hunks.
  return Future.wait(indicesToLoad
      .map((int i) => _loadHunk(uris[i]))).then((_) {
    // Now all hunks have been loaded, we run the needed initializers.
    for (int i in indicesToLoad) {
      var initializer = JS_EMBEDDED_GLOBAL('', INITIALIZE_LOADED_HUNK);
      JS('void', '#(#)', initializer, hashes[i]);
    }
    bool updated = _loadedLibraries.add(loadId);
    if (updated && deferredLoadHook != null) {
      deferredLoadHook();
    }
  });
}

Future<Null> _loadHunk(String hunkName) {
  // TODO(ahe): Validate libraryName.  Kasper points out that you want
  // to be able to experiment with the effect of toggling @DeferLoad,
  // so perhaps we should silently ignore "bad" library names.
  Future<Null> future = _loadingLibraries[hunkName];
  if (future != null) {
    return future.then((_) => null);
  }

  String uri = IsolateNatives.thisScript;

  int index = uri.lastIndexOf('/');
  uri = '${uri.substring(0, index + 1)}$hunkName';

  if (Primitives.isJsshell || Primitives.isD8) {
    // TODO(ahe): Move this code to a JavaScript command helper script that is
    // not included in generated output.
    return _loadingLibraries[hunkName] = new Future<Null>(() {
      try {
        // Create a new function to avoid getting access to current function
        // context.
        JS('void', '(new Function(#))()', 'load("$uri")');
      } catch (error, stackTrace) {
        throw new DeferredLoadException("Loading $uri failed.");
      }
      return null;
    });
  } else if (isWorker()) {
    // We are in a web worker. Load the code with an XMLHttpRequest.
    return _loadingLibraries[hunkName] = new Future<Null>(() {
      Completer completer = new Completer<Null>();
      enterJsAsync();
      Future<Null> leavingFuture = completer.future.whenComplete(() {
        leaveJsAsync();
      });

      int index = uri.lastIndexOf('/');
      uri = '${uri.substring(0, index + 1)}$hunkName';
      var xhr = JS('dynamic', 'new XMLHttpRequest()');
      JS('void', '#.open("GET", #)', xhr, uri);
      JS('void', '#.addEventListener("load", #, false)',
         xhr, convertDartClosureToJS((event) {
        if (JS('int', '#.status', xhr) != 200) {
          completer.completeError(
              new DeferredLoadException("Loading $uri failed."));
          return;
        }
        String code = JS('String', '#.responseText', xhr);
        try {
          // Create a new function to avoid getting access to current function
          // context.
          JS('void', '(new Function(#))()', code);
        } catch (error, stackTrace) {
          completer.completeError(
            new DeferredLoadException("Evaluating $uri failed."));
          return;
        }
        completer.complete(null);
      }, 1));

      var fail = convertDartClosureToJS((event) {
        new DeferredLoadException("Loading $uri failed.");
      }, 1);
      JS('void', '#.addEventListener("error", #, false)', xhr, fail);
      JS('void', '#.addEventListener("abort", #, false)', xhr, fail);

      JS('void', '#.send()', xhr);
      return leavingFuture;
    });
  }
  // We are in a dom-context.
  return _loadingLibraries[hunkName] = new Future<Null>(() {
    Completer completer = new Completer<Null>();
    // Inject a script tag.
    var script = JS('', 'document.createElement("script")');
    JS('', '#.type = "text/javascript"', script);
    JS('', '#.src = #', script, uri);
    JS('', '#.addEventListener("load", #, false)',
       script, convertDartClosureToJS((event) {
      completer.complete(null);
    }, 1));
    JS('', '#.addEventListener("error", #, false)',
       script, convertDartClosureToJS((event) {
      completer.completeError(
          new DeferredLoadException("Loading $uri failed."));
    }, 1));
    JS('', 'document.body.appendChild(#)', script);

    return completer.future;
  });
}

class MainError extends Error implements NoSuchMethodError {
  final String _message;

  MainError(this._message);

  String toString() => 'NoSuchMethodError: $_message';
}

void missingMain() {
  throw new MainError("No top-level function named 'main'.");
}

void badMain() {
  throw new MainError("'main' is not a function.");
}

void mainHasTooManyParameters() {
  throw new MainError("'main' expects too many parameters.");
}
