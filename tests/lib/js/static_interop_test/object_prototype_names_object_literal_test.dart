// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_util';

import 'package:expect/expect.dart';

// Regression test for a bug that was introduced while attempting to fix
// https://github.com/dart-lang/sdk/issues/56315.
//
// - Property names that collide with properties on the native JavaScript
//   Object prototype should be assignable when creating an anonymous Object.
// - Reading those values should give you the value you set.
// - Reading those values without setting them should walk up the prototype
//   chain and find the native value.

@JS('Object.prototype.constructor')
external JSAny? get objectConstructor;
@JS('Object.prototype.hasOwnProperty')
external JSAny? get objectHasOwnProperty;
@JS('Object.prototype.isPrototypeOf')
external JSAny? get objectIsPrototypeOf;
@JS('Object.prototype.propertyIsEnumerable')
external JSAny? get objectPropertyIsEnumerable;
@JS('Object.prototype.toLocaleString')
external JSAny? get objectToLocaleString;
@JS('Object.prototype.toString')
external JSAny? get objectToString;
@JS('Object.prototype.valueOf')
external JSAny? get objectValueOf;

extension type ObjectLiteral._(JSObject _) implements JSObject {
  external factory ObjectLiteral.named({
    int a,
    String constructor,
    bool hasOwnProperty,
    int isPrototypeOf,
    String propertyIsEnumerable,
    bool toLocaleString,
    int toString,
    String valueOf,
    // Other members on the native JavaScript Object prototype are not valid
    // as named arguments because they begin with `_` and renaming arguments
    // with `@JS()` is not supported at this time.
    // - '__defineGetter__',
    // - '__lookupGetter__',
    // - '__defineSetter__',
    // - '__lookupSetter__',
    // - '__proto__'
  });
}

@JS()
@staticInterop
@anonymous
class ObjectLiteralStaticInterop {
  external factory ObjectLiteralStaticInterop.named({
    int a,
    String constructor,
    bool hasOwnProperty,
    int isPrototypeOf,
    String propertyIsEnumerable,
    bool toLocaleString,
    int toString,
    String valueOf,
    // Other members on the native JavaScript Object prototype are not valid
    // as named arguments because they begin with `_` and renaming arguments
    // with `@JS()` is not supported at this time.
    // - '__defineGetter__',
    // - '__lookupGetter__',
    // - '__defineSetter__',
    // - '__lookupSetter__',
    // - '__proto__'
  });
}

void main() {
  testObjectLiteralUnset();
  testObjectLiteralStaticInteropUnset();
  testObjectLiteralConflict();
  // testObjectLiteralStaticInteropConflict();
}

testObjectLiteralUnset() {
  var obj = ObjectLiteral.named(a: 1);
  // Set properties have the expected value.
  Expect.equals(1, getProperty(obj, 'a'));
  // Unset properties have the value found up the prototype chain.
  Expect.equals(objectConstructor, getProperty(obj, 'constructor'));
  Expect.equals(objectHasOwnProperty, getProperty(obj, 'hasOwnProperty'));
  Expect.equals(objectIsPrototypeOf, getProperty(obj, 'isPrototypeOf'));
  Expect.equals(
      objectPropertyIsEnumerable, getProperty(obj, 'propertyIsEnumerable'));
  Expect.equals(objectToLocaleString, getProperty(obj, 'toLocaleString'));
  Expect.equals(objectToString, getProperty(obj, 'toString'));
  Expect.equals(objectValueOf, getProperty(obj, 'valueOf'));
}

testObjectLiteralStaticInteropUnset() {
  var obj = ObjectLiteralStaticInterop.named(a: 1);
  // Set properties have the expected value.
  Expect.equals(1, getProperty(obj, 'a'));
  // Unset properties have the value found up the prototype chain.
  Expect.equals(objectConstructor, getProperty(obj, 'constructor'));
  Expect.equals(objectHasOwnProperty, getProperty(obj, 'hasOwnProperty'));
  Expect.equals(objectIsPrototypeOf, getProperty(obj, 'isPrototypeOf'));
  Expect.equals(
      objectPropertyIsEnumerable, getProperty(obj, 'propertyIsEnumerable'));
  Expect.equals(objectToLocaleString, getProperty(obj, 'toLocaleString'));
  Expect.equals(objectToString, getProperty(obj, 'toString'));
  Expect.equals(objectValueOf, getProperty(obj, 'valueOf'));
}

testObjectLiteralConflict() {
  var obj = ObjectLiteral.named(
      constructor: 'Cello',
      hasOwnProperty: true,
      isPrototypeOf: 5,
      propertyIsEnumerable: 'Fosse',
      toLocaleString: false,
      toString: 16,
      valueOf: 'Cello');
  // Unset properties are null.
  Expect.isNull(getProperty(obj, 'a'));
  // Set properties have the expected value.
  Expect.equals('Cello', getProperty(obj, 'constructor'));
  Expect.equals(true, getProperty(obj, 'hasOwnProperty'));
  Expect.equals(5, getProperty(obj, 'isPrototypeOf'));
  Expect.equals('Fosse', getProperty(obj, 'propertyIsEnumerable'));
  Expect.equals(false, getProperty(obj, 'toLocaleString'));
  Expect.equals(16, getProperty(obj, 'toString'));
  Expect.equals('Cello', getProperty(obj, 'valueOf'));
}

testConflictStaticInterop() {
  var obj = ObjectLiteralStaticInterop.named(
      constructor: 'Cello',
      hasOwnProperty: true,
      isPrototypeOf: 5,
      propertyIsEnumerable: 'Fosse',
      toLocaleString: false,
      toString: 16,
      valueOf: 'Cello') as JSObject;
  // Unset properties are null.
  Expect.isNull(getProperty(obj, 'a'));
  // Set properties have the expected value.
  Expect.equals('Cello', getProperty(obj, 'constructor'));
  Expect.equals(true, getProperty(obj, 'hasOwnProperty'));
  Expect.equals(5, getProperty(obj, 'isPrototypeOf'));
  Expect.equals('Fosse', getProperty(obj, 'propertyIsEnumerable'));
  Expect.equals(false, getProperty(obj, 'toLocaleString'));
  Expect.equals(16, getProperty(obj, 'toString'));
  Expect.equals('Cello', getProperty(obj, 'valueOf'));
}
