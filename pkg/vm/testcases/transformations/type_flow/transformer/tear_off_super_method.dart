// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

A aa = new B();

dynamic knownResult() => new B();

abstract class A {
  int foo();
}

class B extends A {
  int foo() => 1 + knownResult().foo(); // Should have metadata.
}

class C implements A {
  int foo() => 2 + knownResult().foo(); // Should be unreachable.
}

class Base {
  int foo() => 3 + knownResult().foo(); // Should have metadata.
  int doCall(x) => x();
}

class TearOffSuperMethod extends Base {
  int foo() {
    // Should be unreachable.
    aa = new C();
    return 4 + knownResult().foo();
  }

  int bar() => doCall(super.foo);
}

main(List<String> args) {
  new TearOffSuperMethod().bar();

  aa.foo(); // Should be devirtualized.
}
