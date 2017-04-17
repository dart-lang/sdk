// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests that methods with names "get", "set" and "operator" don't
// cause fatal problems.

// With return type.
class A {
  int get() {
    return 1;
  }

  int set() {
    return 2;
  }

  int operator() {
    return 3;
  }

  int factory() {
    return 4;
  }
}

// Without return types.
class B {
  get() {
    return 1;
  }

  set() {
    return 2;
  }

  operator() {
    return 3;
  }

  factory() {
    return 4;
  }
}

main() {
  {
    A a = new A();
    Expect.equals(1, a.get());
    Expect.equals(2, a.set());
    Expect.equals(3, a.operator());
    Expect.equals(4, a.factory());
  }
  {
    B b = new B();
    Expect.equals(1, b.get());
    Expect.equals(2, b.set());
    Expect.equals(3, b.operator());
    Expect.equals(4, b.factory());
  }
}
