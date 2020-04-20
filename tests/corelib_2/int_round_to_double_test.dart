// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  const int big = 0x123456789AB0000 + 0xCDEF; // Slightly rounded on web.

  Expect.equals(0.0, 0.roundToDouble());
  Expect.equals(1.0, 1.roundToDouble());
  Expect.equals(0x1234, 0x1234.roundToDouble());
  Expect.equals(0x12345678, 0x12345678.roundToDouble());
  Expect.equals(0x123456789AB, 0x123456789AB.roundToDouble());
  Expect.equals(81985529216486900.0, big.roundToDouble());
  Expect.equals(-1.0, (-1).roundToDouble());
  Expect.equals(-0x1234, (-0x1234).roundToDouble());
  Expect.equals(-0x12345678, (-0x12345678).roundToDouble());
  Expect.equals(-0x123456789AB, (-0x123456789AB).roundToDouble());
  Expect.equals(-81985529216486900.0, (-big).roundToDouble());

  Expect.isTrue(0.roundToDouble() is double);
  Expect.isTrue(1.roundToDouble() is double);
  Expect.isTrue(0x1234.roundToDouble() is double);
  Expect.isTrue(0x12345678.roundToDouble() is double);
  Expect.isTrue(0x123456789AB.roundToDouble() is double);
  Expect.isTrue(big.roundToDouble() is double);
  Expect.isTrue((-1).roundToDouble() is double);
  Expect.isTrue((-0x1234).roundToDouble() is double);
  Expect.isTrue((-0x12345678).roundToDouble() is double);
  Expect.isTrue((-0x123456789AB).roundToDouble() is double);
  Expect.isTrue((-big).roundToDouble() is double);
}
