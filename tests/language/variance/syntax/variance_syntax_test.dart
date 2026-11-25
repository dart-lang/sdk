// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=variance

import 'package:expect/expect.dart';

abstract class A<in X> {
  int foo(X bar);
}

class B<out X, in Y, inout Z> {}

class C<in T> extends A<T> {
  @override
  int foo(T bar) {
    return 2;
  }
}

mixin D<out T> {}

class E1 {}

mixin E<in T extends E1> {}

class F<out T> = Object with D<T>;

class G<out out> {}

class H<out inout> {}

main() {
  B<int, String, bool> b = B();

  C<int> c = C();
  Expect.equals(2, c.foo(3));

  F<int> f = F();

  G<int> g = G();

  H<int> h = H();
}
