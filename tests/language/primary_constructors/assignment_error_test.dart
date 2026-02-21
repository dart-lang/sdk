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
    // [cfe] unspecified
    // [analyzer] unspecified

    --x,
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    x++,
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    x--,
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    x = 2,
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    x += 2,
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    x -= 2,
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    (x) = 2,
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    [x] = [2],
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    {null: x} = {null: 2},
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    (x, name: _) = (2, name: true),
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    (x && z) = 2,
    //^
    // [cfe] unspecified
    // [analyzer] unspecified

    int(runtimeType: z) = 2,
    //^
    // [cfe] unspecified
    // [analyzer] unspecified
  );
}
