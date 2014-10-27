// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library for creating mock versions of platform and internal libraries.

library mock_libraries;

String buildLibrarySource(
    Map<String, String> elementMap,
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
  'Function': 'class Function {}',
  'identical': 'bool identical(Object a, Object b) { return true; }',
  'int': 'abstract class int extends num { }',
  'LinkedHashMap': r'''
      class LinkedHashMap {
        factory LinkedHashMap._empty() => null;
        factory LinkedHashMap._literal(elements) => null;
      }''',
  'List': r'''
      class List<E> {
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
  'Symbol': 'class Symbol { final name; const Symbol(this.name); }',
  'Type': 'class Type {}',
  'Pattern': 'abstract class Pattern {}',
};

const String DEFAULT_PATCH_CORE_SOURCE = r'''
import 'dart:_js_helper';
import 'dart:_interceptors';
import 'dart:_isolate_helper';
''';

const Map<String, String> DEFAULT_JS_HELPER_LIBRARY = const <String, String>{
  'assertHelper': 'assertHelper(a) {}',
  'assertIsSubtype': 'assertIsSubtype(subtype, supertype, message) {}',
  'assertSubtype': 'assertSubtype(object, isField, checks, asField) {}',
  'assertSubtypeOfRuntimeType': 'assertSubtypeOfRuntimeType(object, type) {}',
  'boolConversionCheck': 'boolConversionCheck(x) {}',
  'boolTypeCast': 'boolTypeCast(value) {}',
  'boolTypeCheck': 'boolTypeCheck(value) {}',
  'BoundClosure': r'''abstract class BoundClosure extends Closure {
    var self;
    var target;
    var receiver;
  }''',
  'buildFunctionType':
      r'''buildFunctionType(returnType, parameterTypes,
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
  'Closure': 'abstract class Closure implements Function { }',
  'closureFromTearOff':
      r'''closureFromTearOff(receiver, functions, reflectionInfo,
                             isStatic, jsArguments, name) {}''',
  'computeSignature':
      'computeSignature(var signature, var context, var contextName) {}',
  'ConstantMap': 'class ConstantMap<K, V> {}',
  'ConstantProtoMap': 'class ConstantProtoMap<K, V> {}',
  'ConstantStringMap': 'class ConstantStringMap<K, V> {}',
  'copyTypeArguments': 'copyTypeArguments(source, target) {}',
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
  'patch': 'const patch = 0;',
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
  'throwCyclicInit': 'throwCyclicInit() {}',
  'throwExpression': 'throwExpression(e) {}',
  'throwNoSuchMethod':
      'throwNoSuchMethod(obj, name, arguments, expectedArgumentNames) {}',
  'throwRuntimeError': 'throwRuntimeError(message) {}',
  'throwTypeError': 'throwTypeError(message) {}',
  'TypeImpl': 'class TypeImpl {}',
  'TypeVariable': 'class TypeVariable {}',
  'unwrapException': 'unwrapException(e) {}',
  'voidTypeCheck': 'voidTypeCheck(value) {}',
  'wrapException': 'wrapException(x) { return x; }',
  'badMain': 'badMain() { throw "bad main"; }',
  'missingMain': 'missingMain() { throw "missing main"; }',
  'mainHasTooManyParameters':
      'mainHasTooManyParameters() '
      '{ throw "main has too many parameters"; }',
};

const Map<String, String> DEFAULT_FOREIGN_HELPER_LIBRARY
    = const <String, String>{
  'JS': r'''
      dynamic JS(String typeDescription, String codeTemplate,
        [var arg0, var arg1, var arg2, var arg3, var arg4, var arg5, var arg6,
         var arg7, var arg8, var arg9, var arg10, var arg11]) {}''',
};

const Map<String, String> DEFAULT_INTERCEPTORS_LIBRARY = const <String, String>{
  'findIndexForNativeSubclassType':
      'findIndexForNativeSubclassType(type) {}',
  'getDispatchProperty': 'getDispatchProperty(o) {}',
  'getInterceptor': 'getInterceptor(x) {}',
  'getNativeInterceptor': 'getNativeInterceptor(x) {}',
  'initializeDispatchProperty': 'initializeDispatchProperty(f,p,i) {}',
  'initializeDispatchPropertyCSP': 'initializeDispatchPropertyCSP(f,p,i) {}',
  'interceptedNames': 'var interceptedNames;',
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
            add(value) { this[length + 1] = value; }
            insert(index, value) {}
            E get first => this[0];
            E get last => this[0];
            E get single => this[0];
            E removeLast() => this[0];
            E removeAt(index) => this[0];
            E elementAt(index) => this[0];
            E singleWhere(f) => this[0];
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

        operator >(other) => true;
        operator >=(other) => true;
        operator <(other) => true;
        operator <=(other) => true;
        operator ==(other) => true;
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
        var split;
        var length;
        operator[](index) {}
        toString() {}
        operator+(other) => this;
      }''',
  'JSUInt31': 'class JSUInt31 extends JSUInt32 {}',
  'JSUInt32': 'class JSUInt32 extends JSPositiveInt {}',
  'mapTypeToInterceptor': 'var mapTypeToInterceptor;',
  'ObjectInterceptor': 'class ObjectInterceptor {}',
  'PlainJavaScriptObject': 'class PlainJavaScriptObject {}',
  'UnknownJavaScriptObject': 'class UnknownJavaScriptObject {}',
};

const Map<String, String> DEFAULT_ISOLATE_HELPER_LIBRARY =
    const <String, String>{
  'startRootIsolate': 'var startRootIsolate;',
  '_currentIsolate': 'var _currentIsolate;',
  '_callInIsolate': 'var _callInIsolate;',
  '_WorkerBase': 'class _WorkerBase {}',
};

const Map<String, String> DEFAULT_MIRRORS_LIBRARY = const <String, String>{
  'Comment': 'class Comment {}',
  'MirrorSystem': 'class MirrorSystem {}',
  'MirrorsUsed': 'class MirrorsUsed {}',
};

