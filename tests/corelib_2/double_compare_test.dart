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
  Expect.equals(0, double.nan.compareTo(double.nan));
  Expect.equals(0, double.infinity.compareTo(double.infinity));
  Expect.equals(0, double.negativeInfinity.compareTo(double.negativeInfinity));
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
  Expect.isTrue(maxDouble.compareTo(double.infinity) < 0);
  Expect.isTrue(double.infinity.compareTo(maxDouble) > 0);

  double negMaxDouble = -maxDouble;
  Expect.equals(0, negMaxDouble.compareTo(negMaxDouble));
  Expect.isTrue(double.negativeInfinity.compareTo(negMaxDouble) < 0);
  Expect.isTrue(negMaxDouble.compareTo(double.negativeInfinity) > 0);

  Expect.isTrue((-0.0).compareTo(0.0) < 0);
  Expect.isTrue((0.0).compareTo(-0.0) > 0);
  Expect.isTrue(double.nan.compareTo(double.infinity) > 0);
  Expect.isTrue(double.nan.compareTo(double.negativeInfinity) > 0);
  Expect.isTrue(double.infinity.compareTo(double.nan) < 0);
  Expect.isTrue(double.negativeInfinity.compareTo(double.nan) < 0);
  Expect.isTrue(maxDouble.compareTo(double.nan) < 0);
  Expect.isTrue(negMaxDouble.compareTo(double.nan) < 0);
  Expect.isTrue(double.nan.compareTo(maxDouble) > 0);
  Expect.isTrue(double.nan.compareTo(negMaxDouble) > 0);
}
