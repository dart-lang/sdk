// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to optimistically infer the
// wrong types for fields because of generative constructors being
// inlined.

import "package:expect/expect.dart";
import "compiler_annotations.dart";

class A {
  var foo;
  var bar;

  @DontInline()
  A() {
    // Currently defeat inlining by using a closure.
    bar = () => 42;
    foo = 54;
  }
  A.inline();
}

main() {
  // Make sure A's constructor is analyzed first by surrounding the
  // body by two allocations.
  new A();
  bar();
  new A();
}

class B {
  var bar;
  var closure;
  @DontInline()
  B() {
    // Currently defeat inlining by using a closure.
    closure = () => 42;
    bar = new A().foo;
  }
}

@DontInline()
bar() {
  // Make sure B's constructor is analyzed first by surrounding the
  // body by two allocations.
  new B();
  // Currently defeat inlining by using a closure.
  Expect.throwsNoSuchMethodError(() => new A.inline().foo + 42);
  codegenLast();
  new B();
}

@DontInline()
codegenLast() {
  // This assignment currently defeats simple type inference, but not
  // the optimistic inferrer.
  new A().foo = new B().bar;
  // Currently defeat inlining by using a closure.
  new B().closure = () => 42;
}
