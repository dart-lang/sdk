// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for a function type test that cannot be eliminated at compile time.

// VMOptions=--generic-method-syntax

import "package:expect/expect.dart";

class A {}

typedef F<S> = Function(List<S>, Function(String), num);
typedef G<T> = Function<S>(List<S>, Function<A>(A), T);

foo(List<dynamic> x, bar(String y), num z) {}
foo2(List<int> x, bar(String y), num z) {}
foo3<T>(List<T> x, Function<S>(S) y, num z) {}

main() {
  Expect.isTrue(foo is F);
  Expect.isTrue(foo is F<int>);
  Expect.isTrue(foo is F<bool>);

  Expect.isFalse(foo2 is F, //# 01: ok
      "sound function types: cannot allow passing List to List<int>"); //# 01: ok
  Expect.isTrue(foo2 is F<int>);
  Expect.isFalse(foo2 is F<bool>);

  Expect.isFalse(foo3 is F); //# 01: ok
  Expect.isFalse(foo3 is F<int>); //# 01: ok
  Expect.isFalse(foo3 is F<bool>); //# 01: ok

  Expect.isFalse(foo is G); //# 01: ok
  Expect.isFalse(foo is G<int>); //# 01: ok
  Expect.isFalse(foo is G<bool>);

  Expect.isFalse(foo2 is G); //# 01: ok
  Expect.isFalse(foo2 is G<int>); //# 01: ok
  Expect.isFalse(foo2 is G<bool>);

  Expect.isFalse(foo3 is G<Object>, //# 01: ok
      "sound function types: cannot allow passing any Object to num"); //# 01: ok
  Expect.isTrue(foo3 is G<int>);
  Expect.isFalse(foo3 is G<bool>);
}