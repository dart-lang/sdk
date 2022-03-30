// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_util_wasm';

import 'package:expect/expect.dart';

void createObjectTest() {
  JSValue o = newObject();
  Expect.isFalse(hasProperty(o, 'foo'));
  Expect.equals('bar', setProperty(o, 'foo', 'bar'.toJS()).toString());
  Expect.isTrue(hasProperty(o, 'foo'));
  Expect.equals('bar', getProperty(o, 'foo').toString());
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
  JSValue gt = globalThis();
  JSValue jsClass = callConstructorVarArgs(gt, 'JSClass', ['world!'.toJS()]);
  Expect.equals(
      'hello world!',
      callMethodVarArgs(jsClass, 'sum', ['hello'.toJS(), ' '.toJS()])
          .toString());
  _expectListEquals(
      ['a', 'b', 'c'], getProperty(jsClass, 'list')!.toObjectList());
}

class Foo {
  final int i;
  Foo(this.i);
}

void dartObjectRoundTripTest() {
  JSValue o = newObject();
  setProperty(o, 'foo', Foo(4).toJS());
  Object foo = getProperty(o, 'foo')!.toObject();
  Expect.equals(4, (foo as Foo).i);
}

void deepConversionsTest() {
  // Dart to JS.
  Expect.isNull(dartify(jsify(null)));
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
  ''');
  JSValue gt = globalThis();
  Expect.isNull(dartify(getProperty(gt, 'a')));
  Expect.equals('foo', dartify(getProperty(gt, 'b')));
  _expectListEquals(
      ['a', 'b', 'c'], dartify(getProperty(gt, 'c')) as List<Object?>);
}

void main() {
  createObjectTest();
  evalAndConstructTest();
  dartObjectRoundTripTest();
  deepConversionsTest();
}
