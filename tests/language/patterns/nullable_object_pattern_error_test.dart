// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the appropriate errors are generated if a nullable type is used in
/// an object pattern.

typedef A = int?;

void nullableWithField(x) {
  // This is an error because `isEven` can't be called on `int?`.
  switch (x) {
    case A(isEven: true):
//       ^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//               ^
// [cfe] The getter 'isEven' isn't defined for the class 'int?'.
      break;
  }
}

void potentiallyNullableWithField<T extends int?>(x) {
  // This is an error because `isEven` can't be called on `int?`.
  switch (x) {
    case T(isEven: true):
//       ^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//               ^
// [cfe] The getter 'isEven' isn't defined for the class 'int?'.
      break;
  }
}

main() {}
