// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for a function type test that cannot be eliminated at compile time.

// VMOptions=--generic-method-syntax --no-reify-generic-functions

import "package:expect/expect.dart";

class A {}

typedef F<T> = Function<S>(List<S> list, Function<A>(A), T);

foo(List<dynamic> x, bar(String y), int z) {}
foo2(List<int> x, bar(String y), int z) {}

main() {
  Expect.isTrue(foo is F);
  Expect.isTrue(foo is F<int>);
  Expect.isFalse(foo is F<bool>);

  Expect.isTrue(foo2 is F);
  Expect.isTrue(foo2 is F<int>);
  Expect.isFalse(foo2 is F<bool>);
}
