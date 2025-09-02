// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F<X> = X Function(X);

extension<X> on X {
  X m<Y extends F<X>>() => this;
}

void test1() {
  g() {
    if (2 > 1) return 1;
    return null;
  }

  g.m<F<int? Function()>>();
  g.m<F<int? Function()>>;
  g.m<F<int Function()>>();
  //^
  // [cfe] Type argument 'int Function() Function(int Function())' doesn't conform to the bound 'int? Function() Function(int? Function())' of the type variable 'Y' on 'm'.
  //  ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  g.m<F<int Function()>>;
  // ^
  // [cfe] Type argument 'int Function() Function(int Function())' doesn't conform to the bound 'int? Function() Function(int? Function())' of the type variable 'Y' on 'int? Function() Function<Y extends int? Function() Function(int? Function())>()'.
  //  ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}

void test2(int? h()) {
  h.m<F<int? Function()>>();
  h.m<F<int? Function()>>;
  h.m<F<int Function()>>();
  //^
  // [cfe] Type argument 'int Function() Function(int Function())' doesn't conform to the bound 'int? Function() Function(int? Function())' of the type variable 'Y' on 'm'.
  //  ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  h.m<F<int Function()>>;
  // ^
  // [cfe] Type argument 'int Function() Function(int Function())' doesn't conform to the bound 'int? Function() Function(int? Function())' of the type variable 'Y' on 'int? Function() Function<Y extends int? Function() Function(int? Function())>()'.
  //  ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}
