// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when `inference-update-4` is enabled, a final variable that is
// not definitely assigned before a loop, `try` statement, or closure is still
// considered potentially assigned inside it, so it can't be assigned twice.
//
// This is a regression test for a soundness bug in which such variables were
// treated as definitely unassigned, allowing multiple assignments (and
// allowing promotions to be preserved in closures even though the variable's
// value could subsequently change).

// SharedOptions=--enable-experiment=inference-update-4

void forLoop() {
  final int? x;
  late int Function() readX;
  for (int i = 0; i < 2; i++) {
    if (i == 0) {
      x = 42;
      // [error column 7, length 1]
      // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
      // [cfe] Final variable 'x' might already be assigned at this point.
      readX = () => x + 1;
    } else {
      x = null;
      // [error column 7, length 1]
      // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
      // [cfe] Final variable 'x' might already be assigned at this point.
      print(readX());
    }
  }
}

void whileLoop(bool b) {
  final int? x;
  while (b) {
    x = 1;
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
    // [cfe] Final variable 'x' might already be assigned at this point.
  }
}

void doLoop(bool b) {
  final int? x;
  do {
    x = 1;
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
    // [cfe] Final variable 'x' might already be assigned at this point.
  } while (b);
}

void forInLoop(List<int> list) {
  final int? x;
  for (var _ in list) {
    x = 1;
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
    // [cfe] Final variable 'x' might already be assigned at this point.
  }
}

void tryCatch() {
  final int? x;
  try {
    x = 1;
    throw 0;
  } catch (_) {
    x = null;
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
    // [cfe] Final variable 'x' might already be assigned at this point.
  }
}

void switchContinue(int i) {
  final int? x;
  switch (i) {
    L:
    case 0:
      x = 1;
    // [error column 7, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
    // [cfe] Final variable 'x' might already be assigned at this point.
    case 1:
      continue L;
  }
}

main() {}
