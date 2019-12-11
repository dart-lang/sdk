// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Getters and setters can have different types, but it is a warning if the
// two types are not assignable.

import "package:expect/expect.dart";

int bar = 499;


get foo => bar;

void set foo(

    str) {
  bar = str.length;
}

main() {
  int x = foo;
  Expect.equals(499, x);
  foo = "1234";
  int y = foo;
  Expect.equals(4, y);
}
