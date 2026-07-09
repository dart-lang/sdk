// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  const int big = 0x123456789AB0000 + 0xCDEF; // Slightly rounded on web.

  Expect.equals(0.0, 0.floorToDouble());
  Expect.equals(1.0, 1.floorToDouble());
  Expect.equals(0x1234, 0x1234.floorToDouble());
  Expect.equals(0x12345678, 0x12345678.floorToDouble());
  Expect.equals(0x123456789AB, 0x123456789AB.floorToDouble());
  Expect.equals(81985529216486900.0, big.floorToDouble());
  Expect.equals(-1.0, (-1).floorToDouble());
  Expect.equals(-0x1234, (-0x1234).floorToDouble());
  Expect.equals(-0x12345678, (-0x12345678).floorToDouble());
  Expect.equals(-0x123456789AB, (-0x123456789AB).floorToDouble());
  Expect.equals(-81985529216486900.0, (-big).floorToDouble());

  Expect.isTrue(0.floorToDouble() is double);
  Expect.isTrue(1.floorToDouble() is double);
  Expect.isTrue(0x1234.floorToDouble() is double);
  Expect.isTrue(0x12345678.floorToDouble() is double);
  Expect.isTrue(0x123456789AB.floorToDouble() is double);
  Expect.isTrue(big.floorToDouble() is double);
  Expect.isTrue((-1).floorToDouble() is double);
  Expect.isTrue((-0x1234).floorToDouble() is double);
  Expect.isTrue((-0x12345678).floorToDouble() is double);
  Expect.isTrue((-0x123456789AB).floorToDouble() is double);
  Expect.isTrue((-big).floorToDouble() is double);
}
