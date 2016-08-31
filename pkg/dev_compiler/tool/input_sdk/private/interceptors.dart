// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._interceptors;

import 'dart:collection';
import 'dart:_internal' hide Symbol;
import 'dart:_js_helper';
import 'dart:_foreign_helper' show JS;
import 'dart:math' show Random;

part 'js_array.dart';
part 'js_number.dart';
part 'js_string.dart';

// TODO(jmesserly): remove, this doesn't do anything for us.
abstract class Interceptor {
  const Interceptor();
}

// TODO(jmesserly): remove
getInterceptor(obj) => obj;

/**
 * The interceptor class for [bool].
 */
@JsPeerInterface(name: 'Boolean')
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
 * The supertype for JSString and JSArray. Used by the backend as to
 * have a type mask that contains the objects that we can use the
 * native JS [] operator and length on.
 */
abstract class JSIndexable {
  int get length;
  operator[](int index);
}

/**
 * The supertype for JSMutableArray and
 * JavaScriptIndexingBehavior. Used by the backend to have a type mask
 * that contains the objects we can use the JS []= operator on.
 */
abstract class JSMutableIndexable extends JSIndexable {
  operator[]=(int index, var value);
}

/**
 * The interface implemented by JavaScript objects.  These are methods in
 * addition to the regular Dart Object methods like [Object.hashCode].
 *
 * This is the type that should be exported by a JavaScript interop library.
 */
abstract class JSObject {
}


/**
 * Interceptor base class for JavaScript objects not recognized as some more
 * specific native type.
 */
abstract class JavaScriptObject extends Interceptor implements JSObject {
  const JavaScriptObject();

  // It would be impolite to stash a property on the object.
  int get hashCode => 0;

  Type get runtimeType => JSObject;
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

  String toString() => JS('String', 'String(#)', this);
}

// Obsolete in dart dev compiler. Added only so that the same version of
// dart:html can be used in dart2js an dev compiler.
// Warning: calls to these methods need to be removed before custom elements
// and cross-frame dom objects behave correctly in ddc.
// See https://github.com/dart-lang/dev_compiler/issues/517
findInterceptorConstructorForType(Type type) { }
findConstructorForNativeSubclassType(Type type, String name) { }
getNativeInterceptor(object) {}
setDispatchProperty(object, value) {}
