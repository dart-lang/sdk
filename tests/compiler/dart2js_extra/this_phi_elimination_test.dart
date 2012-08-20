// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  foo(a) {
    while (false) {
      // This call will make the builder want to put [this] as a phi.
      foo(0);
    }
    // This computation makes sure there will be a bailout version.
    return a + 42;
  }
}

main() {
  Expect.equals(42, new A().foo(0));
  Expect.throws(() => new A().foo(""), (e) => e is NoSuchMethodException);
}
