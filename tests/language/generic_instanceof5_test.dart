// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that instanceof works correctly with type variables.

import "package:expect/expect.dart";

class A {}

class B<T, S> {}

class C<U, V> extends A with B<V, U> {}

class D<T> {
  foo(x) {
    // Avoid inlining.
    if (new DateTime.now().millisecondsSinceEpoch == 42) foo(x);
    return x is T;
    return true; // Avoid inlining.
  }
}

main() {
  Expect.isTrue(new D<B<int, bool>>().foo(new C<bool, int>()));
}
