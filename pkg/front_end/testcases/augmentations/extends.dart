// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A;
class B;
augment class B extends A;

class C extends A;
augment class C extends A; // Error

class D;
augment class D extends A;
augment class D extends A; // Error

class E extends A;
augment class E extends B; // Error

class F;
augment class F extends A;
augment class F extends B; // Error

main() {
  expect(true, C() is A);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual.';
}
