// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
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

class TearOffDynamicMethod {
  dynamic bazz;
  TearOffDynamicMethod(dynamic arg) : bazz = arg.foo {
    bazz();
  }
}

main(List<String> args) {
  Function closure = () => new B();
  new TearOffDynamicMethod(closure.call());
}
