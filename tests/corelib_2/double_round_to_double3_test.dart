// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  // The following numbers are on the border of 52 bits.
  // For example: 4503599627370499 + 0.5 => 4503599627370500.
  Expect.equals(4503599627370496.0, 4503599627370496.0.roundToDouble());
  Expect.equals(4503599627370497.0, 4503599627370497.0.roundToDouble());
  Expect.equals(4503599627370498.0, 4503599627370498.0.roundToDouble());
  Expect.equals(4503599627370499.0, 4503599627370499.0.roundToDouble());
  Expect.equals(9007199254740991.0, 9007199254740991.0.roundToDouble());
  Expect.equals(9007199254740992.0, 9007199254740992.0.roundToDouble());
  Expect.equals(-4503599627370496.0, (-4503599627370496.0).roundToDouble());
  Expect.equals(-4503599627370497.0, (-4503599627370497.0).roundToDouble());
  Expect.equals(-4503599627370498.0, (-4503599627370498.0).roundToDouble());
  Expect.equals(-4503599627370499.0, (-4503599627370499.0).roundToDouble());
  Expect.equals(-9007199254740991.0, (-9007199254740991.0).roundToDouble());
  Expect.equals(-9007199254740992.0, (-9007199254740992.0).roundToDouble());
  Expect.isTrue(4503599627370496.0.roundToDouble() is double);
  Expect.isTrue(4503599627370497.0.roundToDouble() is double);
  Expect.isTrue(4503599627370498.0.roundToDouble() is double);
  Expect.isTrue(4503599627370499.0.roundToDouble() is double);
  Expect.isTrue(9007199254740991.0.roundToDouble() is double);
  Expect.isTrue(9007199254740992.0.roundToDouble() is double);
  Expect.isTrue((-4503599627370496.0).roundToDouble() is double);
  Expect.isTrue((-4503599627370497.0).roundToDouble() is double);
  Expect.isTrue((-4503599627370498.0).roundToDouble() is double);
  Expect.isTrue((-4503599627370499.0).roundToDouble() is double);
  Expect.isTrue((-9007199254740991.0).roundToDouble() is double);
  Expect.isTrue((-9007199254740992.0).roundToDouble() is double);
}
