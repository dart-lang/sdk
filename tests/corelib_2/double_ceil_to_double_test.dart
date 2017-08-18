// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0.0, 0.0.ceilToDouble());
  Expect.equals(1.0, double.MIN_POSITIVE.ceilToDouble());
  Expect.equals(1.0, (2.0 * double.MIN_POSITIVE).ceilToDouble());
  Expect.equals(1.0, (1.18e-38).ceilToDouble());
  Expect.equals(1.0, (1.18e-38 * 2).ceilToDouble());
  Expect.equals(1.0, 0.49999999999999994.ceilToDouble());
  Expect.equals(1.0, 0.5.ceilToDouble());
  Expect.equals(1.0, 0.9999999999999999.ceilToDouble());
  Expect.equals(1.0, 1.0.ceilToDouble());
  Expect.equals(2.0, 1.000000000000001.ceilToDouble());
  // The following numbers are on the border of 52 bits.
  // For example: 4503599627370499 + 0.5 => 4503599627370500.
  Expect.equals(4503599627370496.0, 4503599627370496.0.ceilToDouble());
  Expect.equals(4503599627370497.0, 4503599627370497.0.ceilToDouble());
  Expect.equals(4503599627370498.0, 4503599627370498.0.ceilToDouble());
  Expect.equals(4503599627370499.0, 4503599627370499.0.ceilToDouble());

  Expect.equals(9007199254740991.0, 9007199254740991.0.ceilToDouble());
  Expect.equals(9007199254740992.0, 9007199254740992.0.ceilToDouble());
  Expect.equals(double.MAX_FINITE, double.MAX_FINITE.ceilToDouble());

  Expect.equals(0.0, (-double.MIN_POSITIVE).ceilToDouble());
  Expect.equals(0.0, (2.0 * -double.MIN_POSITIVE).ceilToDouble());
  Expect.equals(0.0, (-1.18e-38).ceilToDouble());
  Expect.equals(0.0, (-1.18e-38 * 2).ceilToDouble());
  Expect.equals(0.0, (-0.49999999999999994).ceilToDouble());
  Expect.equals(0.0, (-0.5).ceilToDouble());
  Expect.equals(0.0, (-0.9999999999999999).ceilToDouble());
  Expect.equals(-1.0, (-1.0).ceilToDouble());
  Expect.equals(-1.0, (-1.000000000000001).ceilToDouble());
  Expect.equals(-4503599627370496.0, (-4503599627370496.0).ceilToDouble());
  Expect.equals(-4503599627370497.0, (-4503599627370497.0).ceilToDouble());
  Expect.equals(-4503599627370498.0, (-4503599627370498.0).ceilToDouble());
  Expect.equals(-4503599627370499.0, (-4503599627370499.0).ceilToDouble());
  Expect.equals(-9007199254740991.0, (-9007199254740991.0).ceilToDouble());
  Expect.equals(-9007199254740992.0, (-9007199254740992.0).ceilToDouble());
  Expect.equals(-double.MAX_FINITE, (-double.MAX_FINITE).ceilToDouble());

  Expect.equals(double.INFINITY, double.INFINITY.ceilToDouble());
  Expect.equals(
      double.NEGATIVE_INFINITY, double.NEGATIVE_INFINITY.ceilToDouble());
  Expect.isTrue(double.NAN.ceilToDouble().isNaN);

  Expect.isTrue(0.0.ceilToDouble() is double);
  Expect.isTrue(double.MIN_POSITIVE.ceilToDouble() is double);
  Expect.isTrue((2.0 * double.MIN_POSITIVE).ceilToDouble() is double);
  Expect.isTrue((1.18e-38).ceilToDouble() is double);
  Expect.isTrue((1.18e-38 * 2).ceilToDouble() is double);
  Expect.isTrue(0.49999999999999994.ceilToDouble() is double);
  Expect.isTrue(0.5.ceilToDouble() is double);
  Expect.isTrue(0.9999999999999999.ceilToDouble() is double);
  Expect.isTrue(1.0.ceilToDouble() is double);
  Expect.isTrue(1.000000000000001.ceilToDouble() is double);
  Expect.isTrue(4503599627370496.0.ceilToDouble() is double);
  Expect.isTrue(4503599627370497.0.ceilToDouble() is double);
  Expect.isTrue(4503599627370498.0.ceilToDouble() is double);
  Expect.isTrue(4503599627370499.0.ceilToDouble() is double);
  Expect.isTrue(9007199254740991.0.ceilToDouble() is double);
  Expect.isTrue(9007199254740992.0.ceilToDouble() is double);
  Expect.isTrue(double.MAX_FINITE.ceilToDouble() is double);

  Expect.isTrue((-double.MIN_POSITIVE).ceilToDouble().isNegative);
  Expect.isTrue((2.0 * -double.MIN_POSITIVE).ceilToDouble().isNegative);
  Expect.isTrue((-1.18e-38).ceilToDouble().isNegative);
  Expect.isTrue((-1.18e-38 * 2).ceilToDouble().isNegative);
  Expect.isTrue((-0.49999999999999994).ceilToDouble().isNegative);
  Expect.isTrue((-0.5).ceilToDouble().isNegative);
  Expect.isTrue((-0.9999999999999999).ceilToDouble().isNegative);

  Expect.isTrue((-double.MIN_POSITIVE).ceilToDouble() is double);
  Expect.isTrue((2.0 * -double.MIN_POSITIVE).ceilToDouble() is double);
  Expect.isTrue((-1.18e-38).ceilToDouble() is double);
  Expect.isTrue((-1.18e-38 * 2).ceilToDouble() is double);
  Expect.isTrue((-0.49999999999999994).ceilToDouble() is double);
  Expect.isTrue((-0.5).ceilToDouble() is double);
  Expect.isTrue((-0.9999999999999999).ceilToDouble() is double);
  Expect.isTrue((-1.0).ceilToDouble() is double);
  Expect.isTrue((-1.000000000000001).ceilToDouble() is double);
  Expect.isTrue((-4503599627370496.0).ceilToDouble() is double);
  Expect.isTrue((-4503599627370497.0).ceilToDouble() is double);
  Expect.isTrue((-4503599627370498.0).ceilToDouble() is double);
  Expect.isTrue((-4503599627370499.0).ceilToDouble() is double);
  Expect.isTrue((-9007199254740991.0).ceilToDouble() is double);
  Expect.isTrue((-9007199254740992.0).ceilToDouble() is double);
  Expect.isTrue((-double.MAX_FINITE).ceilToDouble() is double);
}
