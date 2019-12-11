// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const x =
    throw "x";
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Throw is not a constant expression.

const y = const {
  0:
      throw "y";
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Throw is not a constant expression.
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_MAP_VALUE
//             ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected '}' before this.
};

main() {
  print(x);
  print(y);
  const z =
      throw 1 + 1 + 1;
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Throw is not a constant expression.
  print(z);
}
