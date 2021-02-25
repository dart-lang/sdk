// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that mixin supertypes are properly maintained even if marked as
// deferred (e.g., in a circular hierarchy).
// Regression test for: https://github.com/flutter/flutter/issues/66859

import "package:expect/expect.dart";

mixin X {}
mixin Y {}
mixin Z {}

class A extends B<C> with X {}

class C extends A with Z {}

class B<T> extends Object with Y {}

main() {
  var a = A();
  var b = B();
  var c = C();
  Expect.isTrue(a is A);
  Expect.isTrue(a is B<C>);
  Expect.isTrue(a is X);
  Expect.isTrue(a is Y);
  Expect.isTrue(c is C);
  Expect.isTrue(c is A);
  Expect.isTrue(c is B<C>);
  Expect.isTrue(c is X);
  Expect.isTrue(c is Y);
  Expect.isTrue(c is Z);
  Expect.isTrue(b is B);
  Expect.isTrue(b is Y);
}
