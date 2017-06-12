// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

foo() {
  int x = 0;
  if (inscrutable(0) == 0) x = -2; // x is now in range [-2 .. 0].
  int y = 2;
  if (inscrutable(0) == 0) y = 4; // y is now in range [2 .. 4].
  int i = y - x; // i should be in range [2 .. 6].
  i -= 4; // i should be in range [-2 .. 2]. Actual value: 2.
  var a = const [1];
  return a[i];
}

main() {
  Expect.throws(() => foo(), (e) => e is RangeError);
}
