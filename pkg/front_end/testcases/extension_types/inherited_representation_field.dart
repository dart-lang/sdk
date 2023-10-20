// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'inherited_representation_field_lib.dart';

extension type A(int a) {}

extension type B(int b) implements A {
  methodA() => a;
  methodB() => b;
}

extension type C(int _c) {}

extension type E(int _e) implements D {
  methodC() => _c;
}

extension type G<T>(T g) {}
extension type H<T>(List<T> h) implements G<List<T>> {}

main() {
  A a = A(42);
  expect(42, a.a);

  B b = B(87);
  expect(87, b.a);
  expect(87, b.b);
  expect(87, b.methodA());
  expect(87, b.methodB());

  C c = C(123);
  expect(123, c._c);

  D d = D(442);
  expect(442, d._c);

  E e = E(872);
  expect(872, e._c);
  expect(872, e._e);
  expect(872, e.methodC());

  F f = F(1023);
  expect(1023, f._c);
  expect(1023, f._e);
  expect(1023, f.methodC());
  expect(1023, f.methodD());

  G<int> g1 = G<int>(72);
  var g1_g = g1.g;
  int g1_alias = g1_g;
  expect(72, g1.g);

  G<String> g2 = G<String>('72');
  var g2_g = g2.g;
  String g2_alias = g2_g;
  expect('72', g2.g);

  List<int> list1 = [97];
  H<int> h1 = H(list1);
  var h1_g = h1.g;
  List<int> h1_g_alias = h1_g;
  expect(list1, h1.g);
  var h1_h = h1.h;
  List<int> h1_h_alias = h1_h;
  expect(list1, h1.h);

  List<String> list2 = ['foo'];
  H<String> h2 = H(list2);
  var h2_g = h2.g;
  List<String> h2_g_alias = h2_g;
  expect(list2, h2.g);
  var h2_h = h2.h;
  List<String> h2_h_alias = h2_h;
  expect(list2, h2.h);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
