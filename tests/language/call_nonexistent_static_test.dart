// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// When attempting to call a nonexistent static method, getter or setter, check
// that a NoSuchMethodError is thrown.

class C {}

class D {
  get hest => 1; // //# 04: continued
  set hest(val) {} // //# 05: continued
}

get fisk => 2; //# 09: continued
set fisk(val) {} //# 10: continued

expectNsme([void fun()]) {
  if (fun != null) {
    Expect.throws(fun, (e) => e is NoSuchMethodError);
  }
}

alwaysThrows() {
  throw new NoSuchMethodError(null, const Symbol('foo'), [], {});
}

test01() {
  C.hest = 1; // //# 01: static type warning
}

test02() {
  C.hest; // //# 02: static type warning
}

test03() {
  C.hest(); // //# 03: static type warning
}

test04() {
  D.hest = 1; // //# 04: static type warning
}

test05() {
  D.hest; // //# 05: static type warning
}

test06() {
  fisk = 1; // //# 06: static type warning
}

test07() {
  fisk; // //# 07: static type warning
}

test08() {
  fisk(); // //# 08: static type warning
}

test09() {
  fisk = 1; // //# 09: static type warning
}

test10() {
  fisk; // //# 10: static type warning
}

main() {
  expectNsme(alwaysThrows);
  expectNsme(
    test01 // //# 01: continued
      );
  expectNsme(
    test02 // //# 02: continued
      );
  expectNsme(
    test03 // //# 03: continued
      );
  expectNsme(
    test04 // //# 04: continued
      );
  expectNsme(
    test05 // //# 05: continued
      );
  expectNsme(
    test06 // //# 06: continued
      );
  expectNsme(
    test07 // //# 07: continued
      );
  expectNsme(
    test08 // //# 08: continued
      );
  expectNsme(
    test09 // //# 09: continued
      );
  expectNsme(
    test10 // //# 10: continued
      );
}
