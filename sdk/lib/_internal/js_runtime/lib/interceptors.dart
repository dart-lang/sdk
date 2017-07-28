// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _interceptors;

import 'dart:_js_embedded_names'
    show DISPATCH_PROPERTY_NAME, TYPE_TO_INTERCEPTOR_MAP;

import 'dart:collection' hide LinkedList, LinkedListEntry;
import 'dart:_internal' hide Symbol;
import "dart:_internal" as _symbol_dev show Symbol;
import 'dart:_js_helper'
    show
        allMatchesInStringUnchecked,
        JSSyntaxRegExp,
        Primitives,
        argumentErrorValue,
        checkInt,
        checkNull,
        checkNum,
        checkString,
        defineProperty,
        diagnoseIndexError,
        getIsolateAffinityTag,
        getRuntimeType,
        initNativeDispatch,
        initNativeDispatchFlag,
        regExpGetNative,
        regExpCaptureCount,
        stringContainsUnchecked,
        stringIndexOfStringUnchecked,
        stringLastIndexOfUnchecked,
        stringReplaceAllFuncUnchecked,
        stringReplaceAllUnchecked,
        stringReplaceFirstUnchecked,
        stringReplaceFirstMappedUnchecked,
        stringReplaceRangeUnchecked,
        throwConcurrentModificationError,
        lookupAndCacheInterceptor,
        StringMatch,
        firstMatchAfter,
        NoInline;

import 'dart:_foreign_helper'
    show
        JS,
        JS_EFFECT,
        JS_EMBEDDED_GLOBAL,
        JS_INTERCEPTOR_CONSTANT,
        JS_STRING_CONCAT;
import 'dart:math' show Random;

part 'js_array.dart';
part 'js_number.dart';
part 'js_string.dart';

final String DART_CLOSURE_PROPERTY_NAME =
    getIsolateAffinityTag(r'_$dart_dartClosure');

String _symbolToString(Symbol symbol) => _symbol_dev.Symbol.getName(symbol);

_symbolMapToStringMap(Map<Symbol, dynamic> map) {
  if (map == null) return null;
  var result = new Map<String, dynamic>();
  map.forEach((Symbol key, value) {
    result[_symbolToString(key)] = value;
  });
  return result;
}

/**
 * Get the interceptor for [object]. Called by the compiler when it needs
 * to emit a call to an intercepted method, that is a method that is
 * defined in an interceptor class.
 */
@NoInline()
getInterceptor(object) {
  // This is a magic method: the compiler does specialization of it
  // depending on the uses of intercepted methods and instantiated
  // primitive types.

  // The [JS] call prevents the type analyzer from making assumptions about the
  // return type.
  return JS('', 'void 0');
}

getDispatchProperty(object) {
  return JS(
      '', '#[#]', object, JS_EMBEDDED_GLOBAL('String', DISPATCH_PROPERTY_NAME));
}

setDispatchProperty(object, value) {
  defineProperty(
      object, JS_EMBEDDED_GLOBAL('String', DISPATCH_PROPERTY_NAME), value);
}

// Avoid inlining this method because inlining gives us multiple allocation
// points for records which is bad because it leads to polymorphic access.
@NoInline()
makeDispatchRecord(interceptor, proto, extension, indexability) {
  // Dispatch records are stored in the prototype chain, and in some cases, on
  // instances.
  //
  // The record layout and field usage is designed to minimize the number of
  // operations on the common paths.
  //
  // [interceptor] is the interceptor - a holder of methods for the object,
  // i.e. the prototype of the interceptor class.
  //
  // [proto] is usually the prototype, used to check that the dispatch record
  // matches the object and is not the dispatch record of a superclass.  Other
  // values:
  //  - `false` for leaf classes that need no check.
  //  - `true` for Dart classes where the object is its own interceptor (unused)
  //  - a function used to continue matching.
  //
  // [extension] is used for irregular cases.
  //
  // [indexability] is used to cache whether or not the object
  // implements JavaScriptIndexingBehavior.
  //
  //     proto  interceptor extension action
  //     -----  ----------- --------- ------
  //     false  I                     use interceptor I
  //     true   -                     use object
  //     P      I                     if object's prototype is P, use I
  //     F      -           P         if object's prototype is P, call F

  return JS('', '{i: #, p: #, e: #, x: #}', interceptor, proto, extension,
      indexability);
}

dispatchRecordInterceptor(record) => JS('', '#.i', record);
dispatchRecordProto(record) => JS('', '#.p', record);
dispatchRecordExtension(record) => JS('', '#.e', record);
dispatchRecordIndexability(record) => JS('bool|Null', '#.x', record);

/**
 * Returns the interceptor for a native class instance. Used by
 * [getInterceptor].
 */
getNativeInterceptor(object) {
  var record = getDispatchProperty(object);

  if (record == null) {
    if (initNativeDispatchFlag == null) {
      initNativeDispatch();
      record = getDispatchProperty(object);
    }
  }

  if (record != null) {
    var proto = dispatchRecordProto(record);
    if (false == proto) return dispatchRecordInterceptor(record);
    if (true == proto) return object;
    var objectProto = JS('', 'Object.getPrototypeOf(#)', object);
    if (JS('bool', '# === #', proto, objectProto)) {
      return dispatchRecordInterceptor(record);
    }

    var extension = dispatchRecordExtension(record);
    if (JS('bool', '# === #', extension, objectProto)) {
      // TODO(sra): The discriminator returns a tag.  The tag is an uncached or
      // instance-cached tag, defaulting to instance-cached if caching
      // unspecified.
      var discriminatedTag = JS('', '(#)(#, #)', proto, object, record);
      throw new UnimplementedError('Return interceptor for $discriminatedTag');
    }
  }

  // Check for cached UnknownJavaScriptObject. This avoids doing the slow
  // dispatch-record based lookup for repeated js-interop classes.
  var constructor = JS('', '#.constructor', object);
  var interceptor = lookupInterceptorByConstructor(constructor);
  if (interceptor != null) return interceptor;

  // This takes care of dispatch-record based caching, but not constructor based
  // caching of [UnknownJavaScriptObject]s.
  interceptor = lookupAndCacheInterceptor(object);
  if (interceptor != null) return interceptor;

  // JavaScript Objects created via object literals and `Object.create(null)`
  // are 'plain' Objects.  This test could be simplified and the dispatch path
  // be faster if Object.prototype was pre-patched with a non-leaf dispatch
  // record.
  if (JS('bool', 'typeof # == "function"', object)) {
    interceptor = JS_INTERCEPTOR_CONSTANT(JavaScriptFunction);
    // TODO(sra): Investigate caching on `Function`. It might be impossible if
    // some HTML embedded objects on some browsers are (still) JS functions.
    return interceptor;
  }
  var proto = JS('', 'Object.getPrototypeOf(#)', object);
  if (JS('bool', '# == null', proto)) {
    // Nowhere to cache output.
    return JS_INTERCEPTOR_CONSTANT(PlainJavaScriptObject);
  }
  interceptor = JS_INTERCEPTOR_CONSTANT(UnknownJavaScriptObject);
  if (JS('bool', '# === Object.prototype', proto)) {
    interceptor = JS_INTERCEPTOR_CONSTANT(PlainJavaScriptObject);
    // TODO(sra): Investigate caching on 'Object'. It might be impossible if
    // some native class is plain Object (e.g. like Firefox's ImageData).
    return interceptor;
  }
  if (JS('bool', 'typeof # == "function"', constructor)) {
    cacheInterceptorOnConstructor(constructor, interceptor);
    return interceptor;
  }
  return JS_INTERCEPTOR_CONSTANT(UnknownJavaScriptObject);
}

// A JS String or Symbol.
final JS_INTEROP_INTERCEPTOR_TAG = getIsolateAffinityTag(r'_$dart_js');

lookupInterceptorByConstructor(constructor) {
  return constructor == null
      ? null
      : JS('', '#[#]', constructor, JS_INTEROP_INTERCEPTOR_TAG);
}

void cacheInterceptorOnConstructor(constructor, interceptor) {
  defineProperty(constructor, JS_INTEROP_INTERCEPTOR_TAG, interceptor);
}

var constructorToInterceptor =
    JS('', 'typeof(self.WeakMap) == "undefined" ? new Map() : new WeakMap()');

XlookupInterceptorByConstructor(constructor) {
  return JS('', '#.get(#)', constructorToInterceptor, constructor);
}

void XcacheInterceptorOnConstructor(constructor, interceptor) {
  JS('', '#.set(#, #)', constructorToInterceptor, constructor, interceptor);
}

/**
 * Data structure used to map a [Type] to the [Interceptor] and constructors for
 * that type.  It is JavaScript array of 3N entries of adjacent slots containing
 * a [Type], followed by an [Interceptor] class for the type, followed by a
 * JavaScript object map for the constructors.
 *
 * The value of this variable is set by the compiler and contains only types
 * that are user extensions of native classes where the type occurs as a
 * constant in the program.
 *
 * The compiler, in CustomElementsAnalysis, assumes that [typeToInterceptorMap]
 * is accessed only by code that also calls [findIndexForWebComponentType].  If
 * this assumption is invalidated, the compiler will have to be updated.
 */
get typeToInterceptorMap {
  return JS_EMBEDDED_GLOBAL('', TYPE_TO_INTERCEPTOR_MAP);
}

int findIndexForNativeSubclassType(Type type) {
  if (JS('bool', '# == null', typeToInterceptorMap)) return null;
  List map = JS('JSFixedArray', '#', typeToInterceptorMap);
  for (int i = 0; i + 1 < map.length; i += 3) {
    if (type == map[i]) {
      return i;
    }
  }
  return null;
}

findInterceptorConstructorForType(Type type) {
  var index = findIndexForNativeSubclassType(type);
  if (index == null) return null;
  List map = JS('JSFixedArray', '#', typeToInterceptorMap);
  return map[index + 1];
}

/**
 * Returns a JavaScript function that runs the constructor on its argument, or
 * `null` if there is no such constructor.
 *
 * The returned function takes one argument, the web component object.
 */
findConstructorForNativeSubclassType(Type type, String name) {
  var index = findIndexForNativeSubclassType(type);
  if (index == null) return null;
  List map = JS('JSFixedArray', '#', typeToInterceptorMap);
  var constructorMap = map[index + 2];
  var constructorFn = JS('', '#[#]', constructorMap, name);
  return constructorFn;
}

findInterceptorForType(Type type) {
  var constructor = findInterceptorConstructorForType(type);
  if (constructor == null) return null;
  return JS('', '#.prototype', constructor);
}

/**
 * The base interceptor class.
 *
 * The code `r.foo(a)` is compiled to `getInterceptor(r).foo$1(r, a)`.  The
 * value returned by [getInterceptor] holds the methods separately from the
 * state of the instance.  The compiler converts the methods on an interceptor
 * to take the Dart `this` argument as an explicit `receiver` argument.  The
 * JavaScript `this` parameter is bound to the interceptor.
 *
 * In order to have uniform call sites, if a method is defined on an
 * interceptor, methods of that name on plain unintercepted classes also use the
 * interceptor calling convention.  The plain classes are _self-interceptors_,
 * and for them, `getInterceptor(r)` returns `r`.  Methods on plain
 * unintercepted classes have a redundant `receiver` argument and, to enable
 * some optimizations, must ignore `receiver` in favour of `this`.
 *
 * In the case of mixins, a method may be placed on both an intercepted class
 * and an unintercepted class.  In this case, the method must use the `receiver`
 * parameter.
 *
 *
 * There are various optimizations of the general call pattern.
 *
 * When the interceptor can be statically determined, it can be used directly:
 *
 *     CONSTANT_INTERCEPTOR.foo$1(r, a)
 *
 * If there are only a few classes, [getInterceptor] can be specialized with a
 * more efficient dispatch:
 *
 *     getInterceptor$specialized(r).foo$1(r, a)
 *
 * If it can be determined that the receiver is an unintercepted class, it can
 * be called directly:
 *
 *     r.foo$1(r, a)
 *
 * If, further, it is known that the call site cannot call a foo that is
 * mixed-in to a native class, then it is known that the explicit receiver is
 * ignored, and space-saving dummy value can be passed instead:
 *
 *     r.foo$1(0, a)
 *
 * This class defines implementations of *all* methods on [Object] so no
 * interceptor inherits an implementation from [Object].  This enables the
 * implementations on Object to ignore the explicit receiver argument, which
 * allows dummy receiver optimization.
 */
abstract class Interceptor {
  const Interceptor();

  bool operator ==(other) => identical(this, other);

  int get hashCode => Primitives.objectHashCode(this);

  String toString() => Primitives.objectToHumanReadableString(this);

  // [Interceptor.noSuchMethod] is identical to [Object.noSuchMethod].  However,
  // each copy is compiled differently.  The presence of the method on an
  // Interceptor class forces [noSuchMethod] to use interceptor calling
  // convention.  In the [Interceptor] version, `this` is the explicit receiver
  // argument. In the [Object] version, as Object is not an intercepted class,
  // `this` is the JavaScript receiver, and the explicit receiver is ignored.
  // The noSuchMethod stubs for selectors that use the interceptor calling
  // convention do not know the calling convention and forward `this` and
  // `receiver` to one of these noSuchMethod implementations which selects the
  // correct Dart receiver.
  //
  // We don't allow [noSuchMethod] on intercepted classes (that would force all
  // calls to use interceptor calling convention).  If we did allow it, the
  // interceptor context would select the correct `this`.
  dynamic noSuchMethod(Invocation invocation) {
    throw new NoSuchMethodError(this, invocation.memberName,
        invocation.positionalArguments, invocation.namedArguments);
  }

  Type get runtimeType => getRuntimeType(this);
}

/**
 * The interceptor class for [bool].
 */
class JSBool extends Interceptor implements bool {
  const JSBool();

  // Note: if you change this, also change the function [S].
  String toString() => JS('String', r'String(#)', this);

  // The values here are SMIs, co-prime and differ about half of the bit
  // positions, including the low bit, so they are different mod 2^k.
  int get hashCode => this ? (2 * 3 * 23 * 3761) : (269 * 811);

  Type get runtimeType => bool;
}

/**
 * The interceptor class for [Null].
 *
 * This class defines implementations for *all* methods on [Object] since
 * the methods on Object assume the receiver is non-null.  This means that
 * JSNull will always be in the interceptor set for methods defined on Object.
 */
class JSNull extends Interceptor implements Null {
  const JSNull();

  bool operator ==(other) => identical(null, other);

  // Note: if you change this, also change the function [S].
  String toString() => 'null';

  int get hashCode => 0;

  // The spec guarantees that `null` is the singleton instance of the `Null`
  // class. In the mirrors library we also have to patch the `type` getter to
  // special case `null`.
  Type get runtimeType => Null;

  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * The supertype for JSString and JSArray. Used by the backend as to
 * have a type mask that contains the objects that we can use the
 * native JS [] operator and length on.
 */
abstract class JSIndexable<E> {
  int get length;
  E operator [](int index);
}

/**
 * The supertype for JSMutableArray and
 * JavaScriptIndexingBehavior. Used by the backend to have a type mask
 * that contains the objects we can use the JS []= operator on.
 */
abstract class JSMutableIndexable<E> extends JSIndexable<E> {
  operator []=(int index, E value);
}

/**
 * The interface implemented by JavaScript objects.  These are methods in
 * addition to the regular Dart Object methods like [Object.hashCode].
 *
 * This is the type that should be exported by a JavaScript interop library.
 */
abstract class JSObject {}

/**
 * Interceptor base class for JavaScript objects not recognized as some more
 * specific native type.
 */
class JavaScriptObject extends Interceptor implements JSObject {
  const JavaScriptObject();

  // It would be impolite to stash a property on the object.
  int get hashCode => 0;

  Type get runtimeType => JSObject;

  /**
   * Returns the result of the JavaScript objects `toString` method.
   */
  String toString() => JS('String', 'String(#)', this);
}

/**
 * Interceptor for plain JavaScript objects created as JavaScript object
 * literals or `new Object()`.
 */
class PlainJavaScriptObject extends JavaScriptObject {
  const PlainJavaScriptObject();
}

/**
 * Interceptor for unclassified JavaScript objects, typically objects with a
 * non-trivial prototype chain.
 *
 * This class also serves as a fallback for unknown JavaScript exceptions.
 */
class UnknownJavaScriptObject extends JavaScriptObject {
  const UnknownJavaScriptObject();
}

/**
 * Interceptor for JavaScript function objects and Dart functions that have
 * been converted to JavaScript functions.
 * These interceptor methods are not always used as the JavaScript function
 * object has also been mangled to support Dart function calling conventions.
 */
class JavaScriptFunction extends JavaScriptObject implements Function {
  const JavaScriptFunction();

  String toString() {
    var dartClosure = JS('', '#.#', this, DART_CLOSURE_PROPERTY_NAME);
    return dartClosure == null ? super.toString() : dartClosure.toString();
  }
}
