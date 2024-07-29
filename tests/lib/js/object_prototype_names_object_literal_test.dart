// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_util';

import 'package:expect/expect.dart';
import 'package:js/js.dart';

// Regression test for a bug that was introduced while attempting to fix
// https://github.com/dart-lang/sdk/issues/56315.
//
// - Property names that collide with properties on the native JavaScript
//   Object prototype should be assignable when creating an anonymous Object.
// - Reading those values should give you the value you set.
// - Reading those values without setting them should walk up the prototype
//   chain and find the native value.

@JS('Object.prototype.constructor')
external Object? get objectConstructor;
@JS('Object.prototype.hasOwnProperty')
external Object? get objectHasOwnProperty;
@JS('Object.prototype.isPrototypeOf')
external Object? get objectIsPrototypeOf;
@JS('Object.prototype.propertyIsEnumerable')
external Object? get objectPropertyIsEnumerable;
@JS('Object.prototype.toLocaleString')
external Object? get objectToLocaleString;
@JS('Object.prototype.toString')
external Object? get objectToString;
@JS('Object.prototype.valueOf')
external Object? get objectValueOf;

@JS()
@anonymous
class ObjectLiteral {
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

void main() {
  testObjectLiteralUnset();
  testObjectLiteralConflict();
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
