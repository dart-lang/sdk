// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0.0, 0.0.roundToDouble());
  Expect.equals(0.0, double.MIN_POSITIVE.roundToDouble());
  Expect.equals(0.0, (2.0 * double.MIN_POSITIVE).roundToDouble());
  Expect.equals(0.0, (1.18e-38).roundToDouble());
  Expect.equals(0.0, (1.18e-38 * 2).roundToDouble());
  Expect.equals(1.0, 0.5.roundToDouble());
  Expect.equals(1.0, 0.9999999999999999.roundToDouble());
  Expect.equals(1.0, 1.0.roundToDouble());
  Expect.equals(1.0, 1.000000000000001.roundToDouble());
  Expect.equals(2.0, 1.5.roundToDouble());

  Expect.equals(double.MAX_FINITE, double.MAX_FINITE.roundToDouble());

  Expect.equals(0.0, (-double.MIN_POSITIVE).roundToDouble());
  Expect.equals(0.0, (2.0 * -double.MIN_POSITIVE).roundToDouble());
  Expect.equals(0.0, (-1.18e-38).roundToDouble());
  Expect.equals(0.0, (-1.18e-38 * 2).roundToDouble());
  Expect.equals(-1.0, (-0.5).roundToDouble());
  Expect.equals(-1.0, (-0.9999999999999999).roundToDouble());
  Expect.equals(-1.0, (-1.0).roundToDouble());
  Expect.equals(-1.0, (-1.000000000000001).roundToDouble());
  Expect.equals(-2.0, (-1.5).roundToDouble());
  Expect.equals(-double.MAX_FINITE, (-double.MAX_FINITE).roundToDouble());

  Expect.equals(double.INFINITY, double.INFINITY.roundToDouble());
  Expect.equals(
      double.NEGATIVE_INFINITY, double.NEGATIVE_INFINITY.roundToDouble());
  Expect.isTrue(double.NAN.roundToDouble().isNaN);

  Expect.isTrue(0.0.roundToDouble() is double);
  Expect.isTrue(double.MIN_POSITIVE.roundToDouble() is double);
  Expect.isTrue((2.0 * double.MIN_POSITIVE).roundToDouble() is double);
  Expect.isTrue((1.18e-38).roundToDouble() is double);
  Expect.isTrue((1.18e-38 * 2).roundToDouble() is double);
  Expect.isTrue(0.5.roundToDouble() is double);
  Expect.isTrue(0.9999999999999999.roundToDouble() is double);
  Expect.isTrue(1.0.roundToDouble() is double);
  Expect.isTrue(1.000000000000001.roundToDouble() is double);
  Expect.isTrue(double.MAX_FINITE.roundToDouble() is double);

  Expect.isTrue((-double.MIN_POSITIVE).roundToDouble().isNegative);
  Expect.isTrue((2.0 * -double.MIN_POSITIVE).roundToDouble().isNegative);
  Expect.isTrue((-1.18e-38).roundToDouble().isNegative);
  Expect.isTrue((-1.18e-38 * 2).roundToDouble().isNegative);

  Expect.isTrue((-double.MIN_POSITIVE).roundToDouble() is double);
  Expect.isTrue((2.0 * -double.MIN_POSITIVE).roundToDouble() is double);
  Expect.isTrue((-1.18e-38).roundToDouble() is double);
  Expect.isTrue((-1.18e-38 * 2).roundToDouble() is double);
  Expect.isTrue((-0.5).roundToDouble() is double);
  Expect.isTrue((-0.9999999999999999).roundToDouble() is double);
  Expect.isTrue((-1.0).roundToDouble() is double);
  Expect.isTrue((-1.000000000000001).roundToDouble() is double);
  Expect.isTrue((-double.MAX_FINITE).roundToDouble() is double);
}
