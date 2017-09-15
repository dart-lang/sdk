// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

abstract class I<T> {
  void f1(T /*@covariance=genericInterface, genericImpl*/ x);
  void f2(T /*@covariance=genericInterface, genericImpl*/ x);
}

class C<U> implements I<int> {
  void f1(int /*@covariance=genericImpl*/ x) {}
  void f2(int /*@covariance=genericImpl*/ x,
      [U /*@covariance=genericInterface, genericImpl*/ y]) {}
}

class D<U> extends C<U> {
  void f1(int /*@covariance=genericImpl*/ x) {}
  void f2(int /*@covariance=genericImpl*/ x,
      [U /*@covariance=genericInterface, genericImpl*/ y]) {}
}

void g1(C<num> c) {
  c.f1(1);
}

void g2(I<num> i) {
  i.f1(1.5);
}

void g3(C<num> c) {
  c.f2(1, 1.5);
}

void g4(D<num> d) {
  d.f1(1);
}

void g5(D<num> d) {
  d.f2(1, 1.5);
}

void test() {
  g2(new C<num>());
}

void main() {}
