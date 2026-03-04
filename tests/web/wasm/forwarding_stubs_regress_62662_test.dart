// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/62662

import 'package:expect/expect.dart';

void main() {
  testFieldForwardingStub();
  testTypeParameterForwardingStub();
  testPositionalParameterForwardingStub();
  testNamedParameterForwardingStub();
}

void testFieldForwardingStub() {
  final Box<Object> object = Sub();
  object.field = 1;
  Expect.throws<TypeError>(() => object.field = 'not an int');
  Expect.equals(1, object.field);
}

void testTypeParameterForwardingStub() {
  final Box<Object> object = Sub();
  object.foo<List<int>>(<int>[1]);
  Expect.throws<TypeError>(() => object.foo<List<Object>>(<Object>['a']));
}

void testPositionalParameterForwardingStub() {
  final Box<Object> object = Sub();
  object.bar(1);
  object.bar(2);
  Expect.throws<TypeError>(() => object.bar('a'));
}

void testNamedParameterForwardingStub() {
  final Box<Object> object = Sub();
  object.baz();
  object.baz(w: Object());
  object.baz(x: -1);
  object.baz(y: Object());
  object.baz(z: 0);
  object.baz(w: Object(), x: 1);
  object.baz(x: 2, w: Object());
  object.baz(w: Object(), x: 3, y: Object(), z: 4);
  object.baz(z: 5, y: Object(), x: 6, w: Object());
  Expect.throws<TypeError>(() => object.baz(x: 'a'));
  Expect.throws<TypeError>(() => object.baz(z: 'a'));
}

abstract class Box<T> {
  T? field;
  void foo<H extends List<T>>(H a);
  void bar(T a);
  void baz({T? z, Object? y, T? x, Object? w});
}

class Base {
  int? field;
  void foo<H extends List<int>>(List<int> a) =>
      print('Base.foo<$H>(${1 + a[0]})');
  void bar(int a) => print('Base.bar($a)');
  void baz({Object? w, int? x, Object? y, int? z}) =>
      print('Base.baz({w: $w, x: $x, y: $y, z: $z})');
}

class Sub extends Base implements Box<int> {}
