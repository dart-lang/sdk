// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that external variable declarations do not allow more
// than they should.

// Check that external declarations are not abstract.
class External1 {
  external int x;
}

// Check that class has expected interface.
class External2 {
  // Getter only.
  external final int x;
  // Getter and setter.
  external covariant String y;

  static void test(External2 a) {
    int x = a.x;

    // Cannot assign to final field.
    a.x = 42;
    //^
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL
    // [cfe] The setter 'x' isn't defined for the type 'External2'.

    String y = a.y;
    a.y = "ab";

    // Cannot assign something of wrong type, even if covariant.
    a.y = Object();
    //    ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'Object' can't be assigned to a variable of type 'String'.
  }
}

void main() {
  External2.test(External2());
}
