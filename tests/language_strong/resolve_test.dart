// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing resolving of dynamic and static calls.

import "package:expect/expect.dart";

class A {
  static staticCall() {
    return 4;
  }

  dynamicCall() {
    return 5;
  }

  ovrDynamicCall() {
    return 6;
  }
}

class B extends A {
  ovrDynamicCall() {
    return -6;
  }
}

class ResolveTest {
  static testMain() {
    var b = new B();
    Expect.equals(3, (b.dynamicCall() + A.staticCall() + b.ovrDynamicCall()));
  }
}

main() {
  ResolveTest.testMain();
}
