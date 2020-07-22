// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that variables assigned in catch and finally are not de-promoted,
// since the catch or finally block only executes once.

void tryCatchAssignInCatch(Object x) {
  if (x is int) {
    try {} catch (e) {
      // The assignment to x does not de-promote because the assignment is
      // outside the scope of the try block
      x.isEven;
      x = '';
    }
  }
}

void tryFinallyAssignInBody(Object x) {
  if (x is int) {
    try {} finally {
      // The assignment to x does not de-promote because the assignment is
      // outside the scope of the try block
      x.isEven;
      x = 0;
    }
  }
}

main() {
  tryCatchAssignInCatch(0);
  tryFinallyAssignInBody(0);
}
