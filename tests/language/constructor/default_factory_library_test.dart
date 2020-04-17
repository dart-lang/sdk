// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing factories defined across libraries

library test;

import "package:expect/expect.dart";
import "default_factory_library.dart" as lib;

class B implements lib.A, C {
  int methodA() {
    return 1;
  }

  int methodB() {
    return 2;
  }
}

abstract class C implements lib.A {
  // Referenced from an abstract class in another library
  factory C.A() {
    return new B();
  }
}

main() {
  dynamic val = new lib.A();
  Expect.equals(true, (val is B));
  Expect.equals(1, val.methodA());
  Expect.equals(2, val.methodB());
}
