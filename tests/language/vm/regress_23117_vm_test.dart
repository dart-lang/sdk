// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test location summary for Uint32 multiplication.
// VMOptions=--optimization-counter-threshold=5 --no-background-compilation

import 'package:expect/expect.dart';

mintLeftShift(x, y) => x << y;
mintRightShift(x, y) => x >> y;

main() {
  for (var i = 0; i < 20; i++) {
    var x = 1 + (1 << (i + 32));
    Expect.equals(x, mintLeftShift(x, 0));
    Expect.equals(x, mintRightShift(x, 0));
    Expect.equals(2 * x, mintLeftShift(x, 1));
    Expect.equals(x ~/ 2, mintRightShift(x, 1));
    Expect.equals((i >= 16) ? 1 : x, mintRightShift(mintLeftShift(x, i), i));
  }
}
