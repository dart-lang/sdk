// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

typedef U G<T, U>(T x);

class C<T> {
  void f1(T /*@checkFormal=semiSafe*/ x) {}
  T f2(List<T> /*@checkFormal=semiSafe*/ x) => x.first;
}

F<num> g1(C<num> c) {
  return c.f1;
}

void g2(C<int> c, Object x) {
  F<Object> f = g1(c) as F<Object>;
  f /*@checkCall=interface(semiTyped:0)*/ (x);
}

G<List<num>, num> g3(C<num> c) {
  return c.f2;
}

void test() {
  var x = g1(new C<int>());
  x /*@checkCall=interface(semiTyped:0)*/ (1.5);
  g3(new C<int>());
}

main() {}
