// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

class C<T> {
  void f(T /*@checkFormal=semiSafe*/ x) {}
}

void g1(C<num> c) {
  c.f;
}

void g2(C<int> c, Object x) {
  F<Object> f = g1(c) as F<Object>;
  f /*@checkCall=interface(semiTyped:0)*/ (x);
}

void test() {
  var x = g1(new C<int>());
  x /*@checkCall=interface(semiTyped:0)*/ (1.5);
}

main() {}
