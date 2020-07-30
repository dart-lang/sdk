// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that variables assigned in closures and local functions are
// de-promoted at the top of the closure, since the closure may be invoked
// multiple times.

void functionExpression(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    var f = () {
      // The assignment to x does de-promote because it happens after the top of
      // the closure, so flow analysis cannot check that the assigned value is
      // an int at the time de-promotion occurs.
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
      x = 0;
    };
  }
}

void localFunction(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    f() {
      // The assignment to x does de-promote because it happens after the top of
      // the closure, so flow analysis cannot check that the assigned value is
      // an int at the time de-promotion occurs.
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
      x = 0;
    }
  }
}

main() {
  functionExpression(0);
  localFunction(0);
}
