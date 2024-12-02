// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test behavior when using a class as a mixin.
// @dart=2.19

import "package:expect/expect.dart";
import "const_constructor_with_field_legacy_test.dart" show Application;

main() {
  // Forwarding constructors are not constant.

  const Application.c4(42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c5(42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c6(x: 42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c7(42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c8(42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c9(x: 42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c10(42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c11(42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c12(x: 42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c13(42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c14(42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c15(x: 42);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.

  // Only insert forwarders for generative constructors.
  new Application();
  //  ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Couldn't find constructor 'Application'.
}
