// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// On frogsh constant folded hex literals of large magnitude were truncated on
// constant folding - Issue 636 is 'fixed', remaining concerns at Issue 638.

highDigitTruncationTest() {
  Expect.equals(0x12345678A, 0x123456789 + 1);

  // in 32 bits this is 0xF0000000 which is negative.
  Expect.isTrue(0x1f0000000 > 0);

  Expect.equals(0xf0, 0xf * 16);
  Expect.equals(0xff0, 0xff * 16);
  Expect.equals(0xfff0, 0xfff * 16);
  Expect.equals(0xffff0, 0xffff * 16);
  Expect.equals(0xfffff0, 0xfffff * 16);
  Expect.equals(0xffffff0, 0xffffff * 16);
  Expect.equals(0xfffffff0, 0xfffffff * 16);
  Expect.equals(0xffffffff0, 0xffffffff * 16);
  Expect.equals(0xfffffffff0, 0xfffffffff * 16);
  Expect.equals(0xffffffffff0, 0xffffffffff * 16);
}

main() {
  highDigitTruncationTest();
}
