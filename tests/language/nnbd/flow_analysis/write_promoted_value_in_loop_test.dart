// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that variables assigned in initialization parts of loops are not
// de-promoted, since loop initialization only executes once.

void forLoopWithoutDecl(Object x) {
  if (x is int) {
    for (x = 0;;) {
      // The assignment to x does not de-promote x because it happens before the
      // top of the loop, and it assigns an int (which is compatible with the
      // promoted type).
      x.isEven;
      break;
    }
  }
}

void forLoopWithoutDeclAssignInRHS(Object x) {
  if (x is int) {
    int y;
    for (y = (x = 0);;) {
      // The assignment to x does not de-promote x because it happens before the
      // top of the loop, and it assigns an int (which is compatible with the
      // promoted type).
      x.isEven;
      break;
    }
  }
}

void forLoopWithDeclAssignInRHS(Object x) {
  if (x is int) {
    for (int y = (x = 0);;) {
      // The assignment to x does not de-promote x because it happens before the
      // top of the loop, and it assigns an int (which is compatible with the
      // promoted type).
      x.isEven;
      break;
    }
  }
}

void forEachWithoutDecl(Object x) {
  if (x is int) {
    int y;
    for (y in [x = 0]) {
      // The assignment to x does not de-promote x because it happens before the
      // top of the loop, and it assigns an int (which is compatible with the
      // promoted type).
      x.isEven;
      break;
    }
  }
}

void forEachWithDecl(Object x) {
  if (x is int) {
    for (int y in [x = 0]) {
      // The assignment to x does not de-promote x because it happens before the
      // top of the loop, and it assigns an int (which is compatible with the
      // promoted type).
      x.isEven;
      break;
    }
  }
}

main() {
  forLoopWithoutDecl(0);
  forLoopWithoutDeclAssignInRHS(0);
  forLoopWithDeclAssignInRHS(0);
  forEachWithoutDecl(0);
  forEachWithDecl(0);
}
