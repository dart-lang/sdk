// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0.0, 0.ceilToDouble());
  Expect.equals(1.0, 1.ceilToDouble());
  Expect.equals(0x1234, 0x1234.ceilToDouble());
  Expect.equals(0x12345678, 0x12345678.ceilToDouble());
  Expect.equals(0x123456789AB, 0x123456789AB.ceilToDouble());
  Expect.equals(81985529216486900.0, 0x123456789ABCDEF.ceilToDouble());
  Expect.equals(2.7898229935051914e+55,
      0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.ceilToDouble());
  Expect.equals(-1.0, -1.ceilToDouble());
  Expect.equals(-0x1234, -0x1234.ceilToDouble());
  Expect.equals(-0x12345678, -0x12345678.ceilToDouble());
  Expect.equals(-0x123456789AB, -0x123456789AB.ceilToDouble());
  Expect.equals(-81985529216486900.0, -0x123456789ABCDEF.ceilToDouble());
  Expect.equals(-2.7898229935051914e+55,
      -0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.ceilToDouble());

  Expect.isTrue(0.ceilToDouble() is double);
  Expect.isTrue(1.ceilToDouble() is double);
  Expect.isTrue(0x1234.ceilToDouble() is double);
  Expect.isTrue(0x12345678.ceilToDouble() is double);
  Expect.isTrue(0x123456789AB.ceilToDouble() is double);
  Expect.isTrue(0x123456789ABCDEF.ceilToDouble() is double);
  Expect.isTrue(0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.ceilToDouble()
      is double);
  Expect.isTrue(-1.ceilToDouble() is double);
  Expect.isTrue(-0x1234.ceilToDouble() is double);
  Expect.isTrue(-0x12345678.ceilToDouble() is double);
  Expect.isTrue(-0x123456789AB.ceilToDouble() is double);
  Expect.isTrue(-0x123456789ABCDEF.ceilToDouble() is double);
  Expect.isTrue(-0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF
      .ceilToDouble() is double);
}
