// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the individual variable declarations inside a variable
// declaration list are not allowed to be annotated with metadata.

const annotation = null;

var
  @annotation //# 01: compile-time error
    v1,
  @annotation //# 02: compile-time error
    v2;

int
  @annotation //# 03: compile-time error
    v3,
  @annotation //# 04: compile-time error
    v4;

class C {
  var
    @annotation //# 05: compile-time error
      f1,
    @annotation //# 06: compile-time error
      f2;

  int
    @annotation //# 07: compile-time error
      f3,
    @annotation //# 08: compile-time error
      f4;
}

use(x) => x;

main() {
  use(v1);
  use(v2);
  use(v3);
  use(v4);

  C c = new C();
  use(c.f1);
  use(c.f2);
  use(c.f3);
  use(c.f4);

  var
    @annotation //# 09: compile-time error
      l1,
    @annotation //# 10: compile-time error
      l2;

  int
    @annotation //# 11: compile-time error
      l3,
    @annotation //# 12: compile-time error
      l4;

  use(l1);
  use(l2);
  use(l3);
  use(l4);

  for (var
         @annotation //# 13: compile-time error
      i1 = 0,
         @annotation //# 14: compile-time error
      i2 = 0;;) {
    use(i1);
    use(i2);
    break;
  }

  for (int
         @annotation //# 15: compile-time error
      i3 = 0,
         @annotation //# 16: compile-time error
      i4 = 0;;) {
    use(i3);
    use(i4);
    break;
  }
}
