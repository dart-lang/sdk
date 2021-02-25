// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an assignment inside a complex promotion scope defeats all pending
// promotions, whether introduced directly or through LHS or RHS of a logical
// and expression.

class A {}

class B extends A {}

class C extends A {}

class D extends B {}

class E extends D {}

// An invocation of the form `checkNotB(x)` verifies that the static type of `x`
// is not `B`, since `B` is not assignable to `C`.
dynamic checkNotB(C c) => null;

test([A a]) {
  if (a is B && a is D) {
    if (a is E) {
      checkNotB(a);
      a = null;
    }
  }
}

main() {
  test();
}
