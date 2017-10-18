// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "regress_10996_lib.dart" as lib;

foo(a, [b]) {
  return a + b + lib.a + lib.b;
}

bar(c, {d}) {
  return c + d + lib.c + lib.d;
}

main() {
  Expect.equals(1 + 2 + 3 + 4, foo(1, 2));
  Expect.equals(7 + 8 + 3 + 4, foo(7, 8));
  Expect.equals(3 + 4 + 5 + 6, bar(3, d: 4));
  Expect.equals(7 + 8 + 5 + 6, bar(7, d: 8));
}
