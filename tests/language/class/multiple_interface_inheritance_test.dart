// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class I1 {
  void f(int i);
}

abstract class I2 {
  void f(Object o);
}

abstract class C implements I1, I2 {}

class D extends C {
  void f(Object o) {}
}

abstract class E implements I2, I1 {}

class F extends E {
  void f(Object o) {}
}

void g1(C c) {
  c.f('hi');
}

void g2(E e) {
  e.f('hi');
}

main() {
  g1(new D());
  g2(new F());
}
