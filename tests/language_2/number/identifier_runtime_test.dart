// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Integer literals.
  Expect.isTrue(2 is int);
  Expect.equals(2, 2 as int);
  Expect.isTrue(-2 is int);
  Expect.equals(-2, -2 as int);
  Expect.isTrue(0x10 is int);
  Expect.isTrue(-0x10 is int);
  // "a" will be part of hex literal, the following "s" is an error.



  // Double literals.
  Expect.isTrue(2.0 is double);
  Expect.equals(2.0, 2.0 as double);
  Expect.isTrue(-2.0 is double);
  Expect.equals(-2.0, -2.0 as double);
  Expect.isTrue(.2 is double);
  Expect.equals(0.2, .2 as double);
  Expect.isTrue(1e2 is double);
  Expect.equals(1e2, 1e2 as double);
  Expect.isTrue(1e-2 is double);
  Expect.equals(1e-2, 1e-2 as double);
  Expect.isTrue(1e+2 is double);
  Expect.equals(1e+2, 1e+2 as double);









}
