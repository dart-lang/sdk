// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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


}

class C implements D {
  final int x;
  const C() : x = 0;
  const C.fromD() : x = 1;
}

class D implements A {
  int get x => 0;
  const factory D() = C.fromD;
}

main() {
  switch (new B()) {

  }

  switch (new C()) {
    case const C():
      Expect.fail("bad switch");
      break;
    case const A.C() as C:
      Expect.fail("bad switch");
      break;
    case const A.C2() as C:
      Expect.fail("bad switch");
      break;

  }

  switch (new A()) {
    case const A():
      Expect.fail("bad switch");
      break;

  }
}
