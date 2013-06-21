// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that noSuchMethod dispatching and auto-closurization work correctly.

class A {
  noSuchMethod(m) {
    return 123;
  }
}

class B extends A { }

main() {
  var b = new B();
  for (var i = 0; i < 5000; ++i) Expect.equals(123, b.foo());
  Expect.throws(() => (b.foo)());
  Expect.equals("123", (b.foo).toString());
}

