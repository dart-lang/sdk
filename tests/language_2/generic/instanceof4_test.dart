// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that instanceof works correctly with type variables.

import "package:expect/expect.dart";

class A<T> {
  foo(x) {
    // Don't inline.
    if (new DateTime.now().millisecondsSinceEpoch == 42) return foo(x);
    return x is T;
  }
}

class BB {}

class B<T> implements BB {
  foo() {
    // Don't inline.
    if (new DateTime.now().millisecondsSinceEpoch == 42) return foo();
    return new A<T>().foo(new B());
  }
}

main() {
  Expect.isTrue(new B<BB>().foo());
}
