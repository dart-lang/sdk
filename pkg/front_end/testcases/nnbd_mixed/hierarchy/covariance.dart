// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From language/covariant_override/tear_off_type_test

// If a parameter is directly or indirectly a covariant override, its type in
// the method tear-off should become Object?.

class M1 {
  method(covariant int a, int b) {}
}

class M2 {
  method(int a, covariant int b) {}
}

class C extends Object with M1, M2 {}

class Direct {
  void positional(covariant int a, int b, covariant int c, int d, int e) {}
  void optional(
      [covariant int a = 0, int b = 0, covariant int c = 0, int d = 0]) {}
  void named(
      {covariant int a = 0, int b = 0, covariant int c = 0, int d = 0}) {}
}

class Inherited extends Direct {}

// ---

class Override1 {
  void method(covariant int a, int b, int c, int d, int e) {}
}

class Override2 extends Override1 {
  void method(int a, int b, covariant int c, int d, int e) {}
}

class Override3 extends Override2 {
  void method(int a, int b, int c, int d, int e) {}
}

// ---

abstract class Implement1 {
  void method(covariant int a, int b, int c, int d, int e) {}
}

class Implement2 {
  void method(int a, covariant int b, int c, int d, int e) {}
}

class Implement3 {
  void method(int a, int b, covariant int c, int d, int e) {}
}

class Implement4 implements Implement3 {
  void method(int a, int b, int c, covariant int d, int e) {}
}

class Implement5 implements Implement1, Implement2, Implement4 {
  void method(int a, int b, int c, int d, covariant int e) {}
}

// ---

class Interface1 {
  void method(covariant int a, int b, int c, int d, int e) {}
}

class Interface2 {
  void method(int a, covariant int b, int c, int d, int e) {}
}

class Mixin1 {
  void method(int a, int b, covariant int c, int d, int e) {}
}

class Mixin2 {
  void method(int a, int b, int c, covariant int d, int e) {}
}

class Superclass {
  void method(int a, int b, int c, int d, covariant int e) {}
}

class Mixed extends Superclass
    with Mixin1, Mixin2
    implements Interface1, Interface2 {}

void main() {}
