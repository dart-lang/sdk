// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// When attempting to call a nonexistent static method, getter or setter, check
// that a compile error is reported.

class C {}

class D {
  get hest => 1; //# 04: continued
  set hest(val) {} //# 05: continued
}

get fisk => 2; //# 09: continued
set fisk(val) {} //# 10: continued

main() {
  C.hest = 1; //# 01: compile-time error
  C.hest; //# 02: compile-time error
  C.hest(); //# 03: compile-time error

  D.hest = 1; //# 04: compile-time error
  D.hest; //# 05: compile-time error
  fisk = 1; //# 06: compile-time error
  fisk; //# 07: compile-time error
  fisk(); //# 08: compile-time error
  fisk = 1; //# 09: compile-time error
  fisk; //# 10: compile-time error
}
