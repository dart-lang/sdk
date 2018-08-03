// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0.0, 0.0.floorToDouble());
  Expect.equals(0.0, double.minPositive.floorToDouble());
  Expect.equals(0.0, (2.0 * double.minPositive).floorToDouble());
  Expect.equals(0.0, (1.18e-38).floorToDouble());
  Expect.equals(0.0, (1.18e-38 * 2).floorToDouble());
  Expect.equals(0.0, 0.49999999999999994.floorToDouble());
  Expect.equals(0.0, 0.5.floorToDouble());
  Expect.equals(0.0, 0.9999999999999999.floorToDouble());
  Expect.equals(1.0, 1.0.floorToDouble());
  Expect.equals(1.0, 1.000000000000001.floorToDouble());
  // The following numbers are on the border of 52 bits.
  // For example: 4503599627370499 + 0.5 => 4503599627370500.
  Expect.equals(4503599627370496.0, 4503599627370496.0.floorToDouble());
  Expect.equals(4503599627370497.0, 4503599627370497.0.floorToDouble());
  Expect.equals(4503599627370498.0, 4503599627370498.0.floorToDouble());
  Expect.equals(4503599627370499.0, 4503599627370499.0.floorToDouble());

  Expect.equals(9007199254740991.0, 9007199254740991.0.floorToDouble());
  Expect.equals(9007199254740992.0, 9007199254740992.0.floorToDouble());
  Expect.equals(double.maxFinite, double.maxFinite.floorToDouble());

  Expect.equals(-1.0, (-double.minPositive).floorToDouble());
  Expect.equals(-1.0, (2.0 * -double.minPositive).floorToDouble());
  Expect.equals(-1.0, (-1.18e-38).floorToDouble());
  Expect.equals(-1.0, (-1.18e-38 * 2).floorToDouble());
  Expect.equals(-1.0, (-0.49999999999999994).floorToDouble());
  Expect.equals(-1.0, (-0.5).floorToDouble());
  Expect.equals(-1.0, (-0.9999999999999999).floorToDouble());
  Expect.equals(-1.0, (-1.0).floorToDouble());
  Expect.equals(-2.0, (-1.000000000000001).floorToDouble());
  Expect.equals(-4503599627370496.0, (-4503599627370496.0).floorToDouble());
  Expect.equals(-4503599627370497.0, (-4503599627370497.0).floorToDouble());
  Expect.equals(-4503599627370498.0, (-4503599627370498.0).floorToDouble());
  Expect.equals(-4503599627370499.0, (-4503599627370499.0).floorToDouble());
  Expect.equals(-9007199254740991.0, (-9007199254740991.0).floorToDouble());
  Expect.equals(-9007199254740992.0, (-9007199254740992.0).floorToDouble());
  Expect.equals(-double.maxFinite, (-double.maxFinite).floorToDouble());

  Expect.equals(double.infinity, double.infinity.floorToDouble());
  Expect.equals(
      double.negativeInfinity, double.negativeInfinity.floorToDouble());
  Expect.isTrue(double.nan.floorToDouble().isNaN);

  Expect.isTrue(0.0.floorToDouble() is double);
  Expect.isTrue(double.minPositive.floorToDouble() is double);
  Expect.isTrue((2.0 * double.minPositive).floorToDouble() is double);
  Expect.isTrue((1.18e-38).floorToDouble() is double);
  Expect.isTrue((1.18e-38 * 2).floorToDouble() is double);
  Expect.isTrue(0.49999999999999994.floorToDouble() is double);
  Expect.isTrue(0.5.floorToDouble() is double);
  Expect.isTrue(0.9999999999999999.floorToDouble() is double);
  Expect.isTrue(1.0.floorToDouble() is double);
  Expect.isTrue(1.000000000000001.floorToDouble() is double);
  Expect.isTrue(4503599627370496.0.floorToDouble() is double);
  Expect.isTrue(4503599627370497.0.floorToDouble() is double);
  Expect.isTrue(4503599627370498.0.floorToDouble() is double);
  Expect.isTrue(4503599627370499.0.floorToDouble() is double);
  Expect.isTrue(9007199254740991.0.floorToDouble() is double);
  Expect.isTrue(9007199254740992.0.floorToDouble() is double);
  Expect.isTrue(double.maxFinite.floorToDouble() is double);

  Expect.isTrue((-double.minPositive).floorToDouble() is double);
  Expect.isTrue((2.0 * -double.minPositive).floorToDouble() is double);
  Expect.isTrue((-1.18e-38).floorToDouble() is double);
  Expect.isTrue((-1.18e-38 * 2).floorToDouble() is double);
  Expect.isTrue((-0.49999999999999994).floorToDouble() is double);
  Expect.isTrue((-0.5).floorToDouble() is double);
  Expect.isTrue((-0.9999999999999999).floorToDouble() is double);
  Expect.isTrue((-1.0).floorToDouble() is double);
  Expect.isTrue((-1.000000000000001).floorToDouble() is double);
  Expect.isTrue((-4503599627370496.0).floorToDouble() is double);
  Expect.isTrue((-4503599627370497.0).floorToDouble() is double);
  Expect.isTrue((-4503599627370498.0).floorToDouble() is double);
  Expect.isTrue((-4503599627370499.0).floorToDouble() is double);
  Expect.isTrue((-9007199254740991.0).floorToDouble() is double);
  Expect.isTrue((-9007199254740992.0).floorToDouble() is double);
  Expect.isTrue((-double.maxFinite).floorToDouble() is double);
}
