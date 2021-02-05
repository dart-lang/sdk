// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test to ensure that we can use type variable in factories.

import "package:expect/expect.dart";

class A<T> {
  factory A.foo(o) {
    Expect.isTrue(o is A<T>);
    return new A();
  }
  A();
}

main() => new A<int>.foo(new A<int>());
