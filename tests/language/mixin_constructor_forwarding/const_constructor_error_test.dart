// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "const_constructor_test.dart" show Application;

main() {
  // Only make forwarders const if original constructor is const.
  const Application.c1(0);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c2(0);
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //    ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  const Application.c3(x: 0);
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
