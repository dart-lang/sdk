// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class B {
  void f(int x) {}
}

abstract class I<T> {
  void f(T /*@covariance=genericInterface, genericImpl*/ x);
}

class M {
  void f(int x) {}
}

class /*@forwardingStub=void f(semiSafe int x)*/ C = B with M implements I<int>;
void g1(C c) {
  c.f(1);
}

void g2(I<num> i) {
  i.f(1.5);
}

void test() {
  g2(new C());
}

void main() {}
