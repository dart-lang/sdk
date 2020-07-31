// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

// Make sure we use JavaScript semantics when compiling compile-time constants.

const x = 1234567890123456789;
const y = 1234567890123456788;
const z = x - y;

const a = 1.0;
const b = a << 3; // //# 01: compile-time error

const c = -0.0;
const d = c << 1; // //# 02: compile-time error

foo() => 12345678901234567891 - 12345678901234567890;

main() {
  Expect.equals(0, z);
  Expect.equals(0, x - y);
  Expect.equals(0, foo());
  Expect.isTrue(x is double);
  Expect.isTrue(x is int);
  Expect.equals(8, b); // //# 01: continued
  Expect.equals(8, 1.0 << 3); // //# 03: static type warning
  Expect.isTrue(1 == 1.0);
  Expect.equals(0, d); // //# 02: continued
  Expect.equals(0, -0.0 << 1); // //# 04: static type warning
  // Make sure the 1 is not shifted into the 32 bit range.
  Expect.equals(0, 0x100000000 >> 3);
  // The dynamic int-check also allows -0.0.
  Expect.isTrue((-0.0) is int);
}
