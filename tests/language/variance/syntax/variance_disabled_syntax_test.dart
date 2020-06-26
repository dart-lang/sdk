// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests with `variance` flag disabled
// Correct variance modifier usage will issue an error.

import 'package:expect/expect.dart';

abstract class A<in X> {
//               ^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the 'variance' language feature to be enabled.
  int foo(X bar);
}

class B<out X, in Y, inout Z> {}
//      ^^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the 'variance' language feature to be enabled.
//             ^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the 'variance' language feature to be enabled.
//                   ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the 'variance' language feature to be enabled.

class C<in T> extends A<T> {
//      ^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the 'variance' language feature to be enabled.
  @override
  int foo(T bar) {
    return 2;
  }
}

mixin D<out T> {}
//      ^^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the 'variance' language feature to be enabled.

class E1 {}

mixin E<in T extends E1> {}
//      ^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the 'variance' language feature to be enabled.

class F<out T> = Object with D<T>;
//      ^^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the 'variance' language feature to be enabled.

class G<out out> {}
//      ^^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the 'variance' language feature to be enabled.

class H<out inout> {}
//      ^^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the 'variance' language feature to be enabled.

main() {
  B<int, String, bool> b = B();

  C<int> c = C();
  Expect.equals(2, c.foo(3));

  F<int> f = F();

  G<int> g = G();

  H<int> h = H();
}
