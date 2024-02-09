// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type E1(int i) {
  set m1(_) {}
  void m2() {}
  get m3 => 1;
  set m4(_) {}
}

extension type E2(int i) implements E1 {
  void m1() {} // OK, and `E2` does not have a setter named `m1=`.
  set m2(_) {} // OK, and `E2` does not have a method named `m2`.
  set m3(_) {} // OK, and `E2` has the full getter/setter pair.
  get m4 => 1; // OK, and `E2` has the full getter/setter pair.
}

void test() {
  var e2 = E2(1);
  e2.m1(); // OK.
  e2.m1 = 10; // Compile-time error.
  e2.m2 = 10; // OK.
  e2.m2(); // Compile-time error.
}