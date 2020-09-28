// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that variables assigned in try blocks are de-promoted in catch and
// finally blocks, since the catch or finally block may execute after the
// assignment.

void tryCatchAssignInBody(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    try {
      x = 0;
    } catch (e) {
      // The assignment to x does de-promote because flow analysis does a
      // conservative estimate of the flow model resulting from a caught
      // exception (using the same logic it uses for loops, which doesn't
      // account for RHS types)
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
    }
  }
}

void tryFinallyAssignInBody(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    try {
      x = 0;
    } finally {
      // The assignment to x does de-promote because flow analysis does a
      // conservative estimate of the flow model resulting from a caught
      // exception (using the same logic it uses for loops, which doesn't
      // account for RHS types)
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
    }
  }
}

main() {
  tryCatchAssignInBody(0);
  tryFinallyAssignInBody(0);
}
