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

class D {
  C1 c1 = new C1();
  dynamic d1 = new C1();
  C2 c2 = new C2();
  dynamic d2 = new C2();

  void test() {
    // Implicitly invokes c1.call(1)
    Expect.equals(c1(1), 2); //# 01: ok
    // Implicitly invokes d1.call(1)
    Expect.equals(d1(1), 2); //# 02: ok
    // Implicitly invokes c2.call(1)
    Expect.equals(c2(1), 2); //# 03: ok
    // Implicitly invokes d2.call(1)
    Expect.equals(d2(1), 2); //# 04: ok
  }
}

main() {
  new D().test();
  // Implicitly invokes D.c1.call(1)
  Expect.equals(new D().c1(1), 2); //# 05: ok
  // Implicitly invokes D.d1.call(1)
  Expect.equals(new D().d1(1), 2); //# 06: ok
  // Implicitly invokes D.c2.call(1)
  Expect.equals(new D().c2(1), 2); //# 07: ok
  // Implicitly invokes D.d2.call(1)
  Expect.equals(new D().d2(1), 2); //# 08: ok
  D d = new D();
  // Implicitly invokes d.c1.call(1)
  Expect.equals(d.c1(1), 2); //# 09: ok
  // Implicitly invokes d.d1.call(1)
  Expect.equals(d.d1(1), 2); //# 10: ok
  // Implicitly invokes d.c2.call(1)
  Expect.equals(d.c2(1), 2); //# 11: ok
  // Implicitly invokes d.d2.call(1)
  Expect.equals(d.d2(1), 2); //# 12: ok
}
