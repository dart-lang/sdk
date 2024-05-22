// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests invoking JS operators through js_util.

@JS()
library js_util_operator_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

@JS()
external void eval(String code);

@JS()
external Object? get undefinedObject;

@JS()
class Foo {
  external Foo();
}

main() {
  eval(r"""
    function Foo() {}
  """);

  test('typeofEquals', () {
    expect(js_util.typeofEquals(5, 'number'), isTrue);
    expect(js_util.typeofEquals(5, 'string'), isFalse);

    expect(js_util.typeofEquals('foo', 'string'), isTrue);
    expect(js_util.typeofEquals('foo', 'number'), isFalse);

    expect(js_util.typeofEquals(null, 'object'), isTrue);
    expect(js_util.typeofEquals(null, 'boolean'), isFalse);

    expect(js_util.typeofEquals(true, 'boolean'), isTrue);
    expect(js_util.typeofEquals(true, 'number'), isFalse);

    expect(js_util.typeofEquals(Foo(), 'object'), isTrue);
    expect(js_util.typeofEquals(Foo(), 'function'), isFalse);

    expect(js_util.typeofEquals(js_util.newObject(), 'object'), isTrue);
    expect(js_util.typeofEquals(js_util.newObject(), 'function'), isFalse);

    expect(js_util.typeofEquals([], 'object'), isTrue);
    expect(js_util.typeofEquals([], 'function'), isFalse);

    expect(js_util.typeofEquals(undefinedObject, 'undefined'), isTrue);
    expect(js_util.typeofEquals(undefinedObject, 'object'), isFalse);

    expect(
        js_util.typeofEquals(
            js_util.getProperty(js_util.globalThis, 'Foo'), 'function'),
        isTrue);
  });

  test('not', () {
    expect(js_util.not(true), isFalse);
    expect(js_util.not(false), isTrue);

    expect(js_util.not(null), isTrue);
    expect(js_util.not(''), isTrue);
    expect(js_util.not(0), isTrue);
    expect(js_util.not(undefinedObject), isTrue);

    expect(js_util.not([]), isFalse);
    expect(js_util.not({}), isFalse);
    expect(js_util.not(js_util.newObject()), isFalse);
    expect(js_util.not(Foo()), isFalse);
    expect(js_util.not('foo'), isFalse);
    expect(js_util.not(5), isFalse);
  });

  test('isTruthy', () {
    expect(js_util.isTruthy(true), isTrue);
    expect(js_util.isTruthy(false), isFalse);

    expect(js_util.isTruthy(null), isFalse);
    expect(js_util.isTruthy(''), isFalse);
    expect(js_util.isTruthy(0), isFalse);
    expect(js_util.isTruthy(undefinedObject), isFalse);

    expect(js_util.isTruthy([]), isTrue);
    expect(js_util.isTruthy({}), isTrue);
    expect(js_util.isTruthy(js_util.newObject()), isTrue);
    expect(js_util.isTruthy(Foo()), isTrue);
    expect(js_util.isTruthy('foo'), isTrue);
    expect(js_util.isTruthy(5), isTrue);
  });

  test('or', () {
    expect(js_util.or(true, false), isTrue);
    expect(js_util.or(true, true), isTrue);
    expect(js_util.or(false, true), isTrue);
    expect(js_util.or(false, false), isFalse);

    expect(js_util.or('foo', 'bar'), equals('foo'));
    expect(js_util.or(null, 'foo'), equals('foo'));
    expect(js_util.or(undefinedObject, 'foo'), equals('foo'));
    expect(js_util.or(0, 'foo'), equals('foo'));
    expect(js_util.or('', 'foo'), equals('foo'));
    expect(js_util.or([], 'bar'), equals([]));
    var o = js_util.newObject();
    expect(js_util.or(o, 'foo'), equals(o));
  });

  test('and', () {
    expect(js_util.and(true, false), isFalse);
    expect(js_util.and(true, true), isTrue);
    expect(js_util.and(false, true), isFalse);
    expect(js_util.and(false, false), isFalse);

    expect(js_util.and('foo', 'bar'), equals('bar'));
    expect(js_util.and(null, 'foo'), equals(null));
    // Should be undefined if we had JS types
    expect(js_util.and(undefinedObject, 'foo'), equals(null));
    expect(js_util.and(0, 'foo'), equals(0));
    expect(js_util.and([], 'bar'), equals('bar'));
    var o = js_util.newObject();
    expect(js_util.and(o, 'foo'), equals('foo'));
  });

  test('delete', () {
    var f = Foo();

    expect(js_util.delete(f, 'unknownProperty'), isTrue);

    expect(js_util.getProperty(f, 'a'), equals(null));
    js_util.setProperty(f, 'a', 'foo');
    expect(js_util.getProperty(f, 'a'), equals('foo'));
    expect(js_util.delete(f, 'a'), isTrue);
    expect(js_util.getProperty(f, 'a'), equals(null));
  });

  test('unsignedRightShift', () {
    expect(js_util.unsignedRightShift(9, 2), equals(2));
    expect(js_util.unsignedRightShift(-9, 2), equals(1073741821));

    expect(js_util.unsignedRightShift(1, 'a'), equals(1));
    expect(js_util.unsignedRightShift(1, null), equals(1));
    expect(js_util.unsignedRightShift(1, undefinedObject), equals(1));
    expect(js_util.unsignedRightShift(1, false), equals(1));
    expect(js_util.unsignedRightShift(1, []), equals(1));

    expect(js_util.unsignedRightShift('a', 1), equals(0));
    expect(js_util.unsignedRightShift(null, 1), equals(0));
    expect(js_util.unsignedRightShift(undefinedObject, 1), equals(0));
    expect(js_util.unsignedRightShift(false, 1), equals(0));
    expect(js_util.unsignedRightShift([], 1), equals(0));
  });
}
