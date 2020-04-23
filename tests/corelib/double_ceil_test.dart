// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0, 0.0.ceil());
  Expect.equals(1, double.minPositive.ceil());
  Expect.equals(1, (2.0 * double.minPositive).ceil());
  Expect.equals(1, (1.18e-38).ceil());
  Expect.equals(1, (1.18e-38 * 2).ceil());
  Expect.equals(1, 0.49999999999999994.ceil());
  Expect.equals(1, 0.5.ceil());
  Expect.equals(1, 0.9999999999999999.ceil());
  Expect.equals(1, 1.0.ceil());
  Expect.equals(2, 1.000000000000001.ceil());
  // The following numbers are on the border of 52 bits.
  // For example: 4503599627370499 + 0.5 => 4503599627370500.
  Expect.equals(4503599627370496, 4503599627370496.0.ceil());
  Expect.equals(4503599627370497, 4503599627370497.0.ceil());
  Expect.equals(4503599627370498, 4503599627370498.0.ceil());
  Expect.equals(4503599627370499, 4503599627370499.0.ceil());

  Expect.equals(9007199254740991, 9007199254740991.0.ceil());
  Expect.equals(9007199254740992, 9007199254740992.0.ceil());
  Expect.equals(9223372036854775807, double.maxFinite.ceil()); // //# int64: ok

  Expect.equals(0, (-double.minPositive).ceil());
  Expect.equals(0, (2.0 * -double.minPositive).ceil());
  Expect.equals(0, (-1.18e-38).ceil());
  Expect.equals(0, (-1.18e-38 * 2).ceil());
  Expect.equals(0, (-0.49999999999999994).ceil());
  Expect.equals(0, (-0.5).ceil());
  Expect.equals(0, (-0.9999999999999999).ceil());
  Expect.equals(-1, (-1.0).ceil());
  Expect.equals(-1, (-1.000000000000001).ceil());
  Expect.equals(-4503599627370496, (-4503599627370496.0).ceil());
  Expect.equals(-4503599627370497, (-4503599627370497.0).ceil());
  Expect.equals(-4503599627370498, (-4503599627370498.0).ceil());
  Expect.equals(-4503599627370499, (-4503599627370499.0).ceil());
  Expect.equals(-9007199254740991, (-9007199254740991.0).ceil());
  Expect.equals(-9007199254740992, (-9007199254740992.0).ceil());
  Expect.equals(-9223372036854775808, (-double.maxFinite).ceil()); // //# int64: ok

  Expect.isTrue(0.0.ceil() is int);
  Expect.isTrue(double.minPositive.ceil() is int);
  Expect.isTrue((2.0 * double.minPositive).ceil() is int);
  Expect.isTrue((1.18e-38).ceil() is int);
  Expect.isTrue((1.18e-38 * 2).ceil() is int);
  Expect.isTrue(0.49999999999999994.ceil() is int);
  Expect.isTrue(0.5.ceil() is int);
  Expect.isTrue(0.9999999999999999.ceil() is int);
  Expect.isTrue(1.0.ceil() is int);
  Expect.isTrue(1.000000000000001.ceil() is int);
  Expect.isTrue(4503599627370496.0.ceil() is int);
  Expect.isTrue(4503599627370497.0.ceil() is int);
  Expect.isTrue(4503599627370498.0.ceil() is int);
  Expect.isTrue(4503599627370499.0.ceil() is int);
  Expect.isTrue(9007199254740991.0.ceil() is int);
  Expect.isTrue(9007199254740992.0.ceil() is int);
  Expect.isTrue(double.maxFinite.ceil() is int);

  Expect.isTrue((-double.minPositive).ceil() is int);
  Expect.isTrue((2.0 * -double.minPositive).ceil() is int);
  Expect.isTrue((-1.18e-38).ceil() is int);
  Expect.isTrue((-1.18e-38 * 2).ceil() is int);
  Expect.isTrue((-0.49999999999999994).ceil() is int);
  Expect.isTrue((-0.5).ceil() is int);
  Expect.isTrue((-0.9999999999999999).ceil() is int);
  Expect.isTrue((-1.0).ceil() is int);
  Expect.isTrue((-1.000000000000001).ceil() is int);
  Expect.isTrue((-4503599627370496.0).ceil() is int);
  Expect.isTrue((-4503599627370497.0).ceil() is int);
  Expect.isTrue((-4503599627370498.0).ceil() is int);
  Expect.isTrue((-4503599627370499.0).ceil() is int);
  Expect.isTrue((-9007199254740991.0).ceil() is int);
  Expect.isTrue((-9007199254740992.0).ceil() is int);
  Expect.isTrue((-double.maxFinite).ceil() is int);
}
