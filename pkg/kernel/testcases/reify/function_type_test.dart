// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_type_test;

import 'test_base.dart';

class A {}

class B extends A {}

class C extends A {}

class D implements Function {
  B call(A a) {
    return null;
  }
}

class ER0P1 {
  void call([A a]) {}
}

class ER1P0 {
  void call(A a) {}
}

class ER1P1 {
  void call(A a, [B b]) {}
}

class ER1P2 {
  void call(A a, [B b, C c]) {}
}

class ER2P1 {
  void call(A a, B b, [C c]) {}
}

class ER0N1 {
  void call({A a}) {}
}

class ER1N0 {
  void call(A a) {}
}

class ER1N1 {
  void call(A a, {B b}) {}
}

class ER1N2 {
  void call(A a, {B b, C c}) {}
}

class ER2N1 {
  void call(A a, B b, {C c}) {}
}

class ER0N8 {
  void call({kE, ii, oP, Ij, pA, zD, aZ, UU}) {}
}

C foo(A a) {
  return null;
}

typedef B A2B(A a);

typedef C C2C(C c);

typedef void R0P1([A a]);
typedef void R1P0(A a);
typedef void R1P1(A a, [B b]);
typedef void R1P2(A a, [B b, C c]);
typedef void R2P1(A a, B b, [C c]);

typedef void R0N1({A a});
typedef void R1N0(A a);
typedef void R1N1(A a, {B b});
typedef void R1N2(A a, {B b, C c});
typedef void R2N1(A a, B b, {C c});

typedef void R0N8({aZ, oP, Ij, kE, pA, zD, UU, ii});

void test(x) {
  write(x is Function);
  write(x is A2B);
  write(x is C2C);

  write(x is R0P1);
  write(x is R1P0);
  write(x is R1P1);
  write(x is R1P2);
  write(x is R2P1);

  write(x is R0N1);
  write(x is R1N0);
  write(x is R1N1);
  write(x is R1N2);
  write(x is R2N1);
}

main() {
  test(new D());
  for (var c in [
    new ER0P1(),
    new ER1P0(),
    new ER1P1(),
    new ER1P2(),
    new ER2P1(),
    new ER0N1(),
    new ER1N0(),
    new ER1N1(),
    new ER1N2(),
    new ER2N1()
  ]) {
    test(c);
  }

  expectOutput("""
true
true
false
false
true
false
false
false
false
true
false
false
false
true
false
false
true
true
false
false
false
false
true
false
false
false
true
false
false
false
true
false
false
false
false
true
false
false
false
true
false
false
false
true
true
false
false
false
true
false
false
false
true
false
false
false
true
true
true
true
false
true
false
false
false
true
false
false
false
false
false
false
true
false
false
false
false
false
true
false
false
false
false
false
false
false
true
false
false
false
false
true
false
false
false
true
false
false
false
false
true
false
false
false
true
false
false
false
true
false
false
false
false
true
true
false
false
true
false
false
false
true
false
false
false
false
true
true
true
false
true
false
false
false
false
false
false
false
false
false
false
false
true""");
}
