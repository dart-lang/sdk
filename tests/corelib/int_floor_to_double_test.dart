// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0.0, 0.floorToDouble());
  Expect.equals(1.0, 1.floorToDouble());
  Expect.equals(0x1234, 0x1234.floorToDouble());
  Expect.equals(0x12345678, 0x12345678.floorToDouble());
  Expect.equals(0x123456789AB, 0x123456789AB.floorToDouble());
  Expect.equals(81985529216486900.0, 0x123456789ABCDEF.floorToDouble());
  Expect.equals(2.7898229935051914e+55,
      0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.floorToDouble());
  Expect.equals(-1.0, -1.floorToDouble());
  Expect.equals(-0x1234, -0x1234.floorToDouble());
  Expect.equals(-0x12345678, -0x12345678.floorToDouble());
  Expect.equals(-0x123456789AB, -0x123456789AB.floorToDouble());
  Expect.equals(-81985529216486900.0, -0x123456789ABCDEF.floorToDouble());
  Expect.equals(-2.7898229935051914e+55,
      -0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.floorToDouble());

  Expect.isTrue(0.floorToDouble() is double);
  Expect.isTrue(1.floorToDouble() is double);
  Expect.isTrue(0x1234.floorToDouble() is double);
  Expect.isTrue(0x12345678.floorToDouble() is double);
  Expect.isTrue(0x123456789AB.floorToDouble() is double);
  Expect.isTrue(0x123456789ABCDEF.floorToDouble() is double);
  Expect.isTrue(0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF
      .floorToDouble() is double);
  Expect.isTrue(-1.floorToDouble() is double);
  Expect.isTrue(-0x1234.floorToDouble() is double);
  Expect.isTrue(-0x12345678.floorToDouble() is double);
  Expect.isTrue(-0x123456789AB.floorToDouble() is double);
  Expect.isTrue(-0x123456789ABCDEF.floorToDouble() is double);
  Expect.isTrue(-0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF
      .floorToDouble() is double);
}
