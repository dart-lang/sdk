// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that mixin supertypes are properly maintained even if marked as
// deferred (e.g., in a circular hierarchy).
// Regression test for: https://github.com/flutter/flutter/issues/66859

import "package:expect/expect.dart";

mixin M {}

mixin N {}

class A extends B<C> with M, N {}

class B<T> {}

class C extends A {}

class Z extends B<Z> with M {}

main() {
  var z = Z();
  Expect.isTrue(z is B<Z>);
  Expect.isTrue(z is M);
  var a = A();
  Expect.isTrue(a is M);
  Expect.isTrue(a is N);
  Expect.isTrue(a is B<C>);
}
