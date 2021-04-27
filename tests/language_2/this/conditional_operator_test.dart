// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Verify that the ?. operator cannot be used for forwarding "this"
// constructors.

class B {
  B();
  B.namedConstructor();
  var field = 1;
  method() => 1;

  B.forward()
    : this?.namedConstructor()
    //^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_THIS
    // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNMENT_IN_INITIALIZER
    //^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INITIALIZER_FOR_NON_EXISTENT_FIELD
    // [cfe] Expected an assignment after the field name.
    //    ^^
    // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
    // [cfe] Expected '.' before this.
    // [cfe] Expected an identifier, but got ''.
  ;

  test() {
    this?.field = 1;
    this?.field += 1;
    this?.field;
    this?.method();
  }
}

main() {
  new B.forward().test();
}
