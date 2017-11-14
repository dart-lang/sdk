// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0, 0.0.floor());
  Expect.equals(0, double.MIN_POSITIVE.floor());
  Expect.equals(0, (2.0 * double.MIN_POSITIVE).floor());
  Expect.equals(0, (1.18e-38).floor());
  Expect.equals(0, (1.18e-38 * 2).floor());
  Expect.equals(0, 0.49999999999999994.floor());
  Expect.equals(0, 0.5.floor());
  Expect.equals(0, 0.9999999999999999.floor());
  Expect.equals(1, 1.0.floor());
  Expect.equals(1, 1.000000000000001.floor());
  // The following numbers are on the border of 52 bits.
  // For example: 4503599627370499 + 0.5 => 4503599627370500.
  Expect.equals(4503599627370496, 4503599627370496.0.floor());
  Expect.equals(4503599627370497, 4503599627370497.0.floor());
  Expect.equals(4503599627370498, 4503599627370498.0.floor());
  Expect.equals(4503599627370499, 4503599627370499.0.floor());

  Expect.equals(9007199254740991, 9007199254740991.0.floor());
  Expect.equals(9007199254740992, 9007199254740992.0.floor());
  Expect.equals(
      179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368,
      double.MAX_FINITE.floor());

  Expect.equals(-1, (-double.MIN_POSITIVE).floor());
  Expect.equals(-1, (2.0 * -double.MIN_POSITIVE).floor());
  Expect.equals(-1, (-1.18e-38).floor());
  Expect.equals(-1, (-1.18e-38 * 2).floor());
  Expect.equals(-1, (-0.49999999999999994).floor());
  Expect.equals(-1, (-0.5).floor());
  Expect.equals(-1, (-0.9999999999999999).floor());
  Expect.equals(-1, (-1.0).floor());
  Expect.equals(-2, (-1.000000000000001).floor());
  Expect.equals(-4503599627370496, (-4503599627370496.0).floor());
  Expect.equals(-4503599627370497, (-4503599627370497.0).floor());
  Expect.equals(-4503599627370498, (-4503599627370498.0).floor());
  Expect.equals(-4503599627370499, (-4503599627370499.0).floor());
  Expect.equals(-9007199254740991, (-9007199254740991.0).floor());
  Expect.equals(-9007199254740992, (-9007199254740992.0).floor());
  Expect.equals(
      -179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368,
      (-double.MAX_FINITE).floor());

  Expect.isTrue(0.0.floor() is int);
  Expect.isTrue(double.MIN_POSITIVE.floor() is int);
  Expect.isTrue((2.0 * double.MIN_POSITIVE).floor() is int);
  Expect.isTrue((1.18e-38).floor() is int);
  Expect.isTrue((1.18e-38 * 2).floor() is int);
  Expect.isTrue(0.49999999999999994.floor() is int);
  Expect.isTrue(0.5.floor() is int);
  Expect.isTrue(0.9999999999999999.floor() is int);
  Expect.isTrue(1.0.floor() is int);
  Expect.isTrue(1.000000000000001.floor() is int);
  Expect.isTrue(4503599627370496.0.floor() is int);
  Expect.isTrue(4503599627370497.0.floor() is int);
  Expect.isTrue(4503599627370498.0.floor() is int);
  Expect.isTrue(4503599627370499.0.floor() is int);
  Expect.isTrue(9007199254740991.0.floor() is int);
  Expect.isTrue(9007199254740992.0.floor() is int);
  Expect.isTrue(double.MAX_FINITE.floor() is int);

  Expect.isTrue((-double.MIN_POSITIVE).floor() is int);
  Expect.isTrue((2.0 * -double.MIN_POSITIVE).floor() is int);
  Expect.isTrue((-1.18e-38).floor() is int);
  Expect.isTrue((-1.18e-38 * 2).floor() is int);
  Expect.isTrue((-0.49999999999999994).floor() is int);
  Expect.isTrue((-0.5).floor() is int);
  Expect.isTrue((-0.9999999999999999).floor() is int);
  Expect.isTrue((-1.0).floor() is int);
  Expect.isTrue((-1.000000000000001).floor() is int);
  Expect.isTrue((-4503599627370496.0).floor() is int);
  Expect.isTrue((-4503599627370497.0).floor() is int);
  Expect.isTrue((-4503599627370498.0).floor() is int);
  Expect.isTrue((-4503599627370499.0).floor() is int);
  Expect.isTrue((-9007199254740991.0).floor() is int);
  Expect.isTrue((-9007199254740992.0).floor() is int);
  Expect.isTrue((-double.MAX_FINITE).floor() is int);
}
