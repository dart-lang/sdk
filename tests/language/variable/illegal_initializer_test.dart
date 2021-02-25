// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A();
  A.foo();
}

class B extends A {
  B.c1() : super.foo;
//                  ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected '(' after this.

  B.foo();
  B.c2() : this.foo;
      //   ^^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_THIS
      // [cfe] Can't access 'this' in a field initializer.
      //   ^^^^
      // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNMENT_IN_INITIALIZER
      // [cfe] Expected an assignment after the field name.
      //   ^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.INITIALIZER_FOR_NON_EXISTENT_FIELD
      //        ^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER

  B.c3() : super;
  //            ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected '(' after this.
  ;
//^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_CLASS_MEMBER
// [cfe] Expected a class member, but got ';'.

  B();
  B.c4() : this;
      //   ^^^^
      // [analyzer] COMPILE_TIME_ERROR.INITIALIZER_FOR_NON_EXISTENT_FIELD
      // [cfe] Expected an assignment after the field name.
      //   ^^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_THIS
      //   ^^^^
      // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNMENT_IN_INITIALIZER
      // [error line 39, column 16, length 0]
      // [cfe] Expected '.' before this.
      //       ^
      // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
      // [cfe] Expected an identifier, but got ''.
}

main() {
  new B.c1();
  new B.c2();
  new B.c3();
  new B.c4();
}
