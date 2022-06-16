// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_util';

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS()
external void eval(String code);

void createObjectTest() {
  Object o = newObject();
  Expect.isFalse(hasProperty(o, 'foo'));
  Expect.equals('bar', setProperty(o, 'foo', 'bar'));
  Expect.isTrue(hasProperty(o, 'foo'));
  Expect.equals('bar', getProperty(o, 'foo'));
}

// Unfortunately, lists do not currently compare identically.
void _expectListEquals(List<Object?> l, List<Object?> r) {
  Expect.equals(l.length, r.length);
  for (int i = 0; i < l.length; i++) {
    Expect.equals(l[i], r[i]);
  }
}

void evalAndConstructTest() {
  eval(r'''
    function JSClass(c) {
      this.c = c;
      this.sum = (a, b) => {
        return a + b + this.c;
      }
      this.list = ['a', 'b', 'c'];
    }
    globalThis.JSClass = JSClass;
  ''');
  Object gt = globalThis;
  Object constructor = getProperty(gt, 'JSClass');
  Object jsClass = callConstructor(constructor, ['world!']);
  Expect.equals('hello world!', callMethod(jsClass, 'sum', ['hello', ' ']));
  _expectListEquals(
      ['a', 'b', 'c'], getProperty(jsClass, 'list') as List<Object?>);
}

class Foo {
  final int i;
  Foo(this.i);
}

void dartObjectRoundTripTest() {
  Object o = newObject();
  setProperty(o, 'foo', Foo(4));
  Object foo = getProperty(o, 'foo')!;
  Expect.equals(4, (foo as Foo).i);
}

void deepConversionsTest() {
  // Dart to JS.
  // TODO(joshualitt): Consider supporting `null` in jsify.
  // Expect.isNull(dartify(jsify(null)));
  Expect.equals(true, dartify(jsify(true)));
  Expect.equals(2.0, dartify(jsify(2.0)));
  Expect.equals('foo', dartify(jsify('foo')));
  _expectListEquals(
      ['a', 'b', 'c'], dartify(jsify(['a', 'b', 'c'])) as List<Object?>);

  // JS to Dart.
  eval(r'''
    globalThis.a = null;
    globalThis.b = 'foo';
    globalThis.c = ['a', 'b', 'c'];
    globalThis.d = 2.5;
    globalThis.e = true;
    globalThis.f = function () { return 'hello world'; };
    globalThis.invoke = function (f) { return f(); }
  ''');
  Object gt = globalThis;
  Expect.isNull(getProperty(gt, 'a'));
  Expect.equals('foo', getProperty(gt, 'b'));
  _expectListEquals(['a', 'b', 'c'], getProperty<List<Object?>>(gt, 'c'));
  Expect.equals(2.5, getProperty(gt, 'd'));
  Expect.equals(true, getProperty(gt, 'e'));

  // Confirm a function that takes a roundtrip remains a function.
  Expect.equals('hello world',
      callMethod(gt, 'invoke', <Object?>[dartify(getProperty(gt, 'f'))]));
}

void main() {
  createObjectTest();
  evalAndConstructTest();
  dartObjectRoundTripTest();
  deepConversionsTest();
}
