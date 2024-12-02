// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A mixin class declaration *can* declare factory and trivial generative
// constructors.

import "package:expect/expect.dart";

class A {
  const A();
  const A.baz();
}

class B implements N {
  const B();
}

mixin class N {
  // It's OK for a mixin derived from a class to have factory constructors
  // and trivial constructors.
  // (Trivial means: No initializer list, no body, no parameters, and not
  // forwarding.)
  factory N.foo() => const B();
  const factory N.bar() = B;
  N.baz();
}

// Used as mixin.
class NA = A with N;

main() {
  // Constructors on `N` can be used directly.
  Expect.identical(const B(), N.foo());
  const N bar = N.bar();
  N n = N.baz();

  // Constructors from `A` inherited by `NA`.
  NA na = const NA(); // Inherited from A.
  na = const NA.baz(); // Inherited from A, not shadowed by N.
}
