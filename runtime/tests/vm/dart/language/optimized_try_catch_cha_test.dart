// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=100 --no-use-osr --no-background_compilation

// Test CHA-based optimizations in presence of try-catch.

import "package:expect/expect.dart";

bar(i) {
  if (i == 11) throw 123;
}

class A {
  var f = 42;

  foo(i) {
    do {
      try {
        bar(i);
      } catch (e, s) {
        Expect.equals(123, e);
      }
    } while (i < 0);
    return f;
  }
}

class B extends A {}

main() {
  var result;
  for (var i = 0; i < 200; i++) {
    try {
      result = new B().foo(i);
    } catch (e) {}
  }
  Expect.equals(42, result);
}
