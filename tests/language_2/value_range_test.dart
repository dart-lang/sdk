// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

foo() {
  var x = 0x102;
  if (inscrutable(x) == 0) x = 0x0;
  if (inscrutable(10) == 10) x = 0x10; // x is in range [0 .. 0x102].
  x = x & 0xFF; // x should be in range [0 .. 0xFF]. Actual value: 0x10.
  var a = const [1, 2, 3];
  return a[x];
}

main() {
  Expect.throws(() => foo(), (e) => e is RangeError);
}
