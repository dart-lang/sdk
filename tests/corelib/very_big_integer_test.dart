// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // x and y have lengths in 32-bit digits that overflow 16 bits.
  var x = new BigInt.from(13) << (65000 * 32);
  var y = new BigInt.from(42) << (65000 * 32);
  print(x.bitLength);
  Expect.equals(x, (x + y) - y);
  Expect.equals(x, -((-x + y) - y));
  Expect.equals(x, (x << 2) >> 2);
  Expect.equals(x, (x >> 3) << 3);
  Expect.equals(0, (x ^ x).toInt());
  Expect.equals(0, (y ^ y).toInt());
}
