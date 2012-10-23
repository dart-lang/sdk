// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing NaN and Infinity.

void main() {
  Expect.isTrue(double.NAN.isNaN);
  Expect.isFalse(double.NAN.isInfinite);
  Expect.isFalse(double.INFINITY.isNaN);
  Expect.isTrue(double.INFINITY.isInfinite);
  Expect.isFalse(double.NEGATIVE_INFINITY.isNaN);
  Expect.isTrue(double.NEGATIVE_INFINITY.isInfinite);
  Expect.equals("NaN", double.NAN.toString());
  Expect.equals("Infinity", double.INFINITY.toString());
  Expect.equals("-Infinity", double.NEGATIVE_INFINITY.toString());
  Expect.isFalse(double.NAN == double.NAN);
  Expect.isTrue(double.INFINITY == double.INFINITY);
  Expect.isTrue(double.NEGATIVE_INFINITY == double.NEGATIVE_INFINITY);
  Expect.isFalse(double.NAN < double.NAN);
  Expect.isFalse(double.NAN < double.INFINITY);
  Expect.isFalse(double.NAN < double.NEGATIVE_INFINITY);
  Expect.isFalse(double.NAN > double.NAN);
  Expect.isFalse(double.NAN > double.INFINITY);
  Expect.isFalse(double.NAN > double.NEGATIVE_INFINITY);
  Expect.isFalse(double.NAN == double.NAN);
  Expect.isFalse(double.NAN == double.INFINITY);
  Expect.isFalse(double.NAN == double.NEGATIVE_INFINITY);
  Expect.isFalse(double.INFINITY < double.NAN);
  Expect.isFalse(double.NEGATIVE_INFINITY < double.NAN);
  Expect.isFalse(double.INFINITY > double.NAN);
  Expect.isFalse(double.NEGATIVE_INFINITY > double.NAN);
  Expect.isFalse(double.INFINITY == double.NAN);
  Expect.isFalse(double.NEGATIVE_INFINITY == double.NAN);
  Expect.isTrue((3.0 * double.NAN).isNaN);
  Expect.isTrue(double.INFINITY > double.NEGATIVE_INFINITY);
}
