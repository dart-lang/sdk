// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface class I {
  String get id => "I";
}

class C1 {}

augment class C1 implements I {
  String get id => "C1";
}

class C2 implements I {}

augment class C2 implements I {
  String get id => "C2";
}

class C3 {}

augment class C3 implements I, I {
  String get id => "C3";
}


mixin M1 {}

augment mixin M1 implements I {
  String get id => "M1";
}

mixin M2 implements I {}

augment mixin M2 implements I {
  String get id => "M2";
}

mixin M3 {}

augment mixin M3 implements I, I {
  String get id => "M3";
}

enum E1 {
  e1;
}

augment enum E1 implements I {
  ;
  String get id => "E1";
}

enum E2 implements I {
  e1;
}

augment enum E2 implements I {
  ;
  String get id => "E2";
}

enum E3 {
  e1;
}

augment enum E3 implements I, I {
  ;
  String get id => "E3";
}

extension type ET1(I v) {}

augment extension type ET1 implements I {
  String get id => "ET1";
}

extension type ET2(I v) implements I {}

augment extension type ET2 implements I {
  String get id => "ET2";
}

extension type ET3(I v) {}

augment extension type ET3 implements I, I {
  String get id => "ET3";
}

class MA1 = Object with M1;

class MA2 = Object with M2;

class MA3 = Object with M3;

main() {
  I c1 = C1();
  I c2 = C2();
  I c3 = C3();
  I m1 = MA1();
  I m2 = MA2();
  I m3 = MA3();
  I e1 = E1.e1;
  I e2 = E2.e1;
  I e3 = E3.e1;
  I et1 = ET1(I());
  I et2 = ET2(I());
  I et3 = ET3(I());
  expect("C1", c1.id);
  expect("C2", c2.id);
  expect("C3", c3.id);
  expect("M1", m1.id);
  expect("M2", m2.id);
  expect("M3", m3.id);
  expect("E1", e1.id);
  expect("E2", e2.id);
  expect("E3", e3.id);
  expect("I", et1.id);
  expect("I", et2.id);
  expect("I", et3.id);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual.';
}
