// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0, 0.0.round());
  Expect.equals(0, double.minPositive.round());
  Expect.equals(0, (2.0 * double.minPositive).round());
  Expect.equals(0, (1.18e-38).round());
  Expect.equals(0, (1.18e-38 * 2).round());
  Expect.equals(1, 0.5.round());
  Expect.equals(1, 0.9999999999999999.round());
  Expect.equals(1, 1.0.round());
  Expect.equals(1, 1.000000000000001.round());
  Expect.equals(9223372036854775807, double.maxFinite.round()); // //# int64: ok

  Expect.equals(0, (-double.minPositive).round());
  Expect.equals(0, (2.0 * -double.minPositive).round());
  Expect.equals(0, (-1.18e-38).round());
  Expect.equals(0, (-1.18e-38 * 2).round());
  Expect.equals(-1, (-0.5).round());
  Expect.equals(-1, (-0.9999999999999999).round());
  Expect.equals(-1, (-1.0).round());
  Expect.equals(-1, (-1.000000000000001).round());
  Expect.equals(-9223372036854775808, (-double.maxFinite).round()); // //# int64: ok

  Expect.isTrue(0.0.round() is int);
  Expect.isTrue(double.minPositive.round() is int);
  Expect.isTrue((2.0 * double.minPositive).round() is int);
  Expect.isTrue((1.18e-38).round() is int);
  Expect.isTrue((1.18e-38 * 2).round() is int);
  Expect.isTrue(0.5.round() is int);
  Expect.isTrue(0.9999999999999999.round() is int);
  Expect.isTrue(1.0.round() is int);
  Expect.isTrue(1.000000000000001.round() is int);
  Expect.isTrue(double.maxFinite.round() is int);

  Expect.isTrue((-double.minPositive).round() is int);
  Expect.isTrue((2.0 * -double.minPositive).round() is int);
  Expect.isTrue((-1.18e-38).round() is int);
  Expect.isTrue((-1.18e-38 * 2).round() is int);
  Expect.isTrue((-0.5).round() is int);
  Expect.isTrue((-0.9999999999999999).round() is int);
  Expect.isTrue((-1.0).round() is int);
  Expect.isTrue((-1.000000000000001).round() is int);
  Expect.isTrue((-double.maxFinite).round() is int);
}
