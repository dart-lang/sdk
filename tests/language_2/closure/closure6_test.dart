// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that captured final variables are correctly mangled.

class A {
  foo() {
    length() => 400;
    final box_0 = 28;
    var x = 29;
    var f = () => length() + box_0 + x + bar();
    return f();
  }

  bar() => 42;
}

main() {
  Expect.equals(499, new A().foo());
}
