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

  // `1.e`, etc. are parsed as a property / method access on int.
  Expect.equals(3, 1.e+2);
  Expect.equals(3, 1.d+2);
  Expect.equals(3, 1.D+2);
  Expect.equals(3, 1._0e+2);
}

extension on int {
  int get e => this;
  int get d => this;
  int get D => this;

  int get _0e => this;
}
