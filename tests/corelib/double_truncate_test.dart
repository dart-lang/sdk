// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:expect/variations.dart' as v;

main() {
  Expect.equals(0, 0.0.truncate());
  Expect.equals(0, double.minPositive.truncate());
  Expect.equals(0, (2.0 * double.minPositive).truncate());
  Expect.equals(0, (1.18e-38).truncate());
  Expect.equals(0, (1.18e-38 * 2).truncate());
  Expect.equals(0, 0.49999999999999994.truncate());
  Expect.equals(0, 0.5.truncate());
  Expect.equals(0, 0.9999999999999999.truncate());
  Expect.equals(1, 1.0.truncate());
  Expect.equals(1, 1.000000000000001.truncate());
  // The following numbers are on the border of 52 bits.
  // For example: 4503599627370499 + 0.5 => 4503599627370500.
  Expect.equals(4503599627370496, 4503599627370496.0.truncate());
  Expect.equals(4503599627370497, 4503599627370497.0.truncate());
  Expect.equals(4503599627370498, 4503599627370498.0.truncate());
  Expect.equals(4503599627370499, 4503599627370499.0.truncate());

  Expect.equals(9007199254740991, 9007199254740991.0.truncate());
  Expect.equals(9007199254740992, 9007199254740992.0.truncate());
  if (v.jsNumbers) {
    Expect.equals(1.7976931348623157e+308, double.maxFinite.truncate());
  } else {
    // Split 0x7fffffffffffffff into sum of two web numbers to avoid compilation
    // error.
    Expect.equals(0x7ffffffffffff000 + 0xfff, double.maxFinite.truncate());
  }
  Expect.equals(0, (-double.minPositive).truncate());
  Expect.equals(0, (2.0 * -double.minPositive).truncate());
  Expect.equals(0, (-1.18e-38).truncate());
  Expect.equals(0, (-1.18e-38 * 2).truncate());
  Expect.equals(0, (-0.49999999999999994).truncate());
  Expect.equals(0, (-0.5).truncate());
  Expect.equals(0, (-0.9999999999999999).truncate());
  Expect.equals(-1, (-1.0).truncate());
  Expect.equals(-1, (-1.000000000000001).truncate());
  Expect.equals(-4503599627370496, (-4503599627370496.0).truncate());
  Expect.equals(-4503599627370497, (-4503599627370497.0).truncate());
  Expect.equals(-4503599627370498, (-4503599627370498.0).truncate());
  Expect.equals(-4503599627370499, (-4503599627370499.0).truncate());
  Expect.equals(-9007199254740991, (-9007199254740991.0).truncate());
  Expect.equals(-9007199254740992, (-9007199254740992.0).truncate());
  if (v.jsNumbers) {
    Expect.equals(-1.7976931348623157e+308, (-double.maxFinite).truncate());
  } else {
    Expect.equals(-9223372036854775808, (-double.maxFinite).truncate());
  }
  Expect.isTrue(0.0.truncate() is int);
  Expect.isTrue(double.minPositive.truncate() is int);
  Expect.isTrue((2.0 * double.minPositive).truncate() is int);
  Expect.isTrue((1.18e-38).truncate() is int);
  Expect.isTrue((1.18e-38 * 2).truncate() is int);
  Expect.isTrue(0.49999999999999994.truncate() is int);
  Expect.isTrue(0.5.truncate() is int);
  Expect.isTrue(0.9999999999999999.truncate() is int);
  Expect.isTrue(1.0.truncate() is int);
  Expect.isTrue(1.000000000000001.truncate() is int);
  Expect.isTrue(4503599627370496.0.truncate() is int);
  Expect.isTrue(4503599627370497.0.truncate() is int);
  Expect.isTrue(4503599627370498.0.truncate() is int);
  Expect.isTrue(4503599627370499.0.truncate() is int);
  Expect.isTrue(9007199254740991.0.truncate() is int);
  Expect.isTrue(9007199254740992.0.truncate() is int);
  Expect.isTrue(double.maxFinite.truncate() is int);

  Expect.isTrue((-double.minPositive).truncateToDouble().isNegative);
  Expect.isTrue((2.0 * -double.minPositive).truncateToDouble().isNegative);
  Expect.isTrue((-1.18e-38).truncateToDouble().isNegative);
  Expect.isTrue((-1.18e-38 * 2).truncateToDouble().isNegative);
  Expect.isTrue((-0.49999999999999994).truncateToDouble().isNegative);
  Expect.isTrue((-0.5).truncateToDouble().isNegative);
  Expect.isTrue((-0.9999999999999999).truncateToDouble().isNegative);

  Expect.isTrue((-double.minPositive).truncate() is int);
  Expect.isTrue((2.0 * -double.minPositive).truncate() is int);
  Expect.isTrue((-1.18e-38).truncate() is int);
  Expect.isTrue((-1.18e-38 * 2).truncate() is int);
  Expect.isTrue((-0.49999999999999994).truncate() is int);
  Expect.isTrue((-0.5).truncate() is int);
  Expect.isTrue((-0.9999999999999999).truncate() is int);
  Expect.isTrue((-1.0).truncate() is int);
  Expect.isTrue((-1.000000000000001).truncate() is int);
  Expect.isTrue((-4503599627370496.0).truncate() is int);
  Expect.isTrue((-4503599627370497.0).truncate() is int);
  Expect.isTrue((-4503599627370498.0).truncate() is int);
  Expect.isTrue((-4503599627370499.0).truncate() is int);
  Expect.isTrue((-9007199254740991.0).truncate() is int);
  Expect.isTrue((-9007199254740992.0).truncate() is int);
  Expect.isTrue((-double.maxFinite).truncate() is int);
}
