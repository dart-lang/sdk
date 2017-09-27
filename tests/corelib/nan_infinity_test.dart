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
  Expect.isTrue(double.NAN.isNaN);
  Expect.isFalse(double.NAN.isInfinite);
  Expect.isFalse(double.NAN.isFinite);
  Expect.isFalse(double.NAN.isNegative);
  Expect.isFalse((-double.NAN).isNegative);

  Expect.isFalse(double.INFINITY.isNaN);
  Expect.isTrue(double.INFINITY.isInfinite);
  Expect.isFalse(double.INFINITY.isFinite);
  Expect.isFalse(double.INFINITY.isNegative);
  Expect.isTrue((-double.INFINITY).isNegative);

  Expect.isFalse(double.NEGATIVE_INFINITY.isNaN);
  Expect.isTrue(double.NEGATIVE_INFINITY.isInfinite);
  Expect.isFalse(double.NEGATIVE_INFINITY.isFinite);
  Expect.isTrue(double.NEGATIVE_INFINITY.isNegative);
  Expect.isFalse((-double.NEGATIVE_INFINITY).isNegative);

  // Test toString.
  Expect.equals("NaN", double.NAN.toString());
  Expect.equals("Infinity", double.INFINITY.toString());
  Expect.equals("-Infinity", double.NEGATIVE_INFINITY.toString());

  // Test identities.
  Expect.isTrue(identical(double.NAN, double.NAN)); // //# 01: ok
  Expect.isTrue(identical(double.INFINITY, double.INFINITY));
  Expect.isTrue(identical(double.NEGATIVE_INFINITY, double.NEGATIVE_INFINITY));
  Expect.isFalse(identical(double.NAN, double.INFINITY));
  Expect.isFalse(identical(double.NAN, double.NEGATIVE_INFINITY));
  Expect.isFalse(identical(double.INFINITY, double.NEGATIVE_INFINITY));
  Expect.isFalse(identical(double.NAN, -double.NAN));
  Expect.isTrue(identical(double.INFINITY, -double.NEGATIVE_INFINITY));
  Expect.isTrue(identical(double.NEGATIVE_INFINITY, -double.INFINITY));

  // Test equalities
  Expect.isTrue(double.INFINITY == double.INFINITY);
  Expect.isTrue(double.NEGATIVE_INFINITY == double.NEGATIVE_INFINITY);
  Expect.isFalse(double.INFINITY == double.NEGATIVE_INFINITY);
  Expect.isFalse(double.NEGATIVE_INFINITY == double.INFINITY);
  Expect.isFalse(double.NAN == double.NAN);
  Expect.isFalse(double.NAN == double.INFINITY);
  Expect.isFalse(double.NAN == double.NEGATIVE_INFINITY);
  Expect.isFalse(double.INFINITY == double.NAN);
  Expect.isFalse(double.NEGATIVE_INFINITY == double.NAN);

  // Test relational order.
  Expect.isFalse(double.NAN < double.NAN);
  Expect.isFalse(double.NAN < double.INFINITY);
  Expect.isFalse(double.NAN < double.NEGATIVE_INFINITY);
  Expect.isFalse(double.NAN > double.NAN);
  Expect.isFalse(double.NAN > double.INFINITY);
  Expect.isFalse(double.NAN > double.NEGATIVE_INFINITY);
  Expect.isFalse(double.INFINITY < double.NAN);
  Expect.isFalse(double.NEGATIVE_INFINITY < double.NAN);
  Expect.isFalse(double.INFINITY > double.NAN);
  Expect.isFalse(double.NEGATIVE_INFINITY > double.NAN);
  Expect.isTrue(double.INFINITY > double.NEGATIVE_INFINITY);
  Expect.isFalse(double.INFINITY < double.NEGATIVE_INFINITY);

  // NaN is contagious.
  Expect.isTrue((3.0 * double.NAN).isNaN);
  Expect.isTrue((3.0 + double.NAN).isNaN);
  Expect.isTrue((-double.NAN).isNaN);
}
