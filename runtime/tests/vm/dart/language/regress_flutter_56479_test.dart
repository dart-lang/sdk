// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that optional parameters can be transformed in field initializers.
// Regression test for https://github.com/flutter/flutter/issues/56479.

import "package:expect/expect.dart";

int bar({int x = 2}) => x + 1;

class A {
  static int foo = bar(x: 42);
}

main() {
  Expect.equals(5, bar(x: 4));
  Expect.equals(43, A.foo);
}
