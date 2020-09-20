// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that variables assigned in loops are de-promoted at the top of the
// loop body, since the loop body be executed multiple times.

void forLoopAssignInCondition(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    for (; 0 == 0 ? (x = 0) == 0 : true;) {
      // The assignment to x does de-promote because it happens after the top of
      // the loop, so flow analysis cannot check that the assigned value is an
      // int at the time de-promotion occurs.
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
    }
  }
}

void forLoopAssignInUpdater(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    for (;; x = 0) {
      // The assignment to x does de-promote because it happens after the top of
      // the loop, so flow analysis cannot check that the assigned value is an
      // int at the time de-promotion occurs.
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
    }
  }
}

void forLoopAssignInBody(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    for (;;) {
      // The assignment to x does de-promote because it happens after the top of
      // the loop, so flow analysis cannot check that the assigned value is an
      // int at the time de-promotion occurs.
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
      x = 0;
    }
  }
}

void forEachAssignInBody(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    for (var y in [0]) {
      // The assignment to x does de-promote because it happens after the top of
      // the loop, so flow analysis cannot check that the assigned value is an
      // int at the time de-promotion occurs.
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
      x = 0;
    }
  }
}

void whileAssignInCondition(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    while (0 == 0 ? (x = 0) == 0 : true) {
      // The assignment to x does de-promote because it happens after the top of
      // the loop, so flow analysis cannot check that the assigned value is an
      // int at the time de-promotion occurs.
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
    }
  }
}

void whileAssignInBody(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    while (true) {
      // The assignment to x does de-promote because it happens after the top of
      // the loop, so flow analysis cannot check that the assigned value is an
      // int at the time de-promotion occurs.
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
      x = 0;
    }
  }
}

void doAssignInCondition(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    do {
      // The assignment to x does de-promote because it happens after the top of
      // the loop, so flow analysis cannot check that the assigned value is an
      // int at the time de-promotion occurs.
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
    } while ((x = 0) == 0);
  }
}

void doAssignInBody(Object x) {
  if (x is int) {
    print(x.isEven); // Verify that promotion occurred
    do {
      // The assignment to x does de-promote because it happens after the top of
      // the loop, so flow analysis cannot check that the assigned value is an
      // int at the time de-promotion occurs.
      print(x.isEven);
      //      ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'isEven' isn't defined for the class 'Object'.
      x = 0;
    } while (true);
  }
}

main() {
  forLoopAssignInCondition(0);
  forLoopAssignInUpdater(0);
  forLoopAssignInBody(0);
  forEachAssignInBody(0);
  whileAssignInCondition(0);
  whileAssignInBody(0);
  doAssignInCondition(0);
  doAssignInBody(0);
}
