// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--intrinsify
// VMOptions=--no_intrinsify

import 'package:expect/expect.dart';

main() {
  for (int x in [0, 1, 0xffff, 0xffffffff, 0x111111111111, 0xffffffffffff]) {
    test(x);
    test(-x);
  }

  // Test with ints outside the 53-bit range that are known to have an
  // exact double representation.
  test(9007199254840856);
  test(144115188075954880);
  test(936748722493162112);
}

test(int x) {
  Expect.equals(x, x.toDouble().toInt(), "bad test argument ($x)");
  Expect.equals(x.hashCode, x.toDouble().hashCode);
}
