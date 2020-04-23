// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  const int big = 0x123456789AB0000 + 0xCDEF; // Slightly rounded on web.

  Expect.equals(0.0, 0.truncateToDouble());
  Expect.equals(1.0, 1.truncateToDouble());
  Expect.equals(0x1234, 0x1234.truncateToDouble());
  Expect.equals(0x12345678, 0x12345678.truncateToDouble());
  Expect.equals(0x123456789AB, 0x123456789AB.truncateToDouble());
  Expect.equals(81985529216486900.0, big.truncateToDouble());
  Expect.equals(-1.0, (-1).truncateToDouble());
  Expect.equals(-0x1234, (-0x1234).truncateToDouble());
  Expect.equals(-0x12345678, (-0x12345678).truncateToDouble());
  Expect.equals(-0x123456789AB, (-0x123456789AB).truncateToDouble());
  Expect.equals(-81985529216486900.0, (-big).truncateToDouble());

  Expect.isTrue(0.truncateToDouble() is double);
  Expect.isTrue(1.truncateToDouble() is double);
  Expect.isTrue(0x1234.truncateToDouble() is double);
  Expect.isTrue(0x12345678.truncateToDouble() is double);
  Expect.isTrue(0x123456789AB.truncateToDouble() is double);
  Expect.isTrue(big.truncateToDouble() is double);
  Expect.isTrue((-1).truncateToDouble() is double);
  Expect.isTrue((-0x1234).truncateToDouble() is double);
  Expect.isTrue((-0x12345678).truncateToDouble() is double);
  Expect.isTrue((-0x123456789AB).truncateToDouble() is double);
  Expect.isTrue((-big).truncateToDouble() is double);
}
