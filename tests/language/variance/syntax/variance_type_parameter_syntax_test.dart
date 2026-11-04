// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the grammar of type parameters with variance modifiers. Metadata can
// precede a variance modifier. `out` and `inout` can be the names of type
// parameters with a bound.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

const meta = 0;

class A<@meta out T> {}

class B<@meta inout T, @meta in U> {}

class C<out extends Object> {}

class D<inout extends num> {}

void main() {
  Expect.type<A<int>>(A<int>());
  Expect.type<B<int, int>>(B<int, int>());
  Expect.type<C<int>>(C<int>());
  Expect.type<D<int>>(D<int>());
}
