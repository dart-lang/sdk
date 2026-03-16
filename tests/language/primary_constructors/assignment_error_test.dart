// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if an assignment to a primary parameter occurs
// in the initializing expression of a non-late instance variable.

// SharedOptions=--enable-experiment=primary-constructors

class C(int x, Object? z) {
  Record y = (
    ++x,
    //^
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    --x,
    //^
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    x++,
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    x--,
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    x = 2,
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    x += 2,
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    x -= 2,
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    (x) = 2,
    // [error column 6, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    [x] = [2],
    // [error column 6, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    {null: x} = {null: 2},
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    (x, name: _) = (2, name: true),
    // [error column 6, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    (x && z) = 2,
    // [error column 6, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.

    int(runtimeType: z) = 2,
    //               ^
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
    // [cfe] A primary constructor parameter can't be assigned to in an initializer.
  );
}

// A compile-time error occurs if an assignment to a primary parameter occurs
// in the initializer list of the body part of a primary constructor.

class C2(int x) {
  int y;

  this : y = x++;
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
  // [cfe] A primary constructor parameter can't be assigned to in an initializer.
}

class C3(int x) {
  this : assert(x++ == 2);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
  // [cfe] A primary constructor parameter can't be assigned to in an initializer.
}
