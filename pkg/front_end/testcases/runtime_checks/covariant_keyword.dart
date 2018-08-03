// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef F<T>(T x);

class C {
  void f(num x) {}
}

class D extends C {
  void f(covariant int /*@covariance=explicit*/ x) {}
}

class E extends D {
  void f(int /*@covariance=explicit*/ x) {}
}

void g1(C c) {
  c.f(1.5);
}

F<num> g2(C c) {
  return c.f;
}

test() {
  g1(new D());
  F<num> x = g2(new D());
}

main() {}
