// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C<T> {
  void f(T /*@covariance=genericInterface, genericImpl*/ x) {}
}

void g1(C<num> c) {
  c.f(1.5);
}

void g2(C<int> c) {
  c.f(1);
}

void g3(C<num> c) {
  c.f(null);
}

main() {}
