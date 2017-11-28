// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0, 0.truncate());
  Expect.equals(1, 1.truncate());
  Expect.equals(0x1234, 0x1234.truncate());
  Expect.equals(0x12345678, 0x12345678.truncate());
  Expect.equals(0x123456789AB, 0x123456789AB.truncate());
  Expect.equals(0x123456789ABCDEF, 0x123456789ABCDEF.truncate());
  Expect.equals(-1, -1.truncate());
  Expect.equals(-0x1234, -0x1234.truncate());
  Expect.equals(-0x12345678, -0x12345678.truncate());
  Expect.equals(-0x123456789AB, -0x123456789AB.truncate());
  Expect.equals(-0x123456789ABCDEF, -0x123456789ABCDEF.truncate());

  Expect.isTrue(0.truncate() is int);
  Expect.isTrue(1.truncate() is int);
  Expect.isTrue(0x1234.truncate() is int);
  Expect.isTrue(0x12345678.truncate() is int);
  Expect.isTrue(0x123456789AB.truncate() is int);
  Expect.isTrue(0x123456789ABCDEF.truncate() is int);
  Expect.isTrue(-1.truncate() is int);
  Expect.isTrue(-0x1234.truncate() is int);
  Expect.isTrue(-0x12345678.truncate() is int);
  Expect.isTrue(-0x123456789AB.truncate() is int);
  Expect.isTrue(-0x123456789ABCDEF.truncate() is int);
}
