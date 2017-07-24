// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _js_helper;

import 'dart:_js_embedded_names'
    show
        DEFERRED_LIBRARY_URIS,
        DEFERRED_LIBRARY_HASHES,
        GET_TYPE_FROM_NAME,
        GET_ISOLATE_TAG,
        INITIALIZE_LOADED_HUNK,
        INTERCEPTED_NAMES,
        INTERCEPTORS_BY_TAG,
        IS_HUNK_LOADED,
        IS_HUNK_INITIALIZED,
        JsBuiltin,
        JsGetName,
        LEAF_TAGS,
        NATIVE_SUPERCLASS_TAG_NAME,
        STATIC_FUNCTION_NAME_PROPERTY_NAME;

import 'dart:collection';

import 'dart:_isolate_helper'
    show IsolateNatives, enterJsAsync, isWorker, leaveJsAsync;

import 'dart:async'
    show
        Completer,
        DeferredLoadException,
        Future,
        StreamController,
        Stream,
        StreamSubscription,
        scheduleMicrotask,
        Zone;

import 'dart:_foreign_helper'
    show
        DART_CLOSURE_TO_JS,
        JS,
        JS_BUILTIN,
        JS_CALL_IN_ISOLATE,
        JS_CONST,
        JS_CURRENT_ISOLATE_CONTEXT,
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
    show EfficientLengthIterable, MappedIterable, IterableElementError;

import 'dart:_native_typed_data';

import 'dart:_js_names'
    show
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
part 'linked_hash_map.dart';

/// Marks the internal map in dart2js, so that internal libraries can is-check
/// them.
abstract class InternalMap {}

/// Extracts the JavaScript-constructor name from the given isCheckProperty.
// TODO(floitsch): move this to foreign_helper.dart or similar.
@ForceInline()
String isCheckPropertyToJsConstructorName(String isCheckProperty) {
  return JS_BUILTIN('returns:String;depends:none;effects:none',
      JsBuiltin.isCheckPropertyToJsConstructorName, isCheckProperty);
}

/// Returns true if the given [type] is a function type object.
// TODO(floitsch): move this to foreign_helper.dart or similar.
@ForceInline()
bool isDartFunctionType(Object type) {
  return JS_BUILTIN(
      'returns:bool;effects:none;depends:none', JsBuiltin.isFunctionType, type);
}

/// Creates a function type object.
// TODO(floitsch): move this to foreign_helper.dart or similar.
@ForceInline()
createDartFunctionTypeRti() {
  return JS_BUILTIN('returns:=Object;effects:none;depends:none',
      JsBuiltin.createFunctionTypeRti);
}

/// Retrieves the class name from type information stored on the constructor of
/// [type].
// TODO(floitsch): move this to foreign_helper.dart or similar.
@ForceInline()
String rawRtiToJsConstructorName(Object rti) {
  return JS_BUILTIN('String', JsBuiltin.rawRtiToJsConstructorName, rti);
}

/// Returns the rti from the given [constructorName].
// TODO(floitsch): make this a builtin.
jsConstructorNameToRti(String constructorName) {
  var getTypeFromName = JS_EMBEDDED_GLOBAL('', GET_TYPE_FROM_NAME);
  return JS('', '#(#)', getTypeFromName, constructorName);
}

/// Returns the raw runtime type of the given object [o].
///
/// The argument [o] must be the interceptor for primitive types. If
/// necessary run it through [getInterceptor] first.
// TODO(floitsch): move this to foreign_helper.dart or similar.
// TODO(floitsch): we should call getInterceptor ourselves, but currently
//    getInterceptor is not GVNed.
@ForceInline()
Object getRawRuntimeType(Object o) {
  return JS_BUILTIN('', JsBuiltin.rawRuntimeType, o);
}

/// Returns whether the given [type] is a subtype of [other].
///
/// The argument [other] is the name of the other type, as computed by
/// [runtimeTypeToString].
@ForceInline()
bool builtinIsSubtype(type, String other) {
  return JS_BUILTIN('returns:bool;effects:none;depends:none',
      JsBuiltin.isSubtype, other, type);
}

/// Returns true if the given [type] is _the_ `Function` type.
// TODO(floitsch): move this to foreign_helper.dart or similar.
@ForceInline()
bool isDartFunctionTypeRti(Object type) {
  return JS_BUILTIN(
      'returns:bool;effects:none;depends:none',
      JsBuiltin.isGivenTypeRti,
      type,
      JS_GET_NAME(JsGetName.FUNCTION_CLASS_TYPE_NAME));
}

/// Returns true if the given [type] is _the_ `Null` type.
@ForceInline()
bool isNullType(Object type) {
  return JS_BUILTIN(
      'returns:bool;effects:none;depends:none',
      JsBuiltin.isGivenTypeRti,
      type,
      JS_GET_NAME(JsGetName.NULL_CLASS_TYPE_NAME));
}

/// Returns whether the given type is _the_ Dart Object type.
// TODO(floitsch): move this to foreign_helper.dart or similar.
@ForceInline()
bool isDartObjectTypeRti(type) {
  return JS_BUILTIN(
      'returns:bool;effects:none;depends:none',
      JsBuiltin.isGivenTypeRti,
      type,
      JS_GET_NAME(JsGetName.OBJECT_CLASS_TYPE_NAME));
}

/// Returns whether the given type is _the_ null type.
// TODO(floitsch): move this to foreign_helper.dart or similar.
@ForceInline()
bool isNullTypeRti(type) {
  return JS_BUILTIN(
      'returns:bool;effects:none;depends:none',
      JsBuiltin.isGivenTypeRti,
      type,
      JS_GET_NAME(JsGetName.NULL_CLASS_TYPE_NAME));
}

/// Returns the metadata of the given [index].
// TODO(floitsch): move this to foreign_helper.dart or similar.
@ForceInline()
getMetadata(int index) {
  return JS_BUILTIN(
      'returns:var;effects:none;depends:none', JsBuiltin.getMetadata, index);
}

/// Returns the type of the given [index].
// TODO(floitsch): move this to foreign_helper.dart or similar.
@ForceInline()
getType(int index) {
  return JS_BUILTIN(
      'returns:var;effects:none;depends:none', JsBuiltin.getType, index);
}

/// Returns a Dart closure for the global function with the given [name].
///
/// The [name] is the globally unique (minified) JavaScript name of the
/// function. The name must be in correspondence with the propertyName that is
/// used when creating a tear-off (see [fromTearOff]).
Function createDartClosureFromNameOfStaticFunction(String name) {
  return JS_BUILTIN('returns:Function',
      JsBuiltin.createDartClosureFromNameOfStaticFunction, name);
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
  if (res is! String) throw argumentErrorValue(value);
  return res;
}

createInvocationMirror(
    String name, internalName, kind, arguments, argumentNames) {
  return new JSInvocationMirror(
      name, internalName, kind, arguments, argumentNames);
}

createUnmangledInvocationMirror(
    Symbol symbol, internalName, kind, arguments, argumentNames) {
  return new JSInvocationMirror(
      symbol, internalName, kind, arguments, argumentNames);
}

void throwInvalidReflectionError(String memberName) {
  throw new UnsupportedError("Can't use '$memberName' in reflection "
      "because it is not included in a @MirrorsUsed annotation.");
}

/// Helper to print the given method information to the console the first
/// time it is called with it.
@NoInline()
void consoleTraceHelper(String method) {
  if (JS('bool', '!this.cache')) {
    JS('', 'this.cache = Object.create(null)');
  }
  if (JS('bool', '!this.cache[#]', method)) {
    JS('', 'console.log(#)', method);
    JS('', 'this.cache[#] = true', method);
  }
}

List _traceBuffer;

/// Helper to send coverage information as a POST request to a server.
@NoInline()
void postTraceHelper(int id, String name) {
  // Note: we can't move this initialization to the declaration of
  // [_traceBuffer] because [postTraceHelper] is called very early on functions
  // that define constants, this happens before getters and setters are expanded
  // and before main starts executing. This initialization here allows us to
  // skip the lazy field initialization logic.
  if (_traceBuffer == null) _traceBuffer = JS('JSArray', '[]');
  if (JS('bool', '#.length == 0', _traceBuffer)) {
    JS(
        '',
        r'''
      window.setTimeout((function(buffer) {
        return function() {
          var xhr = new XMLHttpRequest();
          xhr.open("POST", "/coverage_uri_to_amend_by_server");
          xhr.send(JSON.stringify(buffer));
          buffer.length = 0;
        };
      })(#), 1000)''',
        _traceBuffer);
  }
  JS('', '#.push([#, #])', _traceBuffer, id, name);
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

  JSInvocationMirror(this._memberName, this._internalName, this._kind,
      this._arguments, this._namedArgumentNames);

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
    for (var index = 0; index < argumentCount; index++) {
      list.add(_arguments[index]);
    }
    return JSArray.markUnmodifiableList(list);
  }

  Map<Symbol, dynamic> get namedArguments {
    if (isAccessor) return const <Symbol, dynamic>{};
    int namedArgumentCount = _namedArgumentNames.length;
    int namedArgumentsStartIndex = _arguments.length - namedArgumentCount;
    if (namedArgumentCount == 0) return const <Symbol, dynamic>{};
    var map = new Map<Symbol, dynamic>();
    for (int i = 0; i < namedArgumentCount; i++) {
      map[new _symbol_dev.Symbol.unvalidated(_namedArgumentNames[i])] =
          _arguments[namedArgumentsStartIndex + i];
    }
    return new ConstantMapView<Symbol, dynamic>(map);
  }

  _getCachedInvocation(Object object) {
    var interceptor = getInterceptor(object);
    var receiver = object;
    var name = _internalName;
    var arguments = _arguments;
    var interceptedNames = JS_EMBEDDED_GLOBAL('', INTERCEPTED_NAMES);
    bool isIntercepted = JS('bool',
        'Object.prototype.hasOwnProperty.call(#, #)', interceptedNames, name);
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
    if (JS('bool', 'typeof # != "function"', method)) {
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

  CachedInvocation(this.mangledName, this.jsFunction, this.isIntercepted,
      this.cachedInterceptor);

  bool get isNoSuchMethod => false;
  bool get isGetterStub => JS('bool', '!!#.\$getterStub', jsFunction);

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
    return JS('var', '#.apply(#, #)', jsFunction, receiver, arguments);
  }
}

class CachedCatchAllInvocation extends CachedInvocation {
  final ReflectionInfo info;

  CachedCatchAllInvocation(String name, jsFunction, bool isIntercepted,
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
    return JS('var', '#.apply(#, #)', jsFunction, receiver, arguments);
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

  ReflectionInfo.internal(
      this.jsFunction,
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
        jsFunction,
        data,
        isAccessor,
        requiredParameterCount,
        optionalParameterCount,
        areOptionalParametersNamed,
        functionType);
  }

  String parameterName(int parameter) {
    int metadataIndex;
    if (JS_GET_FLAG('MUST_RETAIN_METADATA')) {
      metadataIndex = JS('int', '#[2 * # + # + #]', data, parameter,
          optionalParameterCount, FIRST_DEFAULT_ARGUMENT);
    } else {
      metadataIndex = JS('int', '#[# + # + #]', data, parameter,
          optionalParameterCount, FIRST_DEFAULT_ARGUMENT);
    }
    var name = getMetadata(metadataIndex);
    return JS('String', '#', name);
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
    return JS('int', '#[# + # - #]', data, FIRST_DEFAULT_ARGUMENT, parameter,
        requiredParameterCount);
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

    if (!areOptionalParametersNamed || optionalParameterCount == 1) {
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
      return getType(functionType);
    } else if (JS('bool', 'typeof # == "function"', functionType)) {
      if (jsConstructor != null) {
        var fakeInstance = JS('', 'new #()', jsConstructor);
        setRuntimeTypeInfo(
            fakeInstance, JS('JSExtendableArray', '#["<>"]', fakeInstance));
        return JS('=Object|Null', r'#.apply({$receiver:#})', functionType,
            fakeInstance);
      }
      return functionType;
    } else {
      throw new RuntimeError('Unexpected function type');
    }
  }

  String get reflectionName => JS('String', r'#.$reflectionName', jsFunction);
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

  @NoInline()
  static int _parseIntError(String source, int handleError(String source)) {
    if (handleError == null) throw new FormatException(source);
    return handleError(source);
  }

  static int parseInt(
      String source, int radix, int handleError(String source)) {
    checkString(source);
    var re = JS('', r'/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i');
    var match = JS('JSExtendableArray|Null', '#.exec(#)', re, source);
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

  /// Creates a string containing the complete type for the class [className]
  /// with the given type arguments.
  ///
  /// In minified mode, uses the unminified names if available.
  ///
  /// The given [className] string generally contains the name of the JavaScript
  /// constructor of the given class.
  static String formatType(String className, List typeArguments) {
    return unmangleAllIdentifiersIfPreservedAnyways(
        '$className${joinArguments(typeArguments, 0)}');
  }

  /// Returns the type of [object] as a string (including type arguments).
  ///
  /// In minified mode, uses the unminified names if available.
  @NoInline()
  static String objectTypeName(Object object) {
    return formatType(_objectRawTypeName(object), getRuntimeTypeInfo(object));
  }

  static String _objectRawTypeName(Object object) {
    var interceptor = getInterceptor(object);
    // The interceptor is either an object (self-intercepting plain Dart class),
    // the prototype of the constructor for an Interceptor class (like
    // `JSString.prototype`, `JSNull.prototype`), or an Interceptor object
    // instance (`const JSString()`, should use `JSString.prototype`).
    //
    // These all should have a `constructor` property with a `name` property.
    String name;
    var interceptorConstructor = JS('', '#.constructor', interceptor);
    if (JS('bool', 'typeof # == "function"', interceptorConstructor)) {
      var interceptorConstructorName = JS('', '#.name', interceptorConstructor);
      if (interceptorConstructorName is String) {
        name = interceptorConstructorName;
      }
    }

    if (name == null ||
        identical(interceptor, JS_INTERCEPTOR_CONSTANT(Interceptor)) ||
        object is UnknownJavaScriptObject) {
      // Try to do better.  If we do not find something better, leave the name
      // as 'UnknownJavaScriptObject' or 'Interceptor' (or the minified name).
      //
      // When we get here via the UnknownJavaScriptObject test (for JavaScript
      // objects from outside the program), the object's constructor has a
      // better name that 'UnknownJavaScriptObject'.
      //
      // When we get here the Interceptor test (for Native classes that are
      // declared in the Dart program but have been 'folded' into Interceptor),
      // the native class's constructor name is better than the generic
      // 'Interceptor' (an abstract class).

      // Try the [constructorNameFallback]. This gets the constructor name for
      // any browser (used by [getNativeInterceptor]).
      String dispatchName = constructorNameFallback(object);
      if (dispatchName == 'Object') {
        // Try to decompile the constructor by turning it into a string and get
        // the name out of that. If the decompiled name is a string containing
        // an identifier, we use that instead of the very generic 'Object'.
        var objectConstructor = JS('', '#.constructor', object);
        if (JS('bool', 'typeof # == "function"', objectConstructor)) {
          var match = JS('var', r'#.match(/^\s*function\s*([\w$]*)\s*\(/)',
              JS('var', r'String(#)', objectConstructor));
          var decompiledName = match == null ? null : JS('var', r'#[1]', match);
          if (decompiledName is String &&
              JS('bool', r'/^\w+$/.test(#)', decompiledName)) {
            name = decompiledName;
          }
        }
        if (name == null) name = dispatchName;
      } else {
        name = dispatchName;
      }
    }

    // Type inference does not understand that [name] is now always a non-null
    // String. (There is some imprecision in the negation of the disjunction.)
    name = JS('String', '#', name);

    // TODO(kasperl): If the namer gave us a fresh global name, we may
    // want to remove the numeric suffix that makes it unique too.
    if (name.length > 1 && identical(name.codeUnitAt(0), DOLLAR_CHAR_VALUE)) {
      name = name.substring(1);
    }
    return name;
  }

  /// In minified mode, uses the unminified names if available.
  static String objectToHumanReadableString(Object object) {
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

  static String stringFromCharCode(charCode) {
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
    return '';
  }

  static int getTimeZoneOffsetInMinutes(DateTime receiver) {
    // Note that JS and Dart disagree on the sign of the offset.
    // Subtract to avoid -0.0
    return 0 - JS('int', r'#.getTimezoneOffset()', lazyAsJsDate(receiver));
  }

  static int valueFromDecomposedDate(
      years, month, day, hours, minutes, seconds, milliseconds, isUtc) {
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
    var value;
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
  // They are marked as @NoThrows() because `receiver` comes from a receiver of
  // a method on DateTime (i.e. is not `null`).

  // TODO(sra): These methods are GVN-able. dart2js should implement an
  // annotation for that.

  // TODO(sra): These methods often occur in groups (e.g. day, month and
  // year). Is it possible to factor them so that the `Date` is visible and can
  // be GVN-ed without a lot of code bloat?

  @NoSideEffects()
  @NoThrows()
  @NoInline()
  static getYear(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('int', r'(#.getUTCFullYear() + 0)', lazyAsJsDate(receiver))
        : JS('int', r'(#.getFullYear() + 0)', lazyAsJsDate(receiver));
  }

  @NoSideEffects()
  @NoThrows()
  @NoInline()
  static getMonth(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('JSUInt31', r'#.getUTCMonth() + 1', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'#.getMonth() + 1', lazyAsJsDate(receiver));
  }

  @NoSideEffects()
  @NoThrows()
  @NoInline()
  static getDay(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('JSUInt31', r'(#.getUTCDate() + 0)', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'(#.getDate() + 0)', lazyAsJsDate(receiver));
  }

  @NoSideEffects()
  @NoThrows()
  @NoInline()
  static getHours(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('JSUInt31', r'(#.getUTCHours() + 0)', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'(#.getHours() + 0)', lazyAsJsDate(receiver));
  }

  @NoSideEffects()
  @NoThrows()
  @NoInline()
  static getMinutes(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('JSUInt31', r'(#.getUTCMinutes() + 0)', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'(#.getMinutes() + 0)', lazyAsJsDate(receiver));
  }

  @NoSideEffects()
  @NoThrows()
  @NoInline()
  static getSeconds(DateTime receiver) {
    return (receiver.isUtc)
        ? JS('JSUInt31', r'(#.getUTCSeconds() + 0)', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'(#.getSeconds() + 0)', lazyAsJsDate(receiver));
  }

  @NoSideEffects()
  @NoThrows()
  @NoInline()
  static getMilliseconds(DateTime receiver) {
    return (receiver.isUtc)
        ? JS(
            'JSUInt31', r'(#.getUTCMilliseconds() + 0)', lazyAsJsDate(receiver))
        : JS('JSUInt31', r'(#.getMilliseconds() + 0)', lazyAsJsDate(receiver));
  }

  @NoSideEffects()
  @NoThrows()
  @NoInline()
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

  static functionNoSuchMethod(
      function, List positionalArguments, Map<String, dynamic> namedArguments) {
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

    return function.noSuchMethod(createUnmangledInvocationMirror(#call,
        selectorName, JSInvocationMirror.METHOD, arguments, namedArgumentList));
  }

  /**
   * Implements [Function.apply] for the lazy and startup emitters.
   *
   * There are two types of closures that can reach this function:
   *
   * 1. tear-offs (including tear-offs of static functions).
   * 2. anonymous closures.
   *
   * They are treated differently (although there are lots of similarities).
   * Both have in common that they have
   * a [JsGetName.CALL_CATCH_ALL] and
   * a [JsGetName.REQUIRED_PARAMETER_PROPERTY] property.
   *
   * If the closure supports optional parameters, then they also feature
   * a [JsGetName.DEFAULT_VALUES_PROPERTY] property.
   *
   * The catch-all property is a method that takes all arguments (including
   * all optional positional or named arguments). If the function accepts
   * optional arguments, then the default-values property stores (potentially
   * wrapped in a function) the default values for the optional arguments. If
   * the function accepts optional positional arguments, then the value is a
   * JavaScript array with the default values. Otherwise, when the function
   * accepts optional named arguments, it is a JavaScript object.
   *
   * The default-values property may either contain the value directly, or
   * it can be a function that returns the default-values when invoked.
   *
   * If the function is an anonymous closure, then the catch-all property
   * only contains a string pointing to the property that should be used
   * instead. For example, if the catch-all property contains the string
   * "call$4", then the object's "call$4" property should be used as if it was
   * the value of the catch-all property.
   */
  static applyFunction2(Function function, List positionalArguments,
      Map<String, dynamic> namedArguments) {
    // Fast shortcut for the common case.
    if (JS('bool', '# instanceof Array', positionalArguments) &&
        (namedArguments == null || namedArguments.isEmpty)) {
      // Let the compiler know that we did a type-test.
      List arguments = (JS('JSArray', '#', positionalArguments));
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

    return _genericApplyFunction2(
        function, positionalArguments, namedArguments);
  }

  static _genericApplyFunction2(Function function, List positionalArguments,
      Map<String, dynamic> namedArguments) {
    List arguments;
    if (positionalArguments != null) {
      if (JS('bool', '# instanceof Array', positionalArguments)) {
        arguments = JS('JSArray', '#', positionalArguments);
      } else {
        arguments = new List.from(positionalArguments);
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

    bool acceptsPositionalArguments =
        JS('bool', '# instanceof Array', defaultValues);

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
      List missingDefaults = JS('JSArray', '#.slice(#)', defaultValues,
          argumentCount - requiredParameterCount);
      arguments.addAll(missingDefaults);
      return JS('var', '#.apply(#, #)', jsFunction, function, arguments);
    } else {
      // Handle named arguments.

      if (argumentCount > requiredParameterCount) {
        // Tried to invoke a function that takes named parameters with
        // too many positional arguments.
        return functionNoSuchMethod(function, arguments, namedArguments);
      }

      List keys = JS('JSArray', r'Object.keys(#)', defaultValues);
      if (namedArguments == null) {
        for (String key in keys) {
          arguments.add(JS('var', '#[#]', defaultValues, key));
        }
      } else {
        int used = 0;
        for (String key in keys) {
          if (namedArguments.containsKey(key)) {
            used++;
            arguments.add(namedArguments[key]);
          } else {
            arguments.add(JS('var', r'#[#]', defaultValues, key));
          }
        }
        if (used != namedArguments.length) {
          return functionNoSuchMethod(function, arguments, namedArguments);
        }
      }
      return JS('var', r'#.apply(#, #)', jsFunction, function, arguments);
    }
  }

  static applyFunction(Function function, List positionalArguments,
      Map<String, dynamic> namedArguments) {
    // Dispatch on presence of named arguments to improve tree-shaking.
    //
    // This dispatch is as simple as possible to help the compiler detect the
    // common case of `null` namedArguments, either via inlining or
    // specialization.
    return namedArguments == null
        ? applyFunctionWithPositionalArguments(function, positionalArguments)
        : applyFunctionWithNamedArguments(
            function, positionalArguments, namedArguments);
  }

  static applyFunctionWithPositionalArguments(
      Function function, List positionalArguments) {
    List arguments;

    if (positionalArguments != null) {
      if (JS('bool', '# instanceof Array', positionalArguments)) {
        arguments = JS('JSArray', '#', positionalArguments);
      } else {
        arguments = new List.from(positionalArguments);
      }
    } else {
      arguments = [];
    }

    if (arguments.length == 0) {
      String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX0);
      if (JS('bool', '!!#[#]', function, selectorName)) {
        return JS('', '#[#]()', function, selectorName);
      }
    } else if (arguments.length == 1) {
      String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX1);
      if (JS('bool', '!!#[#]', function, selectorName)) {
        return JS('', '#[#](#[0])', function, selectorName, arguments);
      }
    } else if (arguments.length == 2) {
      String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX2);
      if (JS('bool', '!!#[#]', function, selectorName)) {
        return JS('', '#[#](#[0],#[1])', function, selectorName, arguments,
            arguments);
      }
    } else if (arguments.length == 3) {
      String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX3);
      if (JS('bool', '!!#[#]', function, selectorName)) {
        return JS('', '#[#](#[0],#[1],#[2])', function, selectorName, arguments,
            arguments, arguments);
      }
    } else if (arguments.length == 4) {
      String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX4);
      if (JS('bool', '!!#[#]', function, selectorName)) {
        return JS('', '#[#](#[0],#[1],#[2],#[3])', function, selectorName,
            arguments, arguments, arguments, arguments);
      }
    } else if (arguments.length == 5) {
      String selectorName = JS_GET_NAME(JsGetName.CALL_PREFIX5);
      if (JS('bool', '!!#[#]', function, selectorName)) {
        return JS('', '#[#](#[0],#[1],#[2],#[3],#[4])', function, selectorName,
            arguments, arguments, arguments, arguments, arguments);
      }
    }
    return _genericApplyFunctionWithPositionalArguments(function, arguments);
  }

  static _genericApplyFunctionWithPositionalArguments(
      Function function, List arguments) {
    int argumentCount = arguments.length;
    String selectorName =
        '${JS_GET_NAME(JsGetName.CALL_PREFIX)}\$$argumentCount';
    var jsFunction = JS('var', '#[#]', function, selectorName);
    if (jsFunction == null) {
      var interceptor = getInterceptor(function);
      jsFunction =
          JS('', '#[#]', interceptor, JS_GET_NAME(JsGetName.CALL_CATCH_ALL));

      if (jsFunction == null) {
        return functionNoSuchMethod(function, arguments, null);
      }
      ReflectionInfo info = new ReflectionInfo(jsFunction);
      int requiredArgumentCount = info.requiredParameterCount;
      int maxArgumentCount =
          requiredArgumentCount + info.optionalParameterCount;
      if (info.areOptionalParametersNamed ||
          requiredArgumentCount > argumentCount ||
          maxArgumentCount < argumentCount) {
        return functionNoSuchMethod(function, arguments, null);
      }
      arguments = new List.from(arguments);
      for (int pos = argumentCount; pos < maxArgumentCount; pos++) {
        arguments.add(getMetadata(info.defaultValue(pos)));
      }
    }
    // We bound 'this' to [function] because of how we compile
    // closures: escaped local variables are stored and accessed through
    // [function].
    return JS('var', '#.apply(#, #)', jsFunction, function, arguments);
  }

  static applyFunctionWithNamedArguments(Function function,
      List positionalArguments, Map<String, dynamic> namedArguments) {
    if (namedArguments.isEmpty) {
      return applyFunctionWithPositionalArguments(
          function, positionalArguments);
    }
    // TODO(ahe): The following code can be shared with
    // JsInstanceMirror.invoke.
    var interceptor = getInterceptor(function);
    var jsFunction =
        JS('', '#[#]', interceptor, JS_GET_NAME(JsGetName.CALL_CATCH_ALL));

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
@NoInline()
iae(argument) {
  throw argumentErrorValue(argument);
}

/**
 * Called by generated code to throw an index-out-of-range exception, for
 * example, if a bounds check fails in an optimized indexed access.  This may
 * also be called when the index is not an integer, in which case it throws an
 * illegal-argument exception instead, like [iae], or when the receiver is null.
 */
@NoInline()
ioore(receiver, index) {
  if (receiver == null) receiver.length; // Force a NoSuchMethodError.
  throw diagnoseIndexError(receiver, index);
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
  return new ArgumentError.value(end, 'end');
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

@NoInline()
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

/**
 * This wraps the exception and does the throw.  It is possible to call this in
 * a JS expression context, where the throw statement is not allowed.  Helpers
 * are never inlined, so we don't risk inlining the throw statement into an
 * expression context.
 */
throwExpression(ex) {
  JS('void', 'throw #', wrapException(ex));
}

throwRuntimeError(message) {
  throw new RuntimeError(message);
}

throwUnsupportedError(message) {
  throw new UnsupportedError(message);
}

throwAbstractClassInstantiationError(className) {
  throw new AbstractClassInstantiationError(className);
}

// This is used in open coded for-in loops on arrays.
//
//     checkConcurrentModificationError(a.length == startLength, a)
//
// is replaced in codegen by:
//
//     a.length == startLength || throwConcurrentModificationError(a)
//
// TODO(sra): We would like to annotate this as @NoSideEffects() so that loops
// with no other effects can recognize that the array length does not
// change. However, in the usual case where the loop does have other effects,
// that causes the length in the loop condition to be phi(startLength,a.length),
// which causes confusion in range analysis and the insertion of a bounds check.
@NoInline()
checkConcurrentModificationError(sameLength, collection) {
  if (true != sameLength) {
    throwConcurrentModificationError(collection);
  }
}

@NoInline()
throwConcurrentModificationError(collection) {
  throw new ConcurrentModificationError(collection);
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
    message = JS('String', r"#.replace(String({}), '$receiver$')", message);

    // Since we want to create a new regular expression from an unknown string,
    // we must escape all regular expression syntax.
    message = quoteStringForRegExp(message);

    // Look for the special pattern \$camelCase\$ (all the $ symbols
    // have been escaped already), as we will soon be inserting
    // regular expression syntax that we want interpreted by RegExp.
    List<String> match =
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
        r"#.replace(new RegExp('\\\\\\$arguments\\\\\\$', 'g'), "
        r"'((?:x|[^x])*)')"
        r".replace(new RegExp('\\\\\\$argumentsExpr\\\\\\$', 'g'),  "
        r"'((?:x|[^x])*)')"
        r".replace(new RegExp('\\\\\\$expr\\\\\\$', 'g'),  '((?:x|[^x])*)')"
        r".replace(new RegExp('\\\\\\$method\\\\\\$', 'g'),  '((?:x|[^x])*)')"
        r".replace(new RegExp('\\\\\\$receiver\\\\\\$', 'g'),  "
        r"'((?:x|[^x])*)')",
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

    var function = JS(
        '',
        r"""function($expr$) {
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
    var function = JS(
        '',
        r"""function() {
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
    var function = JS(
        '',
        r"""function() {
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
    var function = JS(
        '',
        r"""function($expr$) {
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
    var function = JS(
        '',
        r"""function() {
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
    var function = JS(
        '',
        r"""function() {
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

/// A wrapper around an exception, much like the one created by [wrapException]
/// but with a pre-given stack-trace.
class ExceptionAndStackTrace {
  dynamic dartException;
  StackTrace stackTrace;

  ExceptionAndStackTrace(this.dartException, this.stackTrace);
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
  /// Otherwise, do nothing. Later, the stack trace can then be extracted from
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
  if (ex is ExceptionAndStackTrace) {
    return saveStackTrace(ex.dartException);
  }
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

    // In general, a RangeError is thrown when trying to pass a number as an
    // argument to a function that does not allow a range that includes that
    // number. Translate to a Dart ArgumentError with the same message.
    // TODO(sra): Translate to RangeError.
    message = tryStringifyException(ex);
    if (message is String) {
      message = JS('String', r'#.replace(/^RangeError:\s*/, "")', message);
    }
    return saveStackTrace(new ArgumentError(message));
  }

  // Check for the Firefox specific stack overflow signal.
  if (JS(
      'bool',
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

String tryStringifyException(ex) {
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

/**
 * Called by generated code to fetch the stack trace from an
 * exception. Should never return null.
 */
StackTrace getTraceFromException(exception) {
  if (exception is ExceptionAndStackTrace) {
    return exception.stackTrace;
  }
  if (exception == null) return new _StackTrace(exception);
  _StackTrace trace = JS('_StackTrace|Null', r'#.$cachedTrace', exception);
  if (trace != null) return trace;
  trace = new _StackTrace(exception);
  return JS('_StackTrace', r'#.$cachedTrace = #', exception, trace);
}

class _StackTrace implements StackTrace {
  var _exception;
  String _trace;
  _StackTrace(this._exception);

  String toString() {
    if (_trace != null) return JS('String', '#', _trace);

    String trace;
    if (JS('bool', '# !== null', _exception) &&
        JS('bool', 'typeof # === "object"', _exception)) {
      trace = JS('String|Null', r'#.stack', _exception);
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

invokeClosure(Function closure, var isolate, int numberOfArguments, var arg1,
    var arg2, var arg3, var arg4) {
  switch (numberOfArguments) {
    case 0:
      return JS_CALL_IN_ISOLATE(isolate, () => closure());
    case 1:
      return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1));
    case 2:
      return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1, arg2));
    case 3:
      return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1, arg2, arg3));
    case 4:
      return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1, arg2, arg3, arg4));
  }
  throw new Exception('Unsupported number of arguments for wrapped closure');
}

/**
 * Called by generated code to convert a Dart closure to a JS
 * closure when the Dart closure is passed to the DOM.
 */
convertDartClosureToJS(closure, int arity) {
  if (closure == null) return null;
  var function = JS('var', r'#.$identity', closure);
  if (JS('bool', r'!!#', function)) return function;

  function = JS(
      'var',
      r'''
        (function(closure, arity, context, invoke) {
          return function(a1, a2, a3, a4) {
            return invoke(closure, context, arity, a1, a2, a3, a4);
          };
        })(#,#,#,#)''',
      closure,
      arity,
      JS_CURRENT_ISOLATE_CONTEXT(),
      DART_CLOSURE_TO_JS(invokeClosure));

  JS('void', r'#.$identity = #', closure, function);
  return function;
}

/// Superclass for Dart closures.
///
/// All static, tear-off, function declaration and function expression closures
/// extend this class, but classes that implement Function via a `call` method
/// do not.
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
   * sub-optimal performance due to polymorphism, and can be prevented by
   * ensuring the strings are different, for example, by generating a local
   * variable with a name dependent on [functionCounter].
   */
  static int functionCounter = 0;

  Closure();

  /**
   * Creates a new closure class for use by implicit getters associated with a
   * method.
   *
   * In other words, creates a tear-off closure.
   *
   * The [propertyName] argument is used by
   * [JsBuiltin.createDartClosureFromNameOfStaticFunction].
   *
   * Called from [closureFromTearOff] as well as from reflection when tearing
   * of a method via `getField`.
   *
   * This method assumes that [functions] was created by the JavaScript function
   * `addStubs` in `reflection_data_parser.dart`. That is, a list of JavaScript
   * function objects with properties `$stubName` and `$callName`.
   *
   * Further assumes that [reflectionInfo] is the end of the array created by
   * [dart2js.js_emitter.ContainerBuilder.addMemberMethod] starting with
   * required parameter count or, in case of the new emitter, the runtime
   * representation of the function's type.
   *
   * Caution: this function may be called when building constants.
   * TODO(ahe): Don't call this function when building constants.
   */
  static fromTearOff(receiver, List functions, var reflectionInfo,
      bool isStatic, jsArguments, String propertyName) {
    JS_EFFECT(() {
      // The functions are called here to model the calls from JS forms below.
      // The types in the JS forms in the arguments are propagated in type
      // inference.
      BoundClosure.receiverOf(JS('BoundClosure', '0'));
      BoundClosure.selfOf(JS('BoundClosure', '0'));
      getType(JS('int', '0'));
    });
    // TODO(ahe): All the place below using \$ should be rewritten to go
    // through the namer.
    var function = JS('', '#[#]', functions, 0);
    String name = JS('String|Null', '#.\$stubName', function);
    String callName = JS('String|Null', '#[#]', function,
        JS_GET_NAME(JsGetName.CALL_NAME_PROPERTY));

    // This variable holds either an index into the types-table, or a function
    // that can compute a function-rti. (The latter is necessary if the type
    // is dependent on generic arguments).
    var functionType;
    if (reflectionInfo is List) {
      JS('', '#.\$reflectionInfo = #', function, reflectionInfo);
      ReflectionInfo info = new ReflectionInfo(function);
      functionType = info.functionType;
    } else {
      functionType = reflectionInfo;
    }

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
    // TODO(sra): Perhaps cache the prototype to avoid the allocation.
    var prototype = isStatic
        ? JS('StaticClosure', 'Object.create(#.constructor.prototype)',
            new StaticClosure())
        : JS('BoundClosure', 'Object.create(#.constructor.prototype)',
            new BoundClosure(null, null, null, null));

    JS('', '#.\$initialize = #', prototype, JS('', '#.constructor', prototype));
    var constructor = isStatic
        ? JS('', 'function(){this.\$initialize()}')
        : isCsp
            ? JS('', 'function(a,b,c,d) {this.\$initialize(a,b,c,d)}')
            : JS(
                '',
                'new Function("a,b,c,d" + #,'
                ' "this.\$initialize(a,b,c,d" + # + ")")',
                functionCounter,
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
      JS('', '#[#] = #', prototype, STATIC_FUNCTION_NAME_PROPERTY_NAME,
          propertyName);
    }

    var signatureFunction;
    if (JS('bool', 'typeof # == "number"', functionType)) {
      // We cannot call [getType] here, since the types-metadata might not be
      // set yet. This is, because fromTearOff might be called for constants
      // when the program isn't completely set up yet.
      //
      // Note that we cannot just textually inline the call
      // `getType(functionType)` since we cannot guarantee that the (then)
      // captured variable `functionType` isn't reused.
      signatureFunction = JS(
          '',
          '''(function(getType, t) {
                    return function(){ return getType(t); };
                })(#, #)''',
          RAW_DART_FUNCTION_REF(getType),
          functionType);
    } else if (JS('bool', 'typeof # == "function"', functionType)) {
      if (isStatic) {
        signatureFunction = functionType;
      } else {
        var getReceiver = isIntercepted
            ? RAW_DART_FUNCTION_REF(BoundClosure.receiverOf)
            : RAW_DART_FUNCTION_REF(BoundClosure.selfOf);
        signatureFunction = JS(
            '',
            'function(f,r){'
            'return function(){'
            'return f.apply({\$receiver:r(this)},arguments)'
            '}'
            '}(#,#)',
            functionType,
            getReceiver);
      }
    } else {
      throw 'Error in reflectionInfo.';
    }

    JS('', '#[#] = #', prototype, JS_GET_NAME(JsGetName.SIGNATURE_NAME),
        signatureFunction);

    JS('', '#[#] = #', prototype, callName, trampoline);
    for (int i = 1; i < functions.length; i++) {
      var stub = functions[i];
      var stubCallName = JS('String|Null', '#[#]', stub,
          JS_GET_NAME(JsGetName.CALL_NAME_PROPERTY));
      if (stubCallName != null) {
        JS('', '#[#] = #', prototype, stubCallName,
            isStatic ? stub : forwardCallTo(receiver, stub, isIntercepted));
      }
    }

    JS('', '#[#] = #', prototype, JS_GET_NAME(JsGetName.CALL_CATCH_ALL),
        trampoline);
    String reqArgProperty = JS_GET_NAME(JsGetName.REQUIRED_PARAMETER_PROPERTY);
    String defValProperty = JS_GET_NAME(JsGetName.DEFAULT_VALUES_PROPERTY);
    JS('', '#.# = #.#', prototype, reqArgProperty, function, reqArgProperty);
    JS('', '#.# = #.#', prototype, defValProperty, function, defValProperty);

    return constructor;
  }

  static cspForwardCall(
      int arity, bool isSuperCall, String stubName, function) {
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
            '}(#,#)',
            stubName,
            getSelf);
      case 1:
        return JS(
            '',
            'function(n,S){'
            'return function(a){'
            'return S(this)[n](a)'
            '}'
            '}(#,#)',
            stubName,
            getSelf);
      case 2:
        return JS(
            '',
            'function(n,S){'
            'return function(a,b){'
            'return S(this)[n](a,b)'
            '}'
            '}(#,#)',
            stubName,
            getSelf);
      case 3:
        return JS(
            '',
            'function(n,S){'
            'return function(a,b,c){'
            'return S(this)[n](a,b,c)'
            '}'
            '}(#,#)',
            stubName,
            getSelf);
      case 4:
        return JS(
            '',
            'function(n,S){'
            'return function(a,b,c,d){'
            'return S(this)[n](a,b,c,d)'
            '}'
            '}(#,#)',
            stubName,
            getSelf);
      case 5:
        return JS(
            '',
            'function(n,S){'
            'return function(a,b,c,d,e){'
            'return S(this)[n](a,b,c,d,e)'
            '}'
            '}(#,#)',
            stubName,
            getSelf);
      default:
        return JS(
            '',
            'function(f,s){'
            'return function(){'
            'return f.apply(s(this),arguments)'
            '}'
            '}(#,#)',
            function,
            getSelf);
    }
  }

  static bool get isCsp => JS_GET_FLAG('USE_CONTENT_SECURITY_POLICY');

  static forwardCallTo(receiver, function, bool isIntercepted) {
    if (isIntercepted) return forwardInterceptedCallTo(receiver, function);
    String stubName = JS('String|Null', '#.\$stubName', function);
    int arity = JS('int', '#.length', function);
    var lookedUpFunction = JS('', '#[#]', receiver, stubName);
    // The receiver[stubName] may not be equal to the function if we try to
    // forward to a super-method. Especially when we create a bound closure
    // of a super-call we need to make sure that we don't forward back to the
    // dynamically looked up function.
    bool isSuperCall = !identical(function, lookedUpFunction);

    if (isCsp || isSuperCall || arity >= 27) {
      return cspForwardCall(arity, isSuperCall, stubName, function);
    }

    if (arity == 0) {
      // Incorporate functionCounter into a local.
      String selfName = 'self${functionCounter++}';
      return JS(
          '',
          '(new Function(#))()',
          'return function(){'
          'var $selfName = this.${BoundClosure.selfFieldName()};'
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
        'return this.${BoundClosure.selfFieldName()}.$stubName($arguments);'
        '}');
  }

  static cspForwardInterceptedCall(
      int arity, bool isSuperCall, String name, function) {
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
            '}(#,#,#)',
            name,
            getSelf,
            getReceiver);
      case 2:
        return JS(
            '',
            'function(n,s,r){'
            'return function(a){'
            'return s(this)[n](r(this),a)'
            '}'
            '}(#,#,#)',
            name,
            getSelf,
            getReceiver);
      case 3:
        return JS(
            '',
            'function(n,s,r){'
            'return function(a,b){'
            'return s(this)[n](r(this),a,b)'
            '}'
            '}(#,#,#)',
            name,
            getSelf,
            getReceiver);
      case 4:
        return JS(
            '',
            'function(n,s,r){'
            'return function(a,b,c){'
            'return s(this)[n](r(this),a,b,c)'
            '}'
            '}(#,#,#)',
            name,
            getSelf,
            getReceiver);
      case 5:
        return JS(
            '',
            'function(n,s,r){'
            'return function(a,b,c,d){'
            'return s(this)[n](r(this),a,b,c,d)'
            '}'
            '}(#,#,#)',
            name,
            getSelf,
            getReceiver);
      case 6:
        return JS(
            '',
            'function(n,s,r){'
            'return function(a,b,c,d,e){'
            'return s(this)[n](r(this),a,b,c,d,e)'
            '}'
            '}(#,#,#)',
            name,
            getSelf,
            getReceiver);
      default:
        return JS(
            '',
            'function(f,s,r,a){'
            'return function(){'
            'a=[r(this)];'
            'Array.prototype.push.apply(a,arguments);'
            'return f.apply(s(this),a)'
            '}'
            '}(#,#,#)',
            function,
            getSelf,
            getReceiver);
    }
  }

  static forwardInterceptedCallTo(receiver, function) {
    String selfField = BoundClosure.selfFieldName();
    String receiverField = BoundClosure.receiverFieldName();
    String stubName = JS('String|Null', '#.\$stubName', function);
    int arity = JS('int', '#.length', function);
    bool isCsp = JS_GET_FLAG('USE_CONTENT_SECURITY_POLICY');
    var lookedUpFunction = JS('', '#[#]', receiver, stubName);
    // The receiver[stubName] may not be equal to the function if we try to
    // forward to a super-method. Especially when we create a bound closure
    // of a super-call we need to make sure that we don't forward back to the
    // dynamically looked up function.
    bool isSuperCall = !identical(function, lookedUpFunction);

    if (isCsp || isSuperCall || arity >= 28) {
      return cspForwardInterceptedCall(arity, isSuperCall, stubName, function);
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

  String toString() {
    String name = Primitives.objectTypeName(this);
    // Mirrors puts a space in front of some names, so remove it.
    name = JS('String', '#.trim()', name);
    return "Closure '$name'";
  }
}

/// Called from implicit method getter (aka tear-off).
closureFromTearOff(
    receiver, functions, reflectionInfo, isStatic, jsArguments, name) {
  return Closure.fromTearOff(
      receiver,
      JSArray.markFixedList(functions),
      reflectionInfo is List
          ? JSArray.markFixedList(reflectionInfo)
          : reflectionInfo,
      JS('bool', '!!#', isStatic),
      jsArguments,
      JS('String', '#', name));
}

/// Represents an implicit closure of a function.
abstract class TearOffClosure extends Closure {}

class StaticClosure extends TearOffClosure {
  String toString() {
    String name =
        JS('String|Null', '#[#]', this, STATIC_FUNCTION_NAME_PROPERTY_NAME);
    if (name == null) return 'Closure of unknown static method';
    return "Closure '$name'";
  }
}

/// Represents a 'tear-off' or property extraction closure of an instance
/// method, that is an instance method bound to a specific receiver (instance).
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

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! BoundClosure) return false;
    return JS('bool', '# === #', _self, other._self) &&
        JS('bool', '# === #', _target, other._target) &&
        JS('bool', '# === #', _receiver, other._receiver);
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

  toString() {
    var receiver = _receiver == null ? _self : _receiver;
    return "Closure '$_name' of ${Primitives.objectToHumanReadableString(receiver)}";
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

  @NoInline()
  @NoSideEffects()
  static String computeFieldNamed(String fieldName) {
    var template = new BoundClosure('self', 'target', 'receiver', 'name');
    var names = JSArray
        .markFixedList(JS('', 'Object.getOwnPropertyNames(#)', template));
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
  throw new CastErrorImplementation(Primitives.objectTypeName(value), 'String');
}

doubleTypeCheck(value) {
  if (value == null) return value;
  if (value is double) return value;
  throw new TypeErrorImplementation(value, 'double');
}

doubleTypeCast(value) {
  if (value is double || value == null) return value;
  throw new CastErrorImplementation(Primitives.objectTypeName(value), 'double');
}

numTypeCheck(value) {
  if (value == null) return value;
  if (value is num) return value;
  throw new TypeErrorImplementation(value, 'num');
}

numTypeCast(value) {
  if (value is num || value == null) return value;
  throw new CastErrorImplementation(Primitives.objectTypeName(value), 'num');
}

boolTypeCheck(value) {
  if (value == null) return value;
  if (value is bool) return value;
  throw new TypeErrorImplementation(value, 'bool');
}

boolTypeCast(value) {
  if (value is bool || value == null) return value;
  throw new CastErrorImplementation(Primitives.objectTypeName(value), 'bool');
}

intTypeCheck(value) {
  if (value == null) return value;
  if (value is int) return value;
  throw new TypeErrorImplementation(value, 'int');
}

intTypeCast(value) {
  if (value is int || value == null) return value;
  throw new CastErrorImplementation(Primitives.objectTypeName(value), 'int');
}

void propertyTypeError(value, property) {
  String name = isCheckPropertyToJsConstructorName(property);
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
  if ((JS('bool', 'typeof # === "object"', value) ||
          JS('bool', 'typeof # === "function"', value)) &&
      JS('bool', '#[#]', getInterceptor(value), property)) {
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
  if (value == null ||
      ((JS('bool', 'typeof # === "object"', value) ||
              JS('bool', 'typeof # === "function"', value)) &&
          JS('bool', '#[#]', getInterceptor(value), property))) {
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
  throw new CastErrorImplementation(Primitives.objectTypeName(value), 'List');
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

extractFunctionTypeObjectFrom(o) {
  var interceptor = getInterceptor(o);
  var signatureName = JS_GET_NAME(JsGetName.SIGNATURE_NAME);
  return JS('bool', '# in #', signatureName, interceptor)
      ? JS('', '#[#]()', interceptor, signatureName)
      : null;
}

functionTypeTest(value, functionTypeRti) {
  if (value == null) return false;
  var functionTypeObject = extractFunctionTypeObjectFrom(value);
  return functionTypeObject == null
      ? false
      : isFunctionSubtype(functionTypeObject, functionTypeRti);
}

// Declared as 'var' to avoid assignment checks.
var _inTypeAssertion = false;

functionTypeCheck(value, functionTypeRti) {
  if (value == null) return value;

  // The function type test code contains type assertions for function
  // types. This leads to unbounded recursion, so disable the type checking of
  // function types while checking function types.

  if (true == _inTypeAssertion) return value;

  _inTypeAssertion = true;
  try {
    if (functionTypeTest(value, functionTypeRti)) return value;
    var self = runtimeTypeToString(functionTypeRti);
    throw new TypeErrorImplementation(value, self);
  } finally {
    _inTypeAssertion = false;
  }
}

functionTypeCast(value, functionTypeRti) {
  if (value == null) return value;
  if (functionTypeTest(value, functionTypeRti)) return value;

  var self = runtimeTypeToString(functionTypeRti);
  var functionTypeObject = extractFunctionTypeObjectFrom(value);
  var pretty;
  if (functionTypeObject != null) {
    pretty = runtimeTypeToString(functionTypeObject);
  } else {
    pretty = Primitives.objectTypeName(value);
  }
  throw new CastErrorImplementation(pretty, self);
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
abstract class JavaScriptIndexingBehavior<E> extends JSMutableIndexable<E> {}

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
      : message = "CastError: Casting value of type '$actualType' to"
            " incompatible type '$expectedType'";

  String toString() => message;
}

class FallThroughErrorImplementation extends FallThroughError {
  FallThroughErrorImplementation();
  String toString() => 'Switch case fall-through.';
}

/**
 * Helper function for implementing asserts. The compiler treats this specially.
 *
 * Returns the negation of the condition. That is: `true` if the assert should
 * fail.
 */
bool assertTest(condition) {
  // Do bool success check first, it is common and faster than 'is Function'.
  if (true == condition) return false;
  if (condition is Function) condition = condition();
  if (condition is bool) return !condition;
  throw new TypeErrorImplementation(condition, 'bool');
}

/**
 * Helper function for implementing asserts with messages.
 * The compiler treats this specially.
 */
void assertThrow(Object message) {
  throw new _AssertionError(message);
}

/**
 * Helper function for implementing asserts without messages.
 * The compiler treats this specially.
 */
@NoInline()
void assertHelper(condition) {
  if (assertTest(condition)) throw new AssertionError();
}

/**
 * Called by generated code when a method that must be statically
 * resolved cannot be found.
 */
void throwNoSuchMethod(obj, name, arguments, expectedArgumentNames) {
  Symbol memberName = new _symbol_dev.Symbol.unvalidated(name);
  throw new NoSuchMethodError(obj, memberName, arguments,
      new Map<Symbol, dynamic>(), expectedArgumentNames);
}

/**
 * Called by generated code when a static field's initializer references the
 * field that is currently being initialized.
 */
void throwCyclicInit(String staticName) {
  throw new CyclicInitializationError(staticName);
}

/**
 * Error thrown when a runtime error occurs.
 */
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

/**
 * Creates a random number with 64 bits of randomness.
 *
 * This will be truncated to the 53 bits available in a double.
 */
int random64() {
  // TODO(lrn): Use a secure random source.
  int int32a = JS('int', '(Math.random() * 0x100000000) >>> 0');
  int int32b = JS('int', '(Math.random() * 0x100000000) >>> 0');
  return int32a + int32b * 0x100000000;
}

String jsonEncodeNative(String string) {
  return JS('String', 'JSON.stringify(#)', string);
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
  var isolateTagGetter = JS_EMBEDDED_GLOBAL('', GET_ISOLATE_TAG);
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
  if (uris == null) return new Future.value(null);

  var hashesMap = JS_EMBEDDED_GLOBAL('', DEFERRED_LIBRARY_HASHES);
  List<String> hashes = JS('JSExtendableArray|Null', '#[#]', hashesMap, loadId);

  List<String> urisToLoad = <String>[];

  var isHunkLoaded = JS_EMBEDDED_GLOBAL('', IS_HUNK_LOADED);
  for (int i = 0; i < uris.length; ++i) {
    if (JS('bool', '#(#)', isHunkLoaded, hashes[i])) continue;
    urisToLoad.add(uris[i]);
  }

  return Future.wait(urisToLoad.map(_loadHunk)).then((_) {
    // Now all hunks have been loaded, we run the needed initializers.
    var isHunkInitialized = JS_EMBEDDED_GLOBAL('', IS_HUNK_INITIALIZED);
    var initializer = JS_EMBEDDED_GLOBAL('', INITIALIZE_LOADED_HUNK);
    for (String hash in hashes) {
      // It is possible for a hash to be repeated. This happens when two
      // different parts both end up empty. Checking in the loop rather than
      // pre-filtering prevents duplicate hashes leading to duplicated
      // initializations.
      // TODO(29572): Merge small parts.
      // TODO(29635): Remove duplicate parts from tables and output files.
      if (JS('bool', '#(#)', isHunkInitialized, hash)) continue;
      JS('void', '#(#)', initializer, hash);
    }
    bool updated = _loadedLibraries.add(loadId);
    if (updated && deferredLoadHook != null) {
      deferredLoadHook();
    }
  });
}

Future<Null> _loadHunk(String hunkName) {
  Future<Null> future = _loadingLibraries[hunkName];
  if (future != null) {
    return future.then((_) => null);
  }

  String uri = IsolateNatives.thisScript;

  int index = uri.lastIndexOf('/');
  uri = '${uri.substring(0, index + 1)}$hunkName';

  var deferredLibraryLoader = JS('', 'self.dartDeferredLibraryLoader');
  Completer<Null> completer = new Completer<Null>();

  void success() {
    completer.complete(null);
  }

  void failure([error, StackTrace stackTrace]) {
    _loadingLibraries[hunkName] = null;
    completer.completeError(
        new DeferredLoadException('Loading $uri failed: $error'), stackTrace);
  }

  var jsSuccess = convertDartClosureToJS(success, 0);
  var jsFailure = convertDartClosureToJS((error) {
    failure(unwrapException(error), getTraceFromException(error));
  }, 1);

  if (JS('bool', 'typeof # === "function"', deferredLibraryLoader)) {
    try {
      JS('void', '#(#, #, #)', deferredLibraryLoader, uri, jsSuccess,
          jsFailure);
    } catch (error, stackTrace) {
      failure(error, stackTrace);
    }
  } else if (isWorker()) {
    // We are in a web worker. Load the code with an XMLHttpRequest.
    enterJsAsync();
    Future<Null> leavingFuture = completer.future.whenComplete(() {
      leaveJsAsync();
    });

    int index = uri.lastIndexOf('/');
    uri = '${uri.substring(0, index + 1)}$hunkName';
    var xhr = JS('var', 'new XMLHttpRequest()');
    JS('void', '#.open("GET", #)', xhr, uri);
    JS(
        'void',
        '#.addEventListener("load", #, false)',
        xhr,
        convertDartClosureToJS((event) {
          if (JS('int', '#.status', xhr) != 200) {
            failure('');
          }
          String code = JS('String', '#.responseText', xhr);
          try {
            // Create a new function to avoid getting access to current function
            // context.
            JS('void', '(new Function(#))()', code);
            success();
          } catch (error, stackTrace) {
            failure(error, stackTrace);
          }
        }, 1));

    JS('void', '#.addEventListener("error", #, false)', xhr, failure);
    JS('void', '#.addEventListener("abort", #, false)', xhr, failure);
    JS('void', '#.send()', xhr);
  } else {
    // We are in a dom-context.
    // Inject a script tag.
    var script = JS('', 'document.createElement("script")');
    JS('', '#.type = "text/javascript"', script);
    JS('', '#.src = #', script, uri);
    JS('', '#.addEventListener("load", #, false)', script, jsSuccess);
    JS('', '#.addEventListener("error", #, false)', script, jsFailure);
    JS('', 'document.body.appendChild(#)', script);
  }
  _loadingLibraries[hunkName] = completer.future;
  return completer.future;
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

@NoInline()
void assertUnreachable() {
  throw new _UnreachableError();
}

// Hook to register new global object if necessary.
// This is currently a no-op in dart2js.
void registerGlobalObject(object) {}
