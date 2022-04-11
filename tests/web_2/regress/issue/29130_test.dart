// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// This is a regression test from issue #29310. The global type-inferrer does
/// tracing of closures including allocated classes that implement a `call`
/// method. We incorrectly considered also classes with invoked factory
/// constructors, even if those were only abstract interfaces or mixins that
/// weren't actually allocated explicitly.
library regression_29130;

main() {
  new B();
  new C();
}

class A {
  call() {}
}

// interface scenario: we shouldn't trace B
abstract class B implements A {
  factory B() => null;
}

// mixin scenario: we should trace C, but we should trace _C
abstract class C implements A {
  factory C() => new D();
}

class D = A with C;
