// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that branch fusion correctly sets branch environment for comparisons
// that require unboxing and does not fuse branches that can deoptimize.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

var sideEffect = true;

barDouble(a, b) {
  sideEffect = false;
  final result = (a == b);
  sideEffect = !sideEffect;
  return result;
}

fooDouble(a, b) => barDouble(a, b) ? 1 : 0;

barMint(a, b) {
  sideEffect = false;
  final result = (a == b);
  sideEffect = !sideEffect;
  return result;
}

fooMint(a, b) => barMint(a, b) ? 1 : 0;

class A {
  operator ==(other) => identical(this, other);
}

class B extends A {}

class C extends A {}

barPoly(a, b) {
  sideEffect = false;
  final result = a == b;
  sideEffect = !sideEffect;
  return result;
}

fooPoly(a, b) => barPoly(a, b) ? 1 : 0;

main() {
  final a = 1.0;
  final b = 1 << 62;
  final x = new A(), y = new B(), z = new C();
  for (var i = 0; i < 20; i++) {
    Expect.equals(1, fooDouble(a, a));
    Expect.isTrue(sideEffect);
    Expect.equals(0, fooMint(b, 0));
    Expect.isTrue(sideEffect);
    Expect.equals(1, fooPoly(x, x));
    Expect.equals(0, fooPoly(y, x));
  }
  Expect.equals(1, fooDouble(z, z));
  Expect.isTrue(sideEffect);
  Expect.equals(1, fooMint(z, z));
  Expect.isTrue(sideEffect);
  Expect.equals(1, fooPoly(z, z));
  Expect.isTrue(sideEffect);
}
