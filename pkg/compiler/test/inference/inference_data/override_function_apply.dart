// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that closure tracing is done for overrides of vitual calls. The
// receiver of the `foo` tear-off is [subtype=A] so inference uses a virtual
// target on `A.foo`. There have to be enough subtypes of A to ensure the
// receiver is not a UnionTypeMask.

abstract class A {
  int foo();
}

class B implements A {
  @override
  /*member: B.foo:apply*/
  int foo() => 1;
}

class C implements A {
  @override
  /*member: C.foo:apply*/
  int foo() => 2;
}

class D implements A {
  @override
  /*member: D.foo:apply*/
  int foo() => 3;
}

class E implements A {
  @override
  /*member: E.foo:apply*/
  int foo() => 4;
}

class F implements A {
  @override
  /*member: F.foo:apply*/
  int foo() => 5;
}

dynamic confuse(x) => x;
main() {
  final A a = confuse(true)
      ? (confuse(true) ? (confuse(true) ? B() : C()) : D())
      : (confuse(true) ? E() : F());
  Function.apply(a.foo, []);
}
