// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  const int big = 0x123456789AB0000 + 0xCDEF; // Slightly rounded on web.

  Expect.equals(0.0, 0.ceilToDouble());
  Expect.equals(1.0, 1.ceilToDouble());
  Expect.equals(0x1234, 0x1234.ceilToDouble());
  Expect.equals(0x12345678, 0x12345678.ceilToDouble());
  Expect.equals(0x123456789AB, 0x123456789AB.ceilToDouble());
  Expect.equals(81985529216486900.0, big.ceilToDouble());
  Expect.equals(-1.0, (-1).ceilToDouble());
  Expect.equals(-0x1234, (-0x1234).ceilToDouble());
  Expect.equals(-0x12345678, (-0x12345678).ceilToDouble());
  Expect.equals(-0x123456789AB, (-0x123456789AB).ceilToDouble());
  Expect.equals(-81985529216486900.0, (-big).ceilToDouble());

  Expect.isTrue(0.ceilToDouble() is double);
  Expect.isTrue(1.ceilToDouble() is double);
  Expect.isTrue(0x1234.ceilToDouble() is double);
  Expect.isTrue(0x12345678.ceilToDouble() is double);
  Expect.isTrue(0x123456789AB.ceilToDouble() is double);
  Expect.isTrue(big.ceilToDouble() is double);
  Expect.isTrue((-1).ceilToDouble() is double);
  Expect.isTrue((-0x1234).ceilToDouble() is double);
  Expect.isTrue((-0x12345678).ceilToDouble() is double);
  Expect.isTrue((-0x123456789AB).ceilToDouble() is double);
  Expect.isTrue((-big).ceilToDouble() is double);
}
