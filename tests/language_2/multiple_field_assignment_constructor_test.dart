// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "compiler_annotations.dart";

var a = [null];

class A {
  var foo;
  var bar;

  @DontInline()
  A() {
    // Currently defeat inlining by using a closure.
    bar = () => 42;
    foo = 42;
    foo = a[0];
  }
}

class B {
  var foo;
  var bar;

  @DontInline()
  B() {
    // Currently defeat inlining by using a closure.
    bar = () => 42;
    foo = 42;
    foo = a[0];
    if (false) foo = 42;
  }
}

main() {
  // Surround the call to [bar] by allocations of [A] and [B] to
  // ensure their constructors get analyzed first.
  new A();
  new B();
  bar();
  new A();
  new B();
}

@DontInline()
bar() {
  // Currently defeat inlining by using a closure.
  Expect.throwsNoSuchMethodError(() => new A().foo + 42);
  Expect.throwsNoSuchMethodError(() => new B().foo + 42);
}
