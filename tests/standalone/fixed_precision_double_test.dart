// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

bool testAssociativity(Function f) {
  // Example from https://en.wikipedia.org/wiki/Floating_point
  // Test that (a + b) + c == a + (b + c).
  double a = f(1234.567);  // Chop literals.
  double b = f(45.67834);
  double c = f(0.0004);
  double x = (a + b) + c;  // Chop result of multiplication or division only.
  double y = a + (b + c);
  print("x: $x");
  print("y: $y");
  return x == y;
}

bool testDistributivity(Function f) {
  // Example from https://en.wikipedia.org/wiki/Floating_point
  // Test that (a + b)*c == a*c + b*c.
  double a = f(1234.567);  // Chop literals.
  double b = f(1.234567);
  double c = f(3.333333);
  double x = f((a + b)*c);  // Chop result of multiplication.
  double y = f(a*c) + f(b*c);
  print("x: $x");
  print("y: $y");
  return x == y;
}

// Simulate precision checking with assert.
assertP(double d) {
  assert(d == d.p);
}

bool assertionsEnabled() {
  try {
    assert(false);
    return false;
  } on AssertionError catch (e) {
    return true;
  }
  return false;
}

main() {
  // The getter p keeps only 20 (by default) bits after the decimal point.
  Expect.equals(0.0, 0.0.p);  // 0.0 has no 1-bit after the decimal point.
  Expect.equals(1.5, 1.5.p);  // 1.5 has a single 1-bit after the decimal point.
  Expect.notEquals(1.1, 1.1.p);  // 1.1 has many 1-bits after the decimal point.
  Expect.notEquals(1/3, (1/3).p);  // 0.33333333... ditto.

  Expect.equals(1.1 + 1/3, 1/3 + 1.1);  // Test addition commutativity.
  Expect.equals(1.1.p + (1/3).p, (1/3).p + 1.1.p);
  Expect.equals(1.1 * 1/3, 1/3 * 1.1);  // Test multiplication commutativity.
  Expect.equals(1.1.p * (1/3).p, (1/3).p * 1.1.p);

  print("Without chopping fractional bits:");
  Expect.isFalse(testAssociativity((x) => x));
  Expect.isFalse(testDistributivity((x) => x));
  print("With chopping fractional bits:");
  Expect.isTrue(testAssociativity((x) => x.p));
  Expect.isTrue(testDistributivity((x) => x.p));

  // Check that p works with NaN and Infinity.
  Expect.isTrue(double.NAN.p.isNaN);
  Expect.isTrue(double.INFINITY.p.isInfinite);
  Expect.isFalse(double.INFINITY.p.isNegative);
  Expect.isTrue(double.NEGATIVE_INFINITY.p.isInfinite);
  Expect.isTrue(double.NEGATIVE_INFINITY.p.isNegative);

  // Check use of assert to verify precision.
  if (assertionsEnabled()) {
    assertP(1.5);
    assertP(1.1.p);
    Expect.throws(() => assertP(1.1), (e) => e is AssertionError);
    assertP(1.23456789.p);
    Expect.throws(() => assertP(1.23456789), (e) => e is AssertionError);
  }
}
