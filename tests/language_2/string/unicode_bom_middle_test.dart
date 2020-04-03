// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

foo(x) {
  if (inscrutable(1999) == 1999) return x;
  return 499;
}

main() {
  Expect.equals(3, "x﻿x".length); // BOM character between the xs.
  Expect.equals(3, foo("x﻿x").length); // BOM character between the xs.
}
