// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class B<T> {
  void f(T /*@covariance=genericInterface, genericImpl*/ x) {}
}

class /*@forwardingStub=abstract void f(covariance=(genericImpl) int x)*/ C
    extends B<int> {}

void g1(B<num> b) {
  b.f(1.5);
}

void g2(C c) {
  c.f(1);
}

void test() {
  g1(new C());
}

void main() {}
