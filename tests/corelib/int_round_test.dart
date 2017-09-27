// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0, 0.round());
  Expect.equals(1, 1.round());
  Expect.equals(0x1234, 0x1234.round());
  Expect.equals(0x12345678, 0x12345678.round());
  Expect.equals(0x123456789AB, 0x123456789AB.round());
  Expect.equals(0x123456789ABCDEF, 0x123456789ABCDEF.round());
  Expect.equals(0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF,
      0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.round());
  Expect.equals(-1, -1.round());
  Expect.equals(-0x1234, -0x1234.round());
  Expect.equals(-0x12345678, -0x12345678.round());
  Expect.equals(-0x123456789AB, -0x123456789AB.round());
  Expect.equals(-0x123456789ABCDEF, -0x123456789ABCDEF.round());
  Expect.equals(-0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF,
      -0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.round());

  Expect.isTrue(0.round() is int);
  Expect.isTrue(1.round() is int);
  Expect.isTrue(0x1234.round() is int);
  Expect.isTrue(0x12345678.round() is int);
  Expect.isTrue(0x123456789AB.round() is int);
  Expect.isTrue(0x123456789ABCDEF.round() is int);
  Expect
      .isTrue(0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.round() is int);
  Expect.isTrue(-1.round() is int);
  Expect.isTrue(-0x1234.round() is int);
  Expect.isTrue(-0x12345678.round() is int);
  Expect.isTrue(-0x123456789AB.round() is int);
  Expect.isTrue(-0x123456789ABCDEF.round() is int);
  Expect.isTrue(
      -0x123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.round() is int);
}
