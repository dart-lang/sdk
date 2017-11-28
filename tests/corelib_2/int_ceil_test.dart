// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0, 0.ceil());
  Expect.equals(1, 1.ceil());
  Expect.equals(0x1234, 0x1234.ceil());
  Expect.equals(0x12345678, 0x12345678.ceil());
  Expect.equals(0x123456789AB, 0x123456789AB.ceil());
  Expect.equals(0x123456789ABCDEF, 0x123456789ABCDEF.ceil());
  Expect.equals(-1, -1.ceil());
  Expect.equals(-0x1234, -0x1234.ceil());
  Expect.equals(-0x12345678, -0x12345678.ceil());
  Expect.equals(-0x123456789AB, -0x123456789AB.ceil());
  Expect.equals(-0x123456789ABCDEF, -0x123456789ABCDEF.ceil());

  Expect.isTrue(0.ceil() is int);
  Expect.isTrue(1.ceil() is int);
  Expect.isTrue(0x1234.ceil() is int);
  Expect.isTrue(0x12345678.ceil() is int);
  Expect.isTrue(0x123456789AB.ceil() is int);
  Expect.isTrue(0x123456789ABCDEF.ceil() is int);
  Expect.isTrue(-1.ceil() is int);
  Expect.isTrue(-0x1234.ceil() is int);
  Expect.isTrue(-0x12345678.ceil() is int);
  Expect.isTrue(-0x123456789AB.ceil() is int);
  Expect.isTrue(-0x123456789ABCDEF.ceil() is int);
}
