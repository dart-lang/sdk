// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

import 'package:expect/expect.dart';

abstract class A {
  (Object?, dynamic) method();
  (Object?, dynamic) get getter;
  void set setter((int, int) Function(Object?, dynamic) f);
}

abstract class B {
  (dynamic, Object?) method();
  (dynamic, Object?) get getter;
  void set setter((int, int) Function(dynamic, Object?) f);
}

class C implements A, B {
  (int, int) method() => (42, 87);
  (int, int) get getter => (42, 87);
  void set setter((int, int) Function(dynamic, dynamic) f) {}
}

extension type E(C c) implements A, B {}

void method(E e) {
  var (a, b) = e.method();
  Expect.equals(42, a);
  Expect.equals(87, b);
  var (c, d) = e.getter;
  Expect.equals(42, c);
  Expect.equals(87, d);
  e.setter = (dynamic a, dynamic b) => (42, 87);
  var f = e.method;
  var (g, h) = f();
  Expect.equals(42, g);
  Expect.equals(87, h);
}

main() {
  method(E(C()));
}
