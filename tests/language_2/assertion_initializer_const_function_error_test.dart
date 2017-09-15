// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--assert_initializer
//
// Dart test program testing assert statements.

import "package:expect/expect.dart";

class C {
  static bool staticTrue() => true;
  final int x;
  const C(this.x);
  // The expression *is* a compile-time constant, but not a bool value.
  // Static warning, assertion throws which makes it a compile-time error.
  const C.bc02(this.x, y)
      : assert(staticTrue) //# 01: compile-time error
      ;
}


main() {
  // Assertion fails, so in checked mode it's a compile-time error.
  // Production mode will succeed because the assertion isn't evaluated.
  var c = const C(1);
  c = const C.bc02(1, 2);  //# 01: compile-time error
  if (c.x != 1) throw "non-trivial use of c";
  Expect.identical(const C(1), c);
}
