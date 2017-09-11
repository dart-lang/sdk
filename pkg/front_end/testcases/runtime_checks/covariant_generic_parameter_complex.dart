// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C<T> {
  // List<T> is covariant in T so it needs checking
  void f1(List<T> /*@checkFormal=semiSafe*/ /*@checkInterface=semiTyped*/ x) {}

  // () -> T is covariant in T so it needs checking
  void f2(
      T /*@checkFormal=semiSafe*/ /*@checkInterface=semiTyped*/ callback()) {}

  // (T) -> T is partially covariant in T so it needs checking
  void f3(
      T /*@checkFormal=semiSafe*/ /*@checkInterface=semiTyped*/ callback(
          T x)) {}

  // (T) -> void is contravariant in T so it doesn't need checking
  void f4(void callback(T x)) {}
}

void g1(C<num> c, List<num> l) {
  c.f1(l);
}

void g2(C<num> c, num callback()) {
  c.f2(callback);
}

void g3(C<num> c, num callback(num x)) {
  c.f3(callback);
}

void g4(C<num> c, void callback(num x)) {
  c.f4(callback);
}

main() {}
