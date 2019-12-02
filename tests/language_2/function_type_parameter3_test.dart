// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that we detect that a function literal is not
/// a compile time constant.

test([String fmt(int i) = (i) => "$i"]) {}
//                        ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_DEFAULT_VALUE
// [cfe] Not a constant expression.
//                                 ^
// [cfe] Not a constant expression.

main() {
  test();
}
