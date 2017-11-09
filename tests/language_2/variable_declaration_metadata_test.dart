// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the individual variable declarations inside a variable
// declaration list are not allowed to be annotated with metadata.

const annotation = null;

var
  @annotation //# 01: syntax error
    v1,
  @annotation //# 02: syntax error
    v2;

int
  @annotation //# 03: syntax error
    v3,
  @annotation //# 04: syntax error
    v4;

class C {
  var
    @annotation //# 05: syntax error
      f1,
    @annotation //# 06: syntax error
      f2;

  int
    @annotation //# 07: syntax error
      f3,
    @annotation //# 08: syntax error
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
    @annotation //# 09: syntax error
      l1,
    @annotation //# 10: syntax error
      l2;

  int
    @annotation //# 11: syntax error
      l3,
    @annotation //# 12: syntax error
      l4;

  use(l1);
  use(l2);
  use(l3);
  use(l4);

  for (var
         @annotation //# 13: syntax error
      i1 = 0,
         @annotation //# 14: syntax error
      i2 = 0;;) {
    use(i1);
    use(i2);
    break;
  }

  for (int
         @annotation //# 15: syntax error
      i3 = 0,
         @annotation //# 16: syntax error
      i4 = 0;;) {
    use(i3);
    use(i4);
    break;
  }
}
