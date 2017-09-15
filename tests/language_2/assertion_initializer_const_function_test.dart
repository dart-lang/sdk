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
  // The expression *is* compile-time constant, but not a bool value.
  // Static warning, runtime always fails assertion.
  const C.bc01(this.x, y)
      : assert(staticTrue)  //# 01: compile-time error
      ;
}

main() {
  bool checkedMode = false;
  assert(checkedMode = true);
  if (checkedMode) {                                              //# 01: continued
    Expect.throws(() => new C.bc01(1, 2), (e) => e is TypeError); //# 01: continued
  } else {                                                        //# 01: continued
    Expect.equals(1, new C.bc01(1, 2).x);
  }                                                               //# 01: continued
}
