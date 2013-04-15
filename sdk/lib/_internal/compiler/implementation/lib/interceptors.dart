// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _interceptors;

import 'dart:collection';
import 'dart:_collection-dev';
import 'dart:_js_helper' show allMatchesInStringUnchecked,
                              Null,
                              JSSyntaxRegExp,
                              Primitives,
                              checkGrowable,
                              checkMutable,
                              checkNull,
                              checkNum,
                              checkString,
                              getRuntimeTypeString,
                              regExpGetNative,
                              stringContainsUnchecked,
                              stringLastIndexOfUnchecked,
                              stringReplaceAllFuncUnchecked,
                              stringReplaceAllUnchecked,
                              stringReplaceFirstUnchecked,
                              TypeImpl,
                              lookupDispatchRecord;
import 'dart:_foreign_helper' show JS;

part 'js_array.dart';
part 'js_number.dart';
part 'js_string.dart';

/**
 * Get the interceptor for [object]. Called by the compiler when it needs
 * to emit a call to an intercepted method, that is a method that is
 * defined in an interceptor class.
 */
getInterceptor(object) {
  // This is a magic method: the compiler does specialization of it
  // depending on the uses of intercepted methods and instantiated
  // primitive types.
}

/**
 * The name of the property used on native classes and `Object.prototype` to get
 * the interceptor for a native class instance.
 * TODO(sra): The value should be initialized on isolate startup to a
 * cryptographic hash to prevent collisions.
 */
var dispatchPropertyName = '_zzyzx';

getDispatchProperty(object) {
  // TODO(sra): Implement the magic.
  // This is a magic method: the compiler replaces it with a runtime generated
  // function
  //
  //     function(object){return object._zzyzx;}
  //
  // where _zzyzx is replaced with the actual [dispatchPropertyName].
  //
  // The body is the CSP compliant version.
  return JS('', '#[#]', object, dispatchPropertyName);
}

setDispatchProperty(object, value) {
  // TODO(sra): Implement the magic.
  // This is a magic method: the compiler replaces it with a runtime generated
  // function
  //
  //     function(object, value){object._zzyzx = value;}
  //
  // where _zzyzx is replaced with the actual [dispatchPropertyName].
  //
  // The body is the CSP compliant version.
  JS('void', '#[#] = #', object, dispatchPropertyName, value);
}

makeDispatchRecord(interceptor, proto, extension) {
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
  //     proto  interceptor extension action
  //     -----  ----------- --------- ------
  //     false  I                     use interceptor I
  //     true   -                     use object
  //     P      I                     if object's prototype is P, use I
  //     F      -           P         if object's prototype is P, call F

  return JS('', '{i: #, p: #, e: #}', interceptor, proto, extension);
}

dispatchRecordInterceptor(record) => JS('', '#.i', record);
dispatchRecordProto(record) => JS('', '#.p', record);
dispatchRecordExtension(record) => JS('', '#.e', record);

/**
 * Returns the interceptor for a native class instance. Used by
 * [getInterceptor].
 */
getNativeInterceptor(object) {
  var record = getDispatchProperty(object);

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
      // The extension handler will do any required patching.  A typical use
      // case is where one native class represents two Dart classes.  The
      // extension method will inspect the native object instance to determine
      // its class and patch the instance.  Needed to fix dartbug.com/9654.
      return JS('', '(#)(#, #)', proto, object, record);
    }
  }

  record = lookupDispatchRecord(object);
  setDispatchProperty(JS('', 'Object.getPrototypeOf(#)', object), record);
  return getNativeInterceptor(object);
}

/**
 * If [Invocation.invokeOn] is being used, this variable
 * contains a JavaScript array with the names of methods that are
 * intercepted.
 */
var interceptedNames;

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
 * unintercepted classes have a redundant `receiver` argument and should ignore
 * it in favour of `this`.
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

  String toString() => Primitives.objectToString(this);

  dynamic noSuchMethod(Invocation invocation) {
    throw new NoSuchMethodError(this,
                                invocation.memberName,
                                invocation.positionalArguments,
                                invocation.namedArguments);
  }

  Type get runtimeType;
}

/**
 * The interceptor class for tear-off static methods. Unlike
 * tear-off instance methods, tear-off static methods are just the JS
 * function, and methods inherited from Object must therefore be
 * intercepted.
 */
class JSFunction extends Interceptor implements Function {
  const JSFunction();
  String toString() => 'Closure';
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
 * This class defines implementations for *all* methods on [Object] since the
 * the methods on Object assume the receiver is non-null.  This means that
 * JSNull will always be in the interceptor set for methods defined on Object.
 */
class JSNull extends Interceptor implements Null {
  const JSNull();

  bool operator ==(other) => identical(null, other);

  // Note: if you change this, also change the function [S].
  String toString() => 'null';

  int get hashCode => 0;

  Type get runtimeType => Null;
}


/**
 * The supertype for JSString and JSArray. Used by the backend as to
 * have a type mask that contains the primitive objects that we can
 * use the [] operator on.
 */
class JSIndexable {
}
