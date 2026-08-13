// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/53653.

abstract class A {
  @pragma("vm:entry-point")
  void foo();
  @pragma("vm:entry-point")
  get bar;
  @pragma("vm:entry-point")
  set bar(x);
}

class B extends A {
  foo() {
    print("A");
  }

  get bar {
    print("C");
  }

  set bar(x) {
    print("B");
  }
}

A a = B();

main() {
  a.foo();
  a.bar = a.bar;
}
