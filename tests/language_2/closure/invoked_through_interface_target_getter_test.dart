// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: this test expects a compile error (getter overrides a method), but it
// contains more code than necessary to provoke the compile error.  The reason
// for the extra code is to document the complications that would arise if we
// decided to eliminate the compile error (and allow getters to override
// methods).

import "package:expect/expect.dart";

typedef void F<T>(T t);

class A {
  void foo(Object n);
}

class C implements A {
  F<Object> get /*@compile-error=unspecified*/ foo => bar(new D<int>());
}

class D<T> {
  void m(T t) {}
}

F<Object> bar(D<int> d) => d.m;
void baz(A a) {
  Expect.throws(() {
    // This call looks like it doesn't require any runtime type checking, since
    // it is a call to a regular method with no covariant parameters.  However,
    // if we decide to allow getters to override methods, then it's possible
    // that it's actually invoking a getter that returns a closure, and that
    // closure might have covariant parameters that need runtime type checks.
    a.foo('hi');
  });
  // This call is ok because the types match up at runtime.
  a.foo(1);
}

main() {
  baz(new C());
}
