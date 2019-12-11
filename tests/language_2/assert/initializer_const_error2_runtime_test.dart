// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable-asserts
// dart2jsOptions=--enable-asserts
//
// Test of asserts in initializer lists.

import "package:expect/expect.dart";

class C {
  final int x;
  // Const constructors.
  const C.cc01(this.x, y) : assert(x < y);
  const C.cc02(x, y)
      : x = x,
        assert(x < y);
  const C.cc03(x, y)
      : assert(x < y),
        x = x;
  const C.cc04(this.x, y)
      : assert(x < y),
        super();
  const C.cc05(x, y)
      : x = x,
        assert(x < y),
        super();
  const C.cc06(x, y)
      : assert(x < y),
        x = x,
        super();
  const C.cc07(x, y)
      : assert(x < y),
        x = x,
        assert(y > x),
        super();
  const C.cc08(this.x, y) : assert(x < y, "$x < $y");
  const C.cc09(this.x, y) : assert(x < y,);
  const C.cc10(this.x, y) : assert(x < y, "$x < $y",);
}

main() {
  const x = 3;
  {

    const C.cc01(2, x);
  }
  {

    const C.cc02(2, x);
  }
  {

    const C.cc03(2, x);
  }
  {

    const C.cc04(2, x);
  }
  {

    const C.cc05(2, x);
  }
  {

    const C.cc06(2, x);
  }
  {

    const C.cc07(2, x);
  }
  {

    const C.cc08(2, x);
  }
  {

    const C.cc09(2, x);
  }
  {

    const C.cc10(2, x);
  }
}
