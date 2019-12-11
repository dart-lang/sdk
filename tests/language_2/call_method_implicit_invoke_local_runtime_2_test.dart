// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

import "package:expect/expect.dart";

class C1 {
  int call(int i) => 2 * i;
}

class C2 implements Function {
  int call(int i) => 2 * i;
}

main() {
  C1 c1 = new C1();
  // Implicitly invokes c1.call(1)

  dynamic d1 = c1;
  // Implicitly invokes d1.call(1)
  Expect.equals(d1(1), 2);
  C2 c2 = new C2();
  // Implicitly invokes c2.call(1)

  dynamic d2 = c2;
  // Implicitly invokes d2.call(1)

  // Cannot invoke with the wrong signature.


}
