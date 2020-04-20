// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing implicit invocation of super constructor with all
// named parameters.

import "package:expect/expect.dart";

var res = 0;

class A {
  A([v = 1]) {
    res += v;
  }
}

class B extends A {
  B([v = 2]) {
    res += v;
  }
}

main() {
  new B();
  Expect.equals(3, res);
}
