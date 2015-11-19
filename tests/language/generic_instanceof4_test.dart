// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that instanceof works correctly with type variables.

import "package:expect/expect.dart";

class A<T> {
  @NoInline()
  foo(x) {
    return x is T;
  }
}

class BB {}

class B<T> implements BB {
  @NoInline()
  foo() {
    return new A<T>().foo(new B());
  }
}

main() {
  Expect.isTrue(new B<BB>().foo());
}
