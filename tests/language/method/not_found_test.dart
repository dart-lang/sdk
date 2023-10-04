// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
//    ^
// [cfe] The non-abstract class 'A' is missing implementations for these members:
  B();
//^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
  static const field = const B();
  //                   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                         ^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Can't access 'this' in a field initializer to read 'B'.
  // [cfe] Couldn't find constructor 'B'.
}

class B {
  const B();
}

main() {
  print(A.field);
}
