// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0, 0.floor());
  Expect.equals(1, 1.floor());
  Expect.equals(0x1234, 0x1234.floor());
  Expect.equals(0x12345678, 0x12345678.floor());
  Expect.equals(0x123456789AB, 0x123456789AB.floor());
  Expect.equals(0x123456789ABCDEF, 0x123456789ABCDEF.floor());
  Expect.equals(0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF,
      0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.floor());
  Expect.equals(-1, -1.floor());
  Expect.equals(-0x1234, -0x1234.floor());
  Expect.equals(-0x12345678, -0x12345678.floor());
  Expect.equals(-0x123456789AB, -0x123456789AB.floor());
  Expect.equals(-0x123456789ABCDEF, -0x123456789ABCDEF.floor());
  Expect.equals(-0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF,
      -0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.floor());

  Expect.isTrue(0.floor() is int);
  Expect.isTrue(1.floor() is int);
  Expect.isTrue(0x1234.floor() is int);
  Expect.isTrue(0x12345678.floor() is int);
  Expect.isTrue(0x123456789AB.floor() is int);
  Expect.isTrue(0x123456789ABCDEF.floor() is int);
  Expect
      .isTrue(0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.floor() is int);
  Expect.isTrue(-1.floor() is int);
  Expect.isTrue(-0x1234.floor() is int);
  Expect.isTrue(-0x12345678.floor() is int);
  Expect.isTrue(-0x123456789AB.floor() is int);
  Expect.isTrue(-0x123456789ABCDEF.floor() is int);
  Expect.isTrue(
      -0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.floor() is int);
}
