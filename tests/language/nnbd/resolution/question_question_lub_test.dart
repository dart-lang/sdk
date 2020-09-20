// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that `x ?? y` results in type LUB(x!, y)
void main() {
  f1(null, 2);
}

void f1(
    int? nullableInt,
    int nonNullInt,
) {
  (nullableInt ?? nonNullInt) + 1;
  (nullableInt ?? nullableInt) + 1;
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//                             ^
// [cfe] Operator '+' cannot be called on 'int?' because it is potentially null.
  (nonNullInt ?? nullableInt) + 1;
//^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// ^
// [cfe] Operand of null-aware operation '??' has type 'int' which excludes null.
//               ^^^^^^^^^^^
// [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
//                            ^
// [cfe] Operator '+' cannot be called on 'int?' because it is potentially null.
  (nonNullInt ?? nonNullInt) + 1;
// ^
// [cfe] Operand of null-aware operation '??' has type 'int' which excludes null.
//               ^^^^^^^^^^
// [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
}

// TODO(mfairhurst) add cases with type parameter types
