// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A();
  const factory A.B() = B;
  const factory A.C() = C;
  const factory A.C2() = D;
}

class B implements A {
  const B();

  operator ==(o) => true; // //# 00: compile-time error
}

class C implements A {
  final int x;
  const C() : x = 0;
  const C.fromD() : x = 1;
}

class D implements C {
  int get x => 0;
  const factory D() = C.fromD;
}

main() {
  switch (new B()) { 
    case const A.B(): Expect.fail("bad switch"); break; // //# 00: continued
  }

  switch (new C()) {
    case const C():
      Expect.fail("bad switch");
      break;
    case const A.C():
      Expect.fail("bad switch");
      break;
    case const A.C2():
      Expect.fail("bad switch");
      break;
    case const A(): Expect.fail("bad switch"); break; // //# 01: compile-time error
  }

  switch (new A()) {
    case const A():
      Expect.fail("bad switch");
      break;
    case const A.B(): Expect.fail("bad switch"); break; // //# 02: compile-time error
  }
}
