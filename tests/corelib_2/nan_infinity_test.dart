// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for testing NaN and Infinity.

void main() {
  // Sanity tests.
  Expect.isFalse(1.5.isNaN);
  Expect.isFalse(1.5.isInfinite);
  Expect.isTrue(1.5.isFinite);
  Expect.isFalse(1.5.isNegative);
  Expect.isTrue((-1.5).isNegative);
  Expect.isFalse(0.0.isNegative);
  Expect.isTrue((-0.0).isNegative);
  Expect.isTrue((-0.0).isFinite);

  Expect.isFalse(1.isNaN);
  Expect.isFalse(1.isInfinite);
  Expect.isTrue(1.isFinite);
  Expect.isFalse(1.isNegative);
  Expect.isTrue((-1).isNegative);

  // Test that predicates give the correct result.
  Expect.isTrue(double.nan.isNaN);
  Expect.isFalse(double.nan.isInfinite);
  Expect.isFalse(double.nan.isFinite);
  Expect.isFalse(double.nan.isNegative);
  Expect.isFalse((-double.nan).isNegative);

  Expect.isFalse(double.infinity.isNaN);
  Expect.isTrue(double.infinity.isInfinite);
  Expect.isFalse(double.infinity.isFinite);
  Expect.isFalse(double.infinity.isNegative);
  Expect.isTrue((-double.infinity).isNegative);

  Expect.isFalse(double.negativeInfinity.isNaN);
  Expect.isTrue(double.negativeInfinity.isInfinite);
  Expect.isFalse(double.negativeInfinity.isFinite);
  Expect.isTrue(double.negativeInfinity.isNegative);
  Expect.isFalse((-double.negativeInfinity).isNegative);

  // Test toString.
  Expect.equals("NaN", double.nan.toString());
  Expect.equals("Infinity", double.infinity.toString());
  Expect.equals("-Infinity", double.negativeInfinity.toString());

  // Test identities.
  Expect.isTrue(identical(double.nan, double.nan)); // //# 01: ok
  Expect.isTrue(identical(double.infinity, double.infinity));
  Expect.isTrue(identical(double.negativeInfinity, double.negativeInfinity));
  Expect.isFalse(identical(double.nan, double.infinity));
  Expect.isFalse(identical(double.nan, double.negativeInfinity));
  Expect.isFalse(identical(double.infinity, double.negativeInfinity));
  Expect.isFalse(identical(double.nan, -double.nan));
  Expect.isTrue(identical(double.infinity, -double.negativeInfinity));
  Expect.isTrue(identical(double.negativeInfinity, -double.infinity));

  // Test equalities
  Expect.isTrue(double.infinity == double.infinity);
  Expect.isTrue(double.negativeInfinity == double.negativeInfinity);
  Expect.isFalse(double.infinity == double.negativeInfinity);
  Expect.isFalse(double.negativeInfinity == double.infinity);
  Expect.isFalse(double.nan == double.nan);
  Expect.isFalse(double.nan == double.infinity);
  Expect.isFalse(double.nan == double.negativeInfinity);
  Expect.isFalse(double.infinity == double.nan);
  Expect.isFalse(double.negativeInfinity == double.nan);

  // Test relational order.
  Expect.isFalse(double.nan < double.nan);
  Expect.isFalse(double.nan < double.infinity);
  Expect.isFalse(double.nan < double.negativeInfinity);
  Expect.isFalse(double.nan > double.nan);
  Expect.isFalse(double.nan > double.infinity);
  Expect.isFalse(double.nan > double.negativeInfinity);
  Expect.isFalse(double.infinity < double.nan);
  Expect.isFalse(double.negativeInfinity < double.nan);
  Expect.isFalse(double.infinity > double.nan);
  Expect.isFalse(double.negativeInfinity > double.nan);
  Expect.isTrue(double.infinity > double.negativeInfinity);
  Expect.isFalse(double.infinity < double.negativeInfinity);

  // NaN is contagious.
  Expect.isTrue((3.0 * double.nan).isNaN);
  Expect.isTrue((3.0 + double.nan).isNaN);
  Expect.isTrue((-double.nan).isNaN);
}
