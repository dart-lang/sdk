// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library for creating mock versions of platform and internal libraries.

library mock_libraries;

const DEFAULT_PLATFORM_CONFIG = """
[libraries]
core:core/core.dart
async:async/async.dart
_js_helper:_internal/js_runtime/lib/js_helper.dart
_interceptors:_internal/js_runtime/lib/interceptors.dart
_internal:internal/internal.dart
_isolate_helper:_internal/js_runtime/lib/isolate_helper.dart
""";

String buildLibrarySource(Map<String, String> elementMap,
    [Map<String, String> additionalElementMap = const <String, String>{}]) {
  Map<String, String> map = new Map<String, String>.from(elementMap);
  if (additionalElementMap != null) {
    map.addAll(additionalElementMap);
  }
  StringBuffer sb = new StringBuffer();
  map.values.forEach((String element) {
    sb.write('$element\n');
  });
  return sb.toString();
}

const Map<String, String> DEFAULT_CORE_LIBRARY = const <String, String>{
  '<imports>': '''
import 'dart:_internal' as internal;
''',
  'bool': 'class bool {}',
  'Comparator': 'abstract class Comparator<T> {}',
  'DateTime': r'''
      class DateTime {
        DateTime(year);
        DateTime.utc(year);
      }''',
  'Deprecated': r'''
      class Deprecated extends Object {
        final String expires;
        const Deprecated(this.expires);
      }''',
  'deprecated': 'const Object deprecated = const Deprecated("next release");',
  'double': r'''
      abstract class double extends num {
        static var NAN = 0;
        static parse(s) {}
      }''',
  'Function': r'''
      class Function {
        static apply(Function fn, List positional, [Map named]) => null;
      }''',
  'identical': 'bool identical(Object a, Object b) { return true; }',
  'int': 'abstract class int extends num { }',
  'Iterable': '''
      abstract class Iterable<E> {
          Iterator<E> get iterator => null;
      }''',
  'Iterator': '''
      abstract class Iterator<E> {
          E get current => null;
      }''',
  'LinkedHashMap': r'''
      class LinkedHashMap<K, V> implements Map<K, V> {
      }''',
  'List': r'''
      class List<E> extends Iterable<E> {
        var length;
        List([length]);
        List.filled(length, element);
        E get first => null;
        E get last => null;
        E get single => null;
        E removeLast() => null;
        E removeAt(i) => null;
        E elementAt(i) => null;
        E singleWhere(f) => null;
      }''',
  'Map': 'abstract class Map<K,V> {}',
  'Null': 'class Null {}',
  'num': r'''
      abstract class num {
        operator +(_);
        operator *(_);
        operator -();
      }''',
  'print': 'print(var obj) {}',
  'proxy': 'const proxy = 0;',
  'Object': r'''
      class Object {
        const Object();
        operator ==(other) { return true; }
        get hashCode => throw "Object.hashCode not implemented.";
        String toString() { return null; }
        noSuchMethod(im) { throw im; }
      }''',
  'StackTrace': 'abstract class StackTrace {}',
  'String': 'class String implements Pattern {}',
  'Symbol': '''
      abstract class Symbol { 
        const factory Symbol(String name) = internal.Symbol; 
      }
      ''',
  'Type': 'class Type {}',
  'Pattern': 'abstract class Pattern {}',
  '_genericNoSuchMethod': '_genericNoSuchMethod(a,b,c,d,e) {}',
  '_unresolvedConstructorError': '_unresolvedConstructorError(a,b,c,d,e) {}',
  '_malformedTypeError': '_malformedTypeError(message) {}',
};

const Map<String, String> DEFAULT_INTERNAL_LIBRARY = const <String, String>{
  '<imports>': '''
import 'dart:core' as core;
''',
  'Symbol': '''
class Symbol implements core.Symbol { 
  final core.String _name; 
  
  const Symbol(this._name);
  Symbol.validated(this._name);
}
''',
};

const String DEFAULT_PATCH_CORE_SOURCE = r'''
import 'dart:_js_helper';
import 'dart:_interceptors';
import 'dart:_isolate_helper';
import 'dart:async';

@patch
class LinkedHashMap<K, V> {
  factory LinkedHashMap._empty() => null;
  factory LinkedHashMap._literal(elements) => null;
  static _makeEmpty() => null;
  static _makeLiteral(elements) => null;
}
''';

const Map<String, String> DEFAULT_JS_HELPER_LIBRARY = const <String, String>{
  'assertTest': 'assertTest(a) {}',
  'assertThrow': 'assertThrow(a) {}',
  'assertHelper': 'assertHelper(a) {}',
  'assertUnreachable': 'assertUnreachable() {}',
  'assertIsSubtype': 'assertIsSubtype(subtype, supertype, message) {}',
  'assertSubtype': 'assertSubtype(object, isField, checks, asField) {}',
  'assertSubtypeOfRuntimeType': 'assertSubtypeOfRuntimeType(object, type) {}',
  'asyncHelper': 'asyncHelper(object, asyncBody, completer) {}',
  'boolConversionCheck': 'boolConversionCheck(x) {}',
  'boolTypeCast': 'boolTypeCast(value) {}',
  'boolTypeCheck': 'boolTypeCheck(value) {}',
  'checkSubtype': 'checkSubtype(object, isField, checks, asField) {}',
  'checkSubtypeOfRuntimeType': 'checkSubtypeOfRuntimeType(o, t) {}',
  'BoundClosure': r'''abstract class BoundClosure extends Closure {
    var self;
    var target;
    var receiver;
  }''',
  'buildFunctionType': r'''buildFunctionType(returnType, parameterTypes,
                            optionalParameterTypes) {
            return new RuntimeFunctionType();
          }''',
  'buildInterfaceType': '''buildInterfaceType(rti, typeArguments) {
                             if (rti == null) return new RuntimeTypePlain();
                             return new RuntimeTypeGeneric();
                           }''',
  'buildNamedFunctionType':
      r'''buildNamedFunctionType(returnType, parameterTypes,
                                 namedParameters) {
            return new RuntimeFunctionType();
          }''',
  'checkFunctionSubtype':
      r'''checkFunctionSubtype(var target, String signatureName,
                               String contextName, var context,
                               var typeArguments) {}''',
  'checkMalformedType': 'checkMalformedType(value, message) {}',
  'checkInt': 'checkInt(value) {}',
  'checkNum': 'checkNum(value) {}',
  'checkString': 'checkString(value) {}',
  'Closure': 'abstract class Closure implements Function { }',
  'closureFromTearOff':
      r'''closureFromTearOff(receiver, functions, reflectionInfo,
                             isStatic, jsArguments, name) {}''',
  'computeSignature':
      'computeSignature(var signature, var context, var contextName) {}',
  'ConstantMap': 'class ConstantMap<K, V> {}',
  'ConstantProtoMap': 'class ConstantProtoMap<K, V> {}',
  'ConstantStringMap': 'class ConstantStringMap<K, V> {}',
  'createInvocationMirror': 'createInvocationMirror(a0, a1, a2, a3, a4, a5) {}',
  'createRuntimeType': 'createRuntimeType(a) {}',
  'doubleTypeCast': 'doubleTypeCast(value) {}',
  'doubleTypeCheck': 'doubleTypeCheck(value) {}',
  'functionSubtypeCast':
      r'''functionSubtypeCast(Object object, String signatureName,
                              String contextName, var context) {}''',
  'functionTypeTestMetaHelper': r'''
      functionTypeTestMetaHelper() {
        buildFunctionType(null, null, null);
        buildNamedFunctionType(null, null, null);
        buildInterfaceType(null, null);
      }''',
  'functionTypeTest': r'functionTypeTest(f, t) {}',
  'functionTypeCast': r'functionTypeCast(f, t) { return f; }',
  'functionTypeCheck': r'functionTypeCheck(f, t) { return f; }',
  'getFallThroughError': 'getFallThroughError() {}',
  'getIsolateAffinityTag': 'getIsolateAffinityTag(_) {}',
  'getRuntimeTypeArgument':
      'getRuntimeTypeArgument(target, substitutionName, index) {}',
  'getRuntimeTypeArguments':
      'getRuntimeTypeArguments(target, substitutionName) {}',
  'getRuntimeTypeInfo': 'getRuntimeTypeInfo(a) {}',
  'getTraceFromException': 'getTraceFromException(exception) {}',
  'getTypeArgumentByIndex': 'getTypeArgumentByIndex(target, index) {}',
  'GeneralConstantMap': 'class GeneralConstantMap {}',
  'iae': 'iae(x) { throw x; } ioore(x) { throw x; }',
  'interceptedTypeCast': 'interceptedTypeCast(value, property) {}',
  'interceptedTypeCheck': 'interceptedTypeCheck(value, property) {}',
  'intTypeCast': 'intTypeCast(value) {}',
  'intTypeCheck': 'intTypeCheck(value) {}',
  'IrRepresentation': 'class IrRepresentation {}',
  'isJsIndexable': 'isJsIndexable(a, b) {}',
  'JavaScriptIndexingBehavior': 'abstract class JavaScriptIndexingBehavior {}',
  'JSInvocationMirror': 'class JSInvocationMirror {}',
  'listSuperNativeTypeCast': 'listSuperNativeTypeCast(value) {}',
  'listSuperNativeTypeCheck': 'listSuperNativeTypeCheck(value) {}',
  'listSuperTypeCast': 'listSuperTypeCast(value) {}',
  'listSuperTypeCheck': 'listSuperTypeCheck(value) {}',
  'listTypeCast': 'listTypeCast(value) {}',
  'listTypeCheck': 'listTypeCheck(value) {}',
  'makeLiteralMap': 'makeLiteralMap(List keyValuePairs) {}',
  'Native': 'class Native {}',
  'NoInline': 'class NoInline {}',
  'ForceInline': 'class ForceInline {}',
  'NoSideEffects': 'class NoSideEffects {}',
  'NoThrows': 'class NoThrows {}',
  'numberOrStringSuperNativeTypeCast':
      'numberOrStringSuperNativeTypeCast(value) {}',
  'numberOrStringSuperNativeTypeCheck':
      'numberOrStringSuperNativeTypeCheck(value) {}',
  'numberOrStringSuperTypeCast': 'numberOrStringSuperTypeCast(value) {}',
  'numberOrStringSuperTypeCheck': 'numberOrStringSuperTypeCheck(value) {}',
  'numTypeCast': 'numTypeCast(value) {}',
  'numTypeCheck': 'numTypeCheck(value) {}',
  '_Patch': 'class _Patch { final tag; const _Patch(this.tag); }',
  'patch': 'const patch = const _Patch(null);',
  'patch_full': 'const patch_full = const _Patch("full");',
  'patch_lazy': 'const patch_lazy = const _Patch("lazy");',
  'patch_startup': 'const patch_startup = const _Patch("startup");',
  'propertyTypeCast': 'propertyTypeCast(x) {}',
  'propertyTypeCheck': 'propertyTypeCheck(value, property) {}',
  'requiresPreamble': 'requiresPreamble() {}',
  'RuntimeFunctionType': 'class RuntimeFunctionType {}',
  'RuntimeTypeGeneric': 'class RuntimeTypeGeneric {}',
  'RuntimeTypePlain': 'class RuntimeTypePlain {}',
  'runtimeTypeToString': 'runtimeTypeToString(type, {onTypeVariable(i)}) {}',
  'S': 'S() {}',
  'setRuntimeTypeInfo': 'setRuntimeTypeInfo(a, b) {}',
  'stringSuperNativeTypeCast': 'stringSuperNativeTypeCast(value) {}',
  'stringSuperNativeTypeCheck': 'stringSuperNativeTypeCheck(value) {}',
  'stringSuperTypeCast': 'stringSuperTypeCast(value) {}',
  'stringSuperTypeCheck': 'stringSuperTypeCheck(value) {}',
  'stringTypeCast': 'stringTypeCast(x) {}',
  'stringTypeCheck': 'stringTypeCheck(x) {}',
  'subtypeCast': 'subtypeCast(object, isField, checks, asField) {}',
  'subtypeOfRuntimeTypeCast': 'subtypeOfRuntimeTypeCast(object, type) {}',
  'throwAbstractClassInstantiationError':
      'throwAbstractClassInstantiationError(className) {}',
  'checkConcurrentModificationError':
      'checkConcurrentModificationError(collection) {}',
  'throwConcurrentModificationError':
      'throwConcurrentModificationError(collection) {}',
  'throwCyclicInit': 'throwCyclicInit(staticName) {}',
  'throwExpression': 'throwExpression(e) {}',
  'throwNoSuchMethod':
      'throwNoSuchMethod(obj, name, arguments, expectedArgumentNames) {}',
  'throwRuntimeError': 'throwRuntimeError(message) {}',
  'throwUnsupportedError': 'throwUnsupportedError(message) {}',
  'throwTypeError': 'throwTypeError(message) {}',
  'TypeImpl': 'class TypeImpl {}',
  'TypeVariable': '''class TypeVariable {
    final Type owner;
    final String name;
    final int bound;
    const TypeVariable(this.owner, this.name, this.bound);
  }''',
  'unwrapException': 'unwrapException(e) {}',
  'voidTypeCheck': 'voidTypeCheck(value) {}',
  'wrapException': 'wrapException(x) { return x; }',
  'badMain': 'badMain() { throw "bad main"; }',
  'missingMain': 'missingMain() { throw "missing main"; }',
  'mainHasTooManyParameters': 'mainHasTooManyParameters() '
      '{ throw "main has too many parameters"; }',
};

const Map<String, String> DEFAULT_FOREIGN_HELPER_LIBRARY =
    const <String, String>{
  'JS': r'''
      dynamic JS(String typeDescription, String codeTemplate,
        [var arg0, var arg1, var arg2, var arg3, var arg4, var arg5, var arg6,
         var arg7, var arg8, var arg9, var arg10, var arg11]) {}''',
};

const Map<String, String> DEFAULT_INTERCEPTORS_LIBRARY = const <String, String>{
  'findIndexForNativeSubclassType': 'findIndexForNativeSubclassType(type) {}',
  'getDispatchProperty': 'getDispatchProperty(o) {}',
  'getInterceptor': 'getInterceptor(x) {}',
  'getNativeInterceptor': 'getNativeInterceptor(x) {}',
  'initializeDispatchProperty': 'initializeDispatchProperty(f,p,i) {}',
  'initializeDispatchPropertyCSP': 'initializeDispatchPropertyCSP(f,p,i) {}',
  'Interceptor': r'''
      class Interceptor {
        toString() {}
        bool operator==(other) => identical(this, other);
        get hashCode => throw "Interceptor.hashCode not implemented.";
        noSuchMethod(im) { throw im; }
      }''',
  'JSArray': r'''
          class JSArray<E> extends Interceptor implements List<E>, JSIndexable {
            JSArray();
            factory JSArray.typed(a) => a;
            var length;
            operator[](index) => this[index];
            operator[]=(index, value) { this[index] = value; }
            add(value) { this[length] = value; }
            insert(index, value) {}
            E get first => this[0];
            E get last => this[0];
            E get single => this[0];
            E removeLast() => this[0];
            E removeAt(index) => this[0];
            E elementAt(index) => this[0];
            E singleWhere(f) => this[0];
            Iterator<E> get iterator => null;
          }''',
  'JSBool': 'class JSBool extends Interceptor implements bool {}',
  'JSDouble': 'class JSDouble extends JSNumber implements double {}',
  'JSExtendableArray': 'class JSExtendableArray extends JSMutableArray {}',
  'JSFixedArray': 'class JSFixedArray extends JSMutableArray {}',
  'JSFunction':
      'abstract class JSFunction extends Interceptor implements Function {}',
  'JSIndexable': r'''
      abstract class JSIndexable {
        get length;
        operator[](index);
      }''',
  'JSInt': r'''
       class JSInt extends JSNumber implements int {
         operator~() => this;
       }''',
  'JSMutableArray':
      'class JSMutableArray extends JSArray implements JSMutableIndexable {}',
  'JSUnmodifiableArray': 'class JSUnmodifiableArray extends JSArray {}',
  'JSMutableIndexable':
      'abstract class JSMutableIndexable extends JSIndexable {}',
  'JSPositiveInt': 'class JSPositiveInt extends JSInt {}',
  'JSNull': r'''
      class JSNull extends Interceptor {
        bool operator==(other) => identical(null, other);
        get hashCode => throw "JSNull.hashCode not implemented.";
        String toString() => 'Null';
        Type get runtimeType => null;
        noSuchMethod(x) => super.noSuchMethod(x);
      }''',
  'JSNumber': r'''
      class JSNumber extends Interceptor implements num {
        // All these methods return a number to please type inferencing.
        operator-() => (this is JSInt) ? 42 : 42.2;
        operator +(other) => (this is JSInt) ? 42 : 42.2;
        operator -(other) => (this is JSInt) ? 42 : 42.2;
        operator ~/(other) => _tdivFast(other);
        operator /(other) => (this is JSInt) ? 42 : 42.2;
        operator *(other) => (this is JSInt) ? 42 : 42.2;
        operator %(other) => (this is JSInt) ? 42 : 42.2;
        operator <<(other) => _shlPositive(other);
        operator >>(other) {
          return _shrBothPositive(other) + _shrReceiverPositive(other) +
            _shrOtherPositive(other);
        }
        operator |(other) => 42;
        operator &(other) => 42;
        operator ^(other) => 42;

        operator >(other) => !identical(this, other);
        operator >=(other) => !identical(this, other);
        operator <(other) => !identical(this, other);
        operator <=(other) => !identical(this, other);
        operator ==(other) => identical(this, other);
        get hashCode => throw "JSNumber.hashCode not implemented.";

        // We force side effects on _tdivFast to mimic the shortcomings of
        // the effect analysis: because the `_tdivFast` implementation of
        // the core library has calls that may not already be analyzed,
        // the analysis will conclude that `_tdivFast` may have side
        // effects.
        _tdivFast(other) => new List()..length = 42;
        _shlPositive(other) => 42;
        _shrBothPositive(other) => 42;
        _shrReceiverPositive(other) => 42;
        _shrOtherPositive(other) => 42;

        abs() => (this is JSInt) ? 42 : 42.2;
        remainder(other) => (this is JSInt) ? 42 : 42.2;
        truncate() => 42;
      }''',
  'JSString': r'''
      class JSString extends Interceptor implements String, JSIndexable {
        split(pattern) => [];
        int get length => 42;
        operator[](index) {}
        toString() {}
        operator+(other) => this;
        codeUnitAt(index) => 42;
      }''',
  'JSUInt31': 'class JSUInt31 extends JSUInt32 {}',
  'JSUInt32': 'class JSUInt32 extends JSPositiveInt {}',
  'ObjectInterceptor': 'class ObjectInterceptor {}',
  'JavaScriptObject': 'class JavaScriptObject {}',
  'PlainJavaScriptObject': 'class PlainJavaScriptObject {}',
  'UnknownJavaScriptObject': 'class UnknownJavaScriptObject {}',
  'JavaScriptFunction': 'class JavaScriptFunction {}',
};

const Map<String, String> DEFAULT_ISOLATE_HELPER_LIBRARY =
    const <String, String>{
  'startRootIsolate': 'void startRootIsolate(entry, args) {}',
  '_currentIsolate': 'var _currentIsolate;',
  '_callInIsolate': 'var _callInIsolate;',
  '_WorkerBase': 'class _WorkerBase {}',
};

const Map<String, String> DEFAULT_ASYNC_LIBRARY = const <String, String>{
  'DeferredLibrary': 'class DeferredLibrary {}',
  'Future': '''
      class Future<T> {
        Future.value([value]);
      }
      ''',
  'Stream': 'class Stream<T> {}',
  'Completer': 'class Completer<T> {}',
  'StreamIterator': 'class StreamIterator<T> {}',
};

/// These members are only needed when async/await is used.
const Map<String, String> ASYNC_AWAIT_LIBRARY = const <String, String>{
  '_wrapJsFunctionForAsync': '_wrapJsFunctionForAsync(f) {}',
  '_asyncHelper': '_asyncHelper(o, f, c) {}',
  '_SyncStarIterable': 'class _SyncStarIterable {}',
  '_IterationMarker': 'class _IterationMarker {}',
  '_AsyncStarStreamController': 'class _AsyncStarStreamController {}',
  '_asyncStarHelper': '_asyncStarHelper(x, y, z) {}',
  '_streamOfController': '_streamOfController(x) {}',
};

const String DEFAULT_MIRRORS_SOURCE = r'''
import 'dart:_js_mirrors' as js;
class Comment {}
class MirrorSystem {}
class MirrorsUsed {
  final targets;
  const MirrorsUsed({this.targets});
}
void reflectType(Type t) => js.disableTreeShaking();
''';

const String DEFAULT_JS_MIRRORS_SOURCE = r'''
disableTreeShaking(){}
preserveMetadata(){}
preserveUris(){}
preserveLibraryNames(){}
''';

const Map<String, String> DEFAULT_LOOKUP_MAP_LIBRARY = const <String, String>{
  'LookupMap': r'''
  class LookupMap<K, V> {
    final _key;
    final _value;
    final _entries;
    final _nestedMaps;

    const LookupMap(this._entries, [this._nestedMaps = const []])
        : _key = null, _value = null;

    const LookupMap.pair(this._key, this._value)
        : _entries = const [], _nestedMaps = const [];
    V operator[](K k) => null;
  }''',
  '_version': 'const _version = "0.0.1+1";',
};
