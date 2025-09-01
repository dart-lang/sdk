// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F<X> = X Function(X);

extension<X> on X {
  X m<Y extends F<X>>() => this;
}

void test1() {
  g() sync* {
    yield 1;
    yield null;
  }

  g.m<F<Iterable<int?> Function()>>();
  g.m<F<Iterable<int?> Function()>>;
  g.m<F<Iterable<int> Function()>>();
  //^
  // [cfe] Type argument 'Iterable<int> Function() Function(Iterable<int> Function())' doesn't conform to the bound 'X Function(X)' of the type variable 'Y' on 'm'.
  //  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  g.m<F<Iterable<int> Function()>>;
  // ^
  // [cfe] Type argument 'Iterable<int> Function() Function(Iterable<int> Function())' doesn't conform to the bound 'Iterable<int?> Function() Function(Iterable<int?> Function())' of the type variable 'Y' on 'Iterable<int?> Function() Function<Y extends Iterable<int?> Function() Function(Iterable<int?> Function())>()'.
  //  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}

void test2(Iterable<int?> h()) {
  h.m<F<Iterable<int?> Function()>>();
  h.m<F<Iterable<int?> Function()>>;
  h.m<F<Iterable<int> Function()>>();
  //^
  // [cfe] Type argument 'Iterable<int> Function() Function(Iterable<int> Function())' doesn't conform to the bound 'X Function(X)' of the type variable 'Y' on 'm'.
  //  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  h.m<F<Iterable<int> Function()>>;
  // ^
  // [cfe] Type argument 'Iterable<int> Function() Function(Iterable<int> Function())' doesn't conform to the bound 'Iterable<int?> Function() Function(Iterable<int?> Function())' of the type variable 'Y' on 'Iterable<int?> Function() Function<Y extends Iterable<int?> Function() Function(Iterable<int?> Function())>()'.
  //  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}
