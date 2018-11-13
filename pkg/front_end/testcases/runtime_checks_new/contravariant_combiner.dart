// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

class B<T, U extends F<T>> {
  B<T, F<T>> operator +(other) => null;
}

class C {
  B<num, F<num>> x;
  static B<num, F<num>> y;
  B<num, F<num>> operator [](int i) => null;
  void operator []=(int i, B<num, F<num>> v) {}
}

void test1(B<num, F<num>> b) {
  b /*@checkReturn=B<num, (num) -> void>*/ += 1;
  var x = b /*@checkReturn=B<num, (num) -> void>*/ += 2;
}

void test2(C c) {
  c[0] /*@checkReturn=B<num, (num) -> void>*/ += 1;
  var x = c[0] /*@checkReturn=B<num, (num) -> void>*/ += 2;
}

void test3(C c) {
  c.x /*@checkReturn=B<num, (num) -> void>*/ += 1;
  var x = c.x /*@checkReturn=B<num, (num) -> void>*/ += 2;
}

void test4(C c) {
  C.y /*@checkReturn=B<num, (num) -> void>*/ += 1;
  var x = C.y /*@checkReturn=B<num, (num) -> void>*/ += 2;
}

void main() {}
