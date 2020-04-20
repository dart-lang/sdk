// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing that `noSuchMethod` appears to use implicit forwarders (we don't
// care how it's actually implemented, but it should look like that).

import 'package:expect/expect.dart';

// "Template" class: Something to emulate.
class A {
  int foo(String s) => s.length;
}

// Emulate `A`, but only dynamically.
class B {
  noSuchMethod(_) => 31;
}

// Emulate `A`, including its type.
class C implements A {
  noSuchMethod(_) => 41;
}

// Emulate `A` with its type, based on an inherited `noSuchMethod`.
class D extends B implements A {}

void test(A a, int expectedValue) {
  // Regular superinterfaces can be supported by `noSuchMethod`.
  Expect.equals(expectedValue, a.foo('Hello!')); //# 04: ok

  // `noSuchMethod` triggers generation of forwarders, so a statically
  // known instance method tear-off yields a `Function`, also when invoked
  // dynamically.
  Expect.isTrue(a.foo is Function); //# 05: ok
  Expect.isTrue((a as dynamic).foo is Function); //# 06: ok

  // For an unknown member name the invocation must be dynamic, and in that
  // case it does not match a forwarder, but we invoke `noSuchMethod`.
  Expect.equals(expectedValue, (a as dynamic).bar); //# 07: ok
}

main() {
  // Dynamic invocations can make a `B` seem to implement `A`.
  Expect.equals(31, (new B() as dynamic).foo('Hello!')); //# 01: ok

  // But `noSuchMethod` does not affect the type or interface of a class.
  A a; //# 02: continued
  Expect.throws(() => a = new B() as dynamic); //# 02: ok
  new B().foo('Hello!'); //# 03: compile-time error

  test(new C(), 41);
  test(new D(), 31);
}
