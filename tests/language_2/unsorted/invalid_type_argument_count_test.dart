// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Test top level field.
dynamic<int> x1 = 42;
// [error line 8, column 1, length 12]
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
// [cfe] Expected 0 type arguments.

class Foo {
  // Test class member.
  dynamic<int> x2 = 42;
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
// [cfe] Expected 0 type arguments.

  Foo() {
    print(x2);
  }
}

main() {
  print(x1);

  new Foo();

  // Test local variable.
  dynamic<int> x3 = 42;
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
// [cfe] Expected 0 type arguments.
  print(x3);

  foo(42);
}

// Test parameter.
void foo(dynamic<int> x4) {
//       ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
// [cfe] Expected 0 type arguments.
  print(x4);
}
