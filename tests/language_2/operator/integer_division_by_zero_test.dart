// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test integer division by zero.
// Test that results before and after optimization are the same.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

// @dart = 2.9

import "package:expect/expect.dart";

num divBy(num a, num b) => a ~/ b;

main() {
  // Dividing integers by zero is an error.
  Expect.throws<Error>(() => divBy(1, 0));
  Expect.throws<Error>(() => divBy(0, 0));

  // Dividing doubles by zero is an error (result is never finite).
  Expect.throws<Error>(() => divBy(1.0, 0));
  Expect.throws<Error>(() => divBy(1, 0.0));
  Expect.throws<Error>(() => divBy(1, -0.0));
  Expect.throws<Error>(() => divBy(1.0, 0.0));
  // Double division yielding infinity is an error, even when not dividing
  // by zero.
  Expect.throws<Error>(() => divBy(double.maxFinite, 0.5));
  Expect.throws<Error>(() => divBy(1, double.minPositive));
  Expect.throws<Error>(() => divBy(double.infinity, 2.0));
  Expect.throws<Error>(() => divBy(-double.maxFinite, 0.5));
  Expect.throws<Error>(() => divBy(-1, double.minPositive));
  Expect.throws<Error>(() => divBy(-double.infinity, 2.0));
  // Double division yielding NaN is an error.
  Expect.throws<Error>(() => divBy(0.0, 0.0));
  Expect.throws<Error>(() => divBy(double.infinity, double.infinity));
  Expect.throws<Error>(() => divBy(-0.0, 0.0));
  Expect.throws<Error>(() => divBy(-double.infinity, double.infinity));

  // Truncating division containing a double truncates to max integer
  // on non-web.
  num one = 1;
  if (one is! double) {
    var minInt = -0x8000000000000000;
    var maxInt = minInt - 1;
    Expect.isTrue(maxInt > 0);
    // Not on web.
    Expect.equals(divBy(double.maxFinite, 2), maxInt);
    Expect.equals(divBy(-double.maxFinite, 2), minInt);
    Expect.equals(divBy(maxInt, 0.25), maxInt);
    Expect.equals(divBy(minInt, 0.25), minInt);
  }
}
