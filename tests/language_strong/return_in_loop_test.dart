// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test for a dart2js bug where the live environment was not computed
// right.

import "package:expect/expect.dart";

class A {
  foo() {
    var x = 0;
    while (true) {
      if (true) {
        return 42;
      } else {}
      x = bar();
    }
  }

  bar() => 1;
}

main() {
  Expect.equals(42, new A().foo());
}
