// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

// Test that private names exported via public typedefs don't give access to
// private static methods.

import "private_name_library.dart";

/// Test that accessing private static methods is not accidentally enabled.
void test1() {
  {
    PublicClass._privateStaticMethod();
//              ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
// [cfe] Method not found: '_PrivateClass._privateStaticMethod'.
    AlsoPublicClass._privateStaticMethod();
//                  ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
// [cfe] Method not found: '_PrivateClass._privateStaticMethod'.
    PublicGenericClassOfInt._privateStaticMethod();
//                          ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
// [cfe] Method not found: '_PrivateGenericClass._privateStaticMethod'.
  }
}

void main() {
  test1();
}
