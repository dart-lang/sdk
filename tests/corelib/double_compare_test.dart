// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for testing 'compare' on doubles.

void main() {
  Expect.equals(0, (0.0).compareTo(0.0));
  Expect.equals(0, (1.0).compareTo(1.0));
  Expect.equals(0, (-2.0).compareTo(-2.0));
  Expect.equals(0, (1e-50).compareTo(1e-50));
  Expect.equals(0, (-2e50).compareTo(-2e50));
  Expect.equals(0, double.NAN.compareTo(double.NAN));
  Expect.equals(0, double.INFINITY.compareTo(double.INFINITY));
  Expect.equals(
      0, double.NEGATIVE_INFINITY.compareTo(double.NEGATIVE_INFINITY));
  Expect.equals(0, (-0.0).compareTo(-0.0));
  Expect.isTrue((0.0).compareTo(1.0) < 0);
  Expect.isTrue((1.0).compareTo(0.0) > 0);
  Expect.isTrue((0.0).compareTo(-1.0) > 0);
  Expect.isTrue((-1.0).compareTo(0.0) < 0);
  Expect.isTrue((0.0).compareTo(1234e11) < 0);
  Expect.isTrue((123e-112).compareTo(0.0) > 0);
  Expect.isTrue((0.0).compareTo(-123.0e12) > 0);
  Expect.isTrue((-1.0e8).compareTo(0.0) < 0);

  double maxDouble = 1.7976931348623157e308;
  Expect.equals(0, maxDouble.compareTo(maxDouble));
  Expect.isTrue(maxDouble.compareTo(double.INFINITY) < 0);
  Expect.isTrue(double.INFINITY.compareTo(maxDouble) > 0);

  double negMaxDouble = -maxDouble;
  Expect.equals(0, negMaxDouble.compareTo(negMaxDouble));
  Expect.isTrue(double.NEGATIVE_INFINITY.compareTo(negMaxDouble) < 0);
  Expect.isTrue(negMaxDouble.compareTo(double.NEGATIVE_INFINITY) > 0);

  Expect.isTrue((-0.0).compareTo(0.0) < 0);
  Expect.isTrue((0.0).compareTo(-0.0) > 0);
  Expect.isTrue(double.NAN.compareTo(double.INFINITY) > 0);
  Expect.isTrue(double.NAN.compareTo(double.NEGATIVE_INFINITY) > 0);
  Expect.isTrue(double.INFINITY.compareTo(double.NAN) < 0);
  Expect.isTrue(double.NEGATIVE_INFINITY.compareTo(double.NAN) < 0);
  Expect.isTrue(maxDouble.compareTo(double.NAN) < 0);
  Expect.isTrue(negMaxDouble.compareTo(double.NAN) < 0);
  Expect.isTrue(double.NAN.compareTo(maxDouble) > 0);
  Expect.isTrue(double.NAN.compareTo(negMaxDouble) > 0);
}
