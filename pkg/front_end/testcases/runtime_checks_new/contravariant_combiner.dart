// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

typedef void F<T>(T x);

class B<T, U extends F<T>> {
  B<T, F<T>> operator +(other) => throw '';
}

class C {
  B<num, F<num>> x = throw '';
  static B<num, F<num>> y = throw '';
  B<num, F<num>> operator [](int i) => throw '';
  void operator []=(int i, B<num, F<num>> v) {}
}

void test1(B<num, F<num>> b) {
  b += 1;
  var x = b += 2;
}

void test2(C c) {
  c[0] += 1;
  var x = c[0] += 2;
}

void test3(C c) {
  c.x += 1;
  var x = c.x += 2;
}

void test4(C c) {
  C.y += 1;
  var x = C.y += 2;
}

void main() {}
