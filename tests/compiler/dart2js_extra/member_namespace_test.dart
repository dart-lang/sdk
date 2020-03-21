// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

class A {
  static int a;
  A();
  static foo() {
    // Make sure 'A' is not resolved to the constructor.
    return A.a;
  }
}

main() {
  A.a = 42;
  Expect.equals(42, A.foo());
}
