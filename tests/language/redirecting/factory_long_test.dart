// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test long substitution of long redirection chains.

import 'package:expect/expect.dart';

class C {
  const factory C() = D<int>;
}

class D<T> implements C {
  const factory D() = E<double, T>;
}

class E<S, T> implements D<T> {
  final field = 42;
  const E();
}

class X<T> {
  const factory X() = Y<T>;
}

class X1<T1> {
  const factory X1() = Y<T1>;
}

class X2 {
  const factory X2() = Y<int>;
}

class Y<S> implements X<S>, X1<S>, X2 {
  const factory Y() = Y1<S>;
}

class Y1<U> implements Y<U> {
  const factory Y1() = Z<U>;
}

class Z<V> implements Y1<V> {
  final field = 87;
  const Z();
}

void main() {
  testC(new C());
  testC(const C());
  testZ(new X<int>());
  testZ(new X1<int>());
  testZ(new X2());
  testZ(const X<int>());
  testZ(const X1<int>());
  testZ(const X2());
}

void testC(var c) {
  Expect.isTrue(c is C);
  Expect.isTrue(c is D<int>);
  Expect.isTrue(c is! D<String>);
  Expect.isTrue(c is E<double, int>);
  Expect.isTrue(c is! E<String, int>);
  Expect.isTrue(c is! E<double, String>);
  Expect.equals(42, c.field);
}

void testZ(var z) {
  Expect.isTrue(z is X<int>);
  Expect.isTrue(z is! X<String>);
  Expect.isTrue(z is X1<int>);
  Expect.isTrue(z is! X1<String>);
  Expect.isTrue(z is X2);
  Expect.isTrue(z is Y<int>);
  Expect.isTrue(z is! Y<String>);
  Expect.isTrue(z is Y1<int>);
  Expect.isTrue(z is! Y1<String>);
  Expect.isTrue(z is Z<int>);
  Expect.isTrue(z is! Z<String>);
  Expect.equals(87, z.field);
}
