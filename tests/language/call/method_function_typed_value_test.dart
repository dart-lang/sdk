// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

import "package:expect/expect.dart";

int f(int i) => 2 * i;

typedef int IntToInt(int x);

main() {
  // It is possible to use `.call` on a function-typed value (even though it is
  // redundant).  Similarly, it is possible to tear off `.call` on a
  // function-typed value (but it is a no-op).
  Expect.equals(f.call(1), 2); //# 01: ok
  Expect.identical(f.call, f); //# 02: ok
  IntToInt f2 = f;
  Expect.equals(f2.call(1), 2); //# 03: ok
  Expect.identical(f2.call, f); //# 04: ok
  Function f3 = f;
  Expect.equals(f3.call(1), 2); //# 05: ok
  Expect.identical(f3.call, f); //# 06: ok
  dynamic d = f;
  Expect.equals(d.call(1), 2); //# 07: ok
  Expect.identical(d.call, f); //# 08: ok
}
