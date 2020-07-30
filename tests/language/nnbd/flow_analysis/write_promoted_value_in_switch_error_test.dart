// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that variables assigned in switch statement bodies are de-promoted
// at the top of labelled case blocks, since the assignment may occur before a
// branch to the labelled case block.

void switchWithLabelAssignInCase(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    switch (x) {
      case 1:
        continue L;
      L:
      case 0:
        // The assignment to x does de-promote because it happens after the
        // label, so flow analysis cannot check that the assigned value is an
        // int at the time de-promotion occurs.
        print(x.isEven);
        //      ^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
        // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
        x = 0;
        break;
    }
  }
}

void switchWithLabelAssignInDefault(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    switch (x) {
      case 1:
        continue L;
      L:
      default:
        // The assignment to x does de-promote because it happens after the
        // label, so flow analysis cannot check that the assigned value is an
        // int at the time de-promotion occurs.
        print(x.isEven);
        //      ^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
        // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
        x = 0;
        break;
    }
  }
}

main() {
  switchWithLabelAssignInCase(0);
  switchWithLabelAssignInDefault(0);
}
