// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

A aa = new B();

dynamic knownResult() => new B();

abstract class A {
  int foo();
}

class B extends A {
  int foo() => 1 + knownResult().bar(); // Should have metadata.
  int bar() => 3;
}

class C implements A {
  int foo() => 2 + knownResult().bar(); // Should be unreachable.
}

class TearOffInterfaceMethod {
  dynamic bazz;
  TearOffInterfaceMethod(A arg) : bazz = arg.foo;
}

main(List<String> args) {
  new TearOffInterfaceMethod(new B()).bazz();
}
