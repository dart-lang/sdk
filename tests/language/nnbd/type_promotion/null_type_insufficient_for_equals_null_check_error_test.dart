// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Given an expression E having type `Null`, the reason that `if (x != E)`
// doesn't promote x's type to non-nullable is because evaluation of the
// expression may change the value of `x`.  (Consider, for example, if E is the
// expression `(x = null)`).  This test demonstrates the problem with `(x =
// null)` and checks a few other cases.

// SharedOptions=--enable-experiment=non-nullable

void assignNullRhs(int? x) {
  if (x != (x = null)) {
    x.isEven;
//  ^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    //^
    // [cfe] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void assignNullLhs(int? x) {
  // In theory it would be sound to promote x in this case, because the
  // assignment happens before the RHS is evaluated, but we prefer not to
  // promote in order to be consistent with the `assignNullRhs` case.
  if ((x = null) != x) {
    x.isEven;
//  ^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    //^
    // [cfe] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void unrelatedVarRhs(int? x, Null n) {
  if (x != n) {
    x.isEven;
//  ^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    //^
    // [cfe] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void unrelatedVarLhs(int? x, Null n) {
  if (n != x) {
    x.isEven;
//  ^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    //^
    // [cfe] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

main() {
  assignNullRhs(0);
  assignNullLhs(0);
  unrelatedVarLhs(0, null);
  unrelatedVarRhs(0, null);
}
